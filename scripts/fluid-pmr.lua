-- Fluid PMR control-stage logic. See PMR_handoff.md (repo root) for the
-- full design and prototypes/fluid-pmr.lua for the entity layout this
-- assembles.
--
-- On build: spawns the intake tank, intake pump, and one hidden sub-tank per
-- supported fluid at/around the shell's position, wires the pump's circuit
-- condition to the intake tank's content signal, and stores the whole
-- assembly under the shell's unit_number.
--
-- On tick: drains whatever fluid has staged in the intake tank into the
-- matching sub-tank, respecting sub-tank remaining capacity. The pump's
-- circuit condition (signal-everything == 0 on the intake tank) keeps the
-- external network from pushing anything new in until this drain empties
-- the intake tank, so no explicit "rejection" logic is needed here.

local FLUID_PMR_FLUIDS = require("constants.fluid-pmr")

local M = {}

local DRAIN_INTERVAL = 30  -- ticks between drain attempts; tune once profiled

-- ─── Storage ─────────────────────────────────────────────────────────────────

function M.on_init()
    storage.fluid_pmrs = storage.fluid_pmrs or {}
end

-- ─── Assembly ────────────────────────────────────────────────────────────────

local function wire_pump_gate(pump, intake_tank)
    local pump_conn = pump.get_wire_connector(defines.wire_connector_id.circuit_red, true)
    local tank_conn = intake_tank.get_wire_connector(defines.wire_connector_id.circuit_red, true)
    pump_conn.connect_to(tank_conn, false, defines.wire_origin.script)

    local control = pump.get_or_create_control_behavior()
    control.circuit_enable_disable = true
    control.circuit_condition = {
        comparator    = "=",
        first_signal  = { type = "virtual", name = "signal-everything" },
        constant      = 0,
    }
end

local function spawn_assembly(shell)
    local surface = shell.surface
    local position = shell.position
    local force = shell.force

    local intake_tank = surface.create_entity({
        name     = "fluid-pmr-intake-tank",
        position = position,
        force    = force,
    })

    local pump = surface.create_entity({
        name     = "fluid-pmr-intake-pump",
        position = { position.x - 1, position.y },
        force    = force,
    })

    wire_pump_gate(pump, intake_tank)

    local subtanks = {}
    for _, fluid_name in ipairs(FLUID_PMR_FLUIDS) do
        subtanks[fluid_name] = surface.create_entity({
            name     = "fluid-pmr-subtank-" .. fluid_name,
            position = position,
            force    = force,
        })
    end

    return {
        shell       = shell,
        intake_tank = intake_tank,
        pump        = pump,
        subtanks    = subtanks,
    }
end

-- ─── Registration ────────────────────────────────────────────────────────────

function M.on_built(event)
    local entity = event.entity or event.created_entity
    if not entity or entity.name ~= "fluid-pmr" then return end
    storage.fluid_pmrs = storage.fluid_pmrs or {}
    storage.fluid_pmrs[entity.unit_number] = spawn_assembly(entity)
end

function M.on_removed(event)
    local entity = event.entity
    if not entity or entity.name ~= "fluid-pmr" then return end
    storage.fluid_pmrs = storage.fluid_pmrs or {}

    local data = storage.fluid_pmrs[entity.unit_number]
    if data then
        -- Fluid-loss policy on destruction is an open item from PMR_handoff.md
        -- (#4, not yet confirmed) — currently whatever is staged/stored is
        -- voided along with the entities. Revisit if that's not acceptable.
        if data.intake_tank.valid then data.intake_tank.destroy() end
        if data.pump.valid then data.pump.destroy() end
        for _, subtank in pairs(data.subtanks) do
            if subtank.valid then subtank.destroy() end
        end
    end

    storage.fluid_pmrs[entity.unit_number] = nil
end

-- ─── Tick ────────────────────────────────────────────────────────────────────

local function drain(data)
    if not data.intake_tank.valid then return false end

    local fluid = data.intake_tank.get_fluid(1)
    if not fluid or fluid.amount <= 0 then return true end

    local subtank = data.subtanks[fluid.name]
    if not subtank or not subtank.valid then
        -- Unsupported fluid somehow reached the intake tank (see
        -- PMR_handoff.md #2 under Control-stage logic). Leave it staged —
        -- the pump's gate stays closed, so this is visible/safe rather than
        -- silently voided, but it does mean the PMR wedges until fixed.
        log(string.format(
            "fluid-pmr %d: no sub-tank configured for fluid '%s', leaving staged",
            data.shell.unit_number, fluid.name
        ))
        return true
    end

    local capacity = subtank.get_fluid_capacity(1)
    local existing = subtank.get_fluid(1)
    local existing_amount = existing and existing.amount or 0
    local space = capacity - existing_amount
    if space <= 0 then return true end

    local take = math.min(fluid.amount, space)
    subtank.add_fluid(1, { name = fluid.name, amount = take, temperature = fluid.temperature })
    data.intake_tank.remove_fluid(1, take)

    return true
end

function M.on_tick(event)
    if event.tick % DRAIN_INTERVAL ~= 0 then return end
    storage.fluid_pmrs = storage.fluid_pmrs or {}
    for uid, data in pairs(storage.fluid_pmrs) do
        if not drain(data) then
            storage.fluid_pmrs[uid] = nil
        end
    end
end

return M
