-- Fluid PMR control-stage logic. See PMR_handoff.md (repo root) for the
-- full design and prototypes/fluid-pmr.lua for the entity layout this
-- assembles.
--
-- On build: spawns the intake pump and one hidden sub-tank per supported
-- fluid at/around the shell's position, wires the pump's circuit condition
-- to the shell's own content signal, wires each sub-tank's circuit_connector
-- to the shell's on a separate green wire, and stores the whole assembly
-- under the shell's unit_number. The shell itself IS the intake tank (see
-- prototypes/fluid-pmr.lua) — there's no separate intake-tank entity.
--
-- On tick: moves fluid from the intake pump's own fluidbox into the shell
-- (no real engine pipe connection between them, see prototypes/fluid-pmr.lua),
-- then drains the shell into the matching sub-tank, respecting sub-tank
-- remaining capacity. The pump's circuit condition (signal-everything == 0
-- on the shell) keeps the external network from pushing anything new in
-- until the drain empties the shell, so no explicit "rejection" logic is
-- needed here. Separately, any sub-tank with a rule in
-- constants/fluid-pmr-conversions.lua converts its fluid into an item onto
-- the shell's east-adjacent tile (belt, then container, then ground) once
-- it has enough staged.

local FLUID_PMR_FLUIDS = require("constants.fluid-pmr")
local FLUID_PMR_CONVERSIONS = require("constants.fluid-pmr-conversions")

local M = {}

local DRAIN_INTERVAL   = 30  -- ticks between drain attempts; tune once profiled
local PRODUCE_INTERVAL = 30  -- ticks between item-output attempts

-- ─── Storage ─────────────────────────────────────────────────────────────────

function M.on_init()
    storage.fluid_pmrs = storage.fluid_pmrs or {}
end

-- ─── Assembly ────────────────────────────────────────────────────────────────

local function wire_pump_gate(pump, shell)
    local pump_conn  = pump.get_wire_connector(defines.wire_connector_id.circuit_red, true)
    local shell_conn = shell.get_wire_connector(defines.wire_connector_id.circuit_red, true)
    pump_conn.connect_to(shell_conn, false, defines.wire_origin.script)

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
-- just sums each subtank's single-fluid content signal onto the shell's own
-- green connector — the shell becomes the external "whole PMR" read-contents
-- point, and the player can wire their own equipment to it safely (green
-- only ever carries this passive broadcast, never the pump gate logic).
local function wire_subtank_readout(shell, subtanks)
    local shell_conn = shell.get_wire_connector(defines.wire_connector_id.circuit_green, true)
    for _, subtank in pairs(subtanks) do
        local sub_conn = subtank.get_wire_connector(defines.wire_connector_id.circuit_green, true)
        sub_conn.connect_to(shell_conn, false, defines.wire_origin.script)
    end
end

local function spawn_assembly(shell)
    local surface = shell.surface
    local position = shell.position
    local force = shell.force

    local pump = surface.create_entity({
        name     = "fluid-pmr-intake-pump",
        position = { position.x - 1, position.y },
        force    = force,
    })

    wire_pump_gate(pump, shell)

    local subtanks = {}
    for _, fluid_name in ipairs(FLUID_PMR_FLUIDS) do
        subtanks[fluid_name] = surface.create_entity({
            name     = "fluid-pmr-subtank-" .. fluid_name,
            position = position,
            force    = force,
        })
    end

    wire_subtank_readout(shell, subtanks)

    return {
        shell    = shell,
        pump     = pump,
        subtanks = subtanks,
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
        -- The shell itself is already being removed by whatever fired this
        -- event (mining, death, etc.) — only the pump and sub-tanks are ours
        -- to clean up here.
        if data.pump.valid then data.pump.destroy() end
        for _, subtank in pairs(data.subtanks) do
            if subtank.valid then subtank.destroy() end
        end
    end

    storage.fluid_pmrs[entity.unit_number] = nil
end

-- ─── GUI ─────────────────────────────────────────────────────────────────────
-- The shell's own fluidbox is just a near-empty staging buffer — showing it
-- in the default storage-tank GUI would be misleading. Replace that default
-- GUI with a custom frame listing each sub-tank's actual contents instead.

local CLOSE_BUTTON_NAME = "fluid_pmr_close_button"

-- Vanilla-style title bar: drag handle over the whole frame, a status light
-- (green while the intake gate is open/empty, red while a batch is staged
-- and draining), and a close button — matches the chrome every native
-- machine GUI has.
local function add_titlebar(frame, gate_open)
    local titlebar = frame.add({ type = "flow" })
    titlebar.drag_target = frame
    titlebar.add({
        type = "label",
        style = "frame_title",
        caption = "Fluid PMR",
        ignored_by_interaction = true,
    })
    local filler = titlebar.add({ type = "empty-widget", style = "draggable_space_header", ignored_by_interaction = true })
    filler.style.horizontally_stretchable = true
    filler.style.height = 24

    titlebar.add({
        type = "sprite",
        sprite = gate_open and "utility/status_working" or "utility/status_yellow",
        style = "status_image",
        tooltip = gate_open and "Ready for input" or "Draining staged fluid",
    })
    titlebar.add({
        type = "sprite-button",
        name = CLOSE_BUTTON_NAME,
        style = "frame_action_button",
        sprite = "utility/close",
        hovered_sprite = "utility/close_black",
        clicked_sprite = "utility/close_black",
        tooltip = { "gui.close" },
    })
end

-- One fluid bar per supported fluid: icon, progressbar tinted to the
-- fluid's own color, and an amount/capacity label — same information a
-- vanilla fluid gauge shows.
local function add_fluid_bars(frame, data)
    local content = frame.add({ type = "frame", style = "inside_shallow_frame_with_padding", direction = "vertical" })
    for _, fluid_name in ipairs(FLUID_PMR_FLUIDS) do
        local subtank = data.subtanks[fluid_name]
        local fluid = subtank and subtank.valid and subtank.get_fluid(1)
        local amount = fluid and fluid.amount or 0
        local capacity = (subtank and subtank.valid) and subtank.get_fluid_capacity(1) or 1

        local row = content.add({ type = "flow" })
        row.style.vertical_align = "center"
        row.add({ type = "sprite", sprite = "fluid/" .. fluid_name })

        local bar = row.add({ type = "progressbar", value = amount / capacity })
        bar.style.width = 150
        local fluid_proto = prototypes.fluid[fluid_name]
        if fluid_proto and fluid_proto.base_color then
            bar.style.color = fluid_proto.base_color
        end

        row.add({ type = "label", caption = string.format("%s: %d / %d", fluid_name, amount, capacity) })
    end
    return content
end

local function build_subtank_gui(player, data, gate_open)
    local frame = player.gui.screen.add({
        type      = "frame",
        name      = "fluid_pmr_readout",
        direction = "vertical",
    })
    frame.auto_center = true
    add_titlebar(frame, gate_open)
    add_fluid_bars(frame, data)
    return frame
end

function M.on_gui_opened(event)
    local entity = event.entity
    if not entity or entity.name ~= "fluid-pmr" then return end

    storage.fluid_pmrs = storage.fluid_pmrs or {}
    local data = storage.fluid_pmrs[entity.unit_number]
    if not data then return end

    local player = game.get_player(event.player_index)
    if not player then return end

    storage.fluid_pmr_guis = storage.fluid_pmr_guis or {}
    local old = storage.fluid_pmr_guis[event.player_index]
    if old and old.valid then old.destroy() end

    local staged = entity.valid and entity.get_fluid(1)
    local gate_open = not (staged and staged.amount > 0)

    local frame = build_subtank_gui(player, data, gate_open)
    player.opened = frame
    storage.fluid_pmr_guis[event.player_index] = frame
end

function M.on_gui_closed(event)
    storage.fluid_pmr_guis = storage.fluid_pmr_guis or {}
    local frame = storage.fluid_pmr_guis[event.player_index]
    if frame and frame.valid then frame.destroy() end
    storage.fluid_pmr_guis[event.player_index] = nil
end

function M.on_gui_click(event)
    if event.element and event.element.valid and event.element.name == CLOSE_BUTTON_NAME then
        local player = game.get_player(event.player_index)
        if player then player.opened = nil end
    end
end

-- ─── Tick ────────────────────────────────────────────────────────────────────

-- Moves fluid from the intake pump's own fluidbox into the shell. There's
-- no real engine pipe connection between them (see prototypes/fluid-pmr.lua)
-- — the pump just accumulates whatever the external network pushes in, and
-- this is the only thing that ever reads it.
local function pump_to_shell(data)
    if not data.pump.valid or not data.shell.valid then return false end

    local fluid = data.pump.get_fluid(1)
    if not fluid or fluid.amount <= 0 then return true end

    local capacity = data.shell.get_fluid_capacity(1)
    local existing = data.shell.get_fluid(1)
    local existing_amount = existing and existing.amount or 0
    local space = capacity - existing_amount
    if space <= 0 then return true end

    local take = math.min(fluid.amount, space)
    data.shell.add_fluid(1, { name = fluid.name, amount = take, temperature = fluid.temperature })
    data.pump.remove_fluid(1, take)

    return true
end

local function drain(data)
    if not data.shell.valid then return false end

    local fluid = data.shell.get_fluid(1)
    if not fluid or fluid.amount <= 0 then return true end

    local subtank = data.subtanks[fluid.name]
    if not subtank or not subtank.valid then
        -- Unsupported fluid somehow reached the shell (see PMR_handoff.md
        -- #2 under Control-stage logic). Leave it staged — the pump's gate
        -- stays closed, so this is visible/safe rather than silently voided,
        -- but it does mean the PMR wedges until fixed.
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
    data.shell.remove_fluid(1, take)

    return true
end

-- ─── Item output ─────────────────────────────────────────────────────────────
-- No loader entity — the sub-tanks are fluidboxes, not item inventories, so
-- there is no item stack for a loader to pull from. This mirrors the
-- deprecated Fluid PMR's own output approach (deprecated/fluid-pmr/fluid_pmr.lua):
-- check the east-adjacent tile for a belt, then a container, then bare
-- ground, and place the item directly via script.

local function output_pos(entity)
    local p = entity.position
    return { x = p.x + 2, y = p.y }
end

local function can_output(surface, pos, item_name)
    local belt = surface.find_entity("transport-belt", pos)
    if belt then
        local left  = belt.get_transport_line(defines.transport_line.left_line)
        local right = belt.get_transport_line(defines.transport_line.right_line)
        return left.can_insert_at_back() or right.can_insert_at_back()
    end

    local area = { { pos.x - 0.5, pos.y - 0.5 }, { pos.x + 0.5, pos.y + 0.5 } }
    local containers = surface.find_entities_filtered({ area = area, type = { "container", "logistic-container" } })
    if #containers > 0 then
        for _, cont in ipairs(containers) do
            local inv = cont.get_inventory(defines.inventory.chest)
            if inv and inv.can_insert({ name = item_name, count = 1 }) then return true end
        end
        return false
    end

    local ground = surface.find_entities_filtered({ area = area, type = "item-entity" })
    return #ground == 0
end

local function do_output(surface, pos, item_name)
    local belt = surface.find_entity("transport-belt", pos)
    if belt then
        local left  = belt.get_transport_line(defines.transport_line.left_line)
        local right = belt.get_transport_line(defines.transport_line.right_line)
        if left.can_insert_at_back() then
            left.insert_at_back({ name = item_name, count = 1 })
        elseif right.can_insert_at_back() then
            right.insert_at_back({ name = item_name, count = 1 })
        end
        return
    end

    local area = { { pos.x - 0.5, pos.y - 0.5 }, { pos.x + 0.5, pos.y + 0.5 } }
    local containers = surface.find_entities_filtered({ area = area, type = { "container", "logistic-container" } })
    if #containers > 0 then
        for _, cont in ipairs(containers) do
            local inv = cont.get_inventory(defines.inventory.chest)
            if inv and inv.can_insert({ name = item_name, count = 1 }) then
                inv.insert({ name = item_name, count = 1 })
                return
            end
        end
        return
    end

    surface.spill_item_stack({
        position = pos,
        stack = { name = item_name, count = 1 },
        max_radius = 0,
        use_start_position_on_failure = true,
        allow_belts = false,
    })
end

local function produce(data)
    if not data.shell.valid then return false end

    for fluid_name, rule in pairs(FLUID_PMR_CONVERSIONS) do
        local subtank = data.subtanks[fluid_name]
        if subtank and subtank.valid then
            local fluid = subtank.get_fluid(1)
            if fluid and fluid.amount >= rule.fluid_per_item then
                local pos = output_pos(data.shell)
                if can_output(data.shell.surface, pos, rule.item) then
                    subtank.remove_fluid(1, rule.fluid_per_item)
                    do_output(data.shell.surface, pos, rule.item)
                end
            end
        end
    end

    return true
end

function M.on_tick(event)
    storage.fluid_pmrs = storage.fluid_pmrs or {}
    local do_drain   = (event.tick % DRAIN_INTERVAL   == 0)
    local do_produce = (event.tick % PRODUCE_INTERVAL == 0)
    if not do_drain and not do_produce then return end

    for uid, data in pairs(storage.fluid_pmrs) do
        local ok = true
        if do_drain   then ok = pump_to_shell(data) and drain(data) end
        if ok and do_produce then ok = produce(data) end
        if not ok then storage.fluid_pmrs[uid] = nil end
    end
end

return M
