-- Fluid PMR control-stage logic. See PMR_handoff.md (repo root) for the
-- full design and prototypes/fluid-pmr.lua for the entity layout this
-- assembles.
--
-- On build: spawns the intake tank, intake pump, and one hidden sub-tank per
-- supported fluid at/around the shell's position, wires the pump's circuit
-- condition to the intake tank's content signal, and stores the whole
-- assembly under the shell's unit_number.
--
-- On tick: moves fluid from the intake pump's own fluidbox into the intake
-- tank (no real engine pipe connection between them, see
-- prototypes/fluid-pmr.lua), then drains the intake tank into the matching
-- sub-tank, respecting sub-tank remaining capacity. The pump's circuit
-- condition (signal-everything == 0 on the intake tank) keeps the external
-- network from pushing anything new in until the drain empties the intake
-- tank, so no explicit "rejection" logic is needed here.

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

-- Aggregate "read contents" output. Green wire, kept entirely separate from
-- the red wire used for pump gating so subtank content never affects the
-- signal-everything == 0 gate condition. Any entity's circuit_connector
-- broadcasts its content on whichever wire color it's connected to, so this
-- just sums each subtank's single-fluid content signal onto the intake
-- tank's own green connector — the intake tank becomes the external
-- "whole PMR" read-contents point.
local function wire_subtank_readout(intake_tank, subtanks)
    local tank_conn = intake_tank.get_wire_connector(defines.wire_connector_id.circuit_green, true)
    for _, subtank in pairs(subtanks) do
        local sub_conn = subtank.get_wire_connector(defines.wire_connector_id.circuit_green, true)
        sub_conn.connect_to(tank_conn, false, defines.wire_origin.script)
    end
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

    wire_subtank_readout(intake_tank, subtanks)

    storage.fluid_pmr_by_tank = storage.fluid_pmr_by_tank or {}
    storage.fluid_pmr_by_tank[intake_tank.unit_number] = shell.unit_number

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
        storage.fluid_pmr_by_tank = storage.fluid_pmr_by_tank or {}
        storage.fluid_pmr_by_tank[data.intake_tank.unit_number] = nil
        if data.intake_tank.valid then data.intake_tank.destroy() end
        if data.pump.valid then data.pump.destroy() end
        for _, subtank in pairs(data.subtanks) do
            if subtank.valid then subtank.destroy() end
        end
    end

    storage.fluid_pmrs[entity.unit_number] = nil
end

-- ─── GUI ─────────────────────────────────────────────────────────────────────
-- The intake tank is the visible/selectable "face" of the PMR (shell, pump,
-- and sub-tanks are all invisible/unselectable), but its own fluidbox is
-- just a near-empty staging buffer — showing it in the default storage-tank
-- GUI would be misleading. Replace that default GUI with a custom frame
-- listing each sub-tank's actual contents instead.

local function build_subtank_gui(player, data)
    local frame = player.gui.screen.add({
        type      = "frame",
        name      = "fluid_pmr_readout",
        caption   = "Fluid PMR",
        direction = "vertical",
    })
    frame.auto_center = true
    for _, fluid_name in ipairs(FLUID_PMR_FLUIDS) do
        local subtank = data.subtanks[fluid_name]
        local fluid = subtank and subtank.valid and subtank.get_fluid(1)
        local amount = fluid and fluid.amount or 0
        frame.add({
            type    = "label",
            caption = string.format("%s: %d", fluid_name, amount),
        })
    end
    return frame
end

function M.on_gui_opened(event)
    local entity = event.entity
    if not entity or entity.name ~= "fluid-pmr-intake-tank" then return end

    storage.fluid_pmr_by_tank = storage.fluid_pmr_by_tank or {}
    local shell_uid = storage.fluid_pmr_by_tank[entity.unit_number]
    storage.fluid_pmrs = storage.fluid_pmrs or {}
    local data = shell_uid and storage.fluid_pmrs[shell_uid]
    if not data then return end

    local player = game.get_player(event.player_index)
    if not player then return end

    storage.fluid_pmr_guis = storage.fluid_pmr_guis or {}
    local old = storage.fluid_pmr_guis[event.player_index]
    if old and old.valid then old.destroy() end

    local frame = build_subtank_gui(player, data)
    player.opened = frame
    storage.fluid_pmr_guis[event.player_index] = frame
end

function M.on_gui_closed(event)
    storage.fluid_pmr_guis = storage.fluid_pmr_guis or {}
    local frame = storage.fluid_pmr_guis[event.player_index]
    if frame and frame.valid then frame.destroy() end
    storage.fluid_pmr_guis[event.player_index] = nil
end

-- ─── Tick ────────────────────────────────────────────────────────────────────

-- Moves fluid from the intake pump's own fluidbox into the intake tank.
-- There's no real engine pipe connection between them (see
-- prototypes/fluid-pmr.lua) — the pump just accumulates whatever the
-- external network pushes in, and this is the only thing that ever reads it.
local function pump_to_tank(data)
    if not data.pump.valid or not data.intake_tank.valid then return false end

    local fluid = data.pump.get_fluid(1)
    if not fluid or fluid.amount <= 0 then return true end

    local capacity = data.intake_tank.get_fluid_capacity(1)
    local existing = data.intake_tank.get_fluid(1)
    local existing_amount = existing and existing.amount or 0
    local space = capacity - existing_amount
    if space <= 0 then return true end

    local take = math.min(fluid.amount, space)
    data.intake_tank.add_fluid(1, { name = fluid.name, amount = take, temperature = fluid.temperature })
    data.pump.remove_fluid(1, take)

    return true
end

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
        if not pump_to_tank(data) or not drain(data) then
            storage.fluid_pmrs[uid] = nil
        end
    end
end

return M
