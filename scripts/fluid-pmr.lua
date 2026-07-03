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
-- needed here. Separately, once the hidden fluid-pmr-crafter is idle (no
-- fluid staged in its own fluidboxes), the shell picks the affordable
-- "fluid-pmr" category recipe with the most fluid ingredients, transfers
-- exactly enough fluid from the sub-tanks for the maximum number of
-- affordable batches, and lets the crafter itself (vanilla assembling-
-- machine logic) consume/produce over however many 0.5s craft cycles that
-- takes. Finished items are pulled from the crafter's output inventory and
-- placed the same way the deprecated Fluid PMR did (belt, then container,
-- then ground).

local FLUID_PMR_FLUIDS = require("constants.fluid-pmr")

-- Cached on first use — recipes don't change mid-game, and prototypes.recipe
-- is available as soon as this module loads at control stage.
local fluid_pmr_recipes = nil
local function get_fluid_pmr_recipes()
    if fluid_pmr_recipes then return fluid_pmr_recipes end
    fluid_pmr_recipes = {}
    for name, recipe in pairs(prototypes.recipe) do
        for _, category in pairs(recipe.categories) do
            if category == "fluid-pmr" then
                fluid_pmr_recipes[#fluid_pmr_recipes + 1] = recipe
                break
            end
        end
    end
    return fluid_pmr_recipes
end

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

    local crafter = surface.create_entity({
        name     = "fluid-pmr-crafter",
        position = position,
        force    = force,
    })

    return {
        shell    = shell,
        pump     = pump,
        subtanks = subtanks,
        crafter  = crafter,
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
        if data.crafter.valid then data.crafter.destroy() end
    end

    storage.fluid_pmrs[entity.unit_number] = nil
end

-- ─── GUI ─────────────────────────────────────────────────────────────────────
-- 2.1's native storage-tank GUI (circuit connection subwindow, flush
-- buttons, status light, entity preview) is left alone — player.opened is
-- never overridden, so it opens exactly as it would for any other storage
-- tank. There's no supported way to dock our own content inside it (no
-- relative_gui_type exists for storage-tank), so the sub-tank breakdown is
-- shown as a separate, unanchored floating panel alongside it instead.

local CLOSE_BUTTON_NAME = "fluid_pmr_close_button"

-- Vanilla-style title bar: drag handle over the whole frame, a status light
-- (green while the intake gate is open/empty, red while a batch is staged
-- and draining), and a close button — matches the chrome every native
-- machine GUI has.
-- Returns the status sprite element so M.on_tick can update it live.
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

    local status = titlebar.add({
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

    return status
end

-- Sets a titlebar status sprite's appearance from the shell's current gate
-- state. Shared by initial build and the live tick refresh.
local function set_status(status, gate_open)
    status.sprite = gate_open and "utility/status_working" or "utility/status_yellow"
    status.tooltip = gate_open and "Ready for input" or "Draining staged fluid"
end

-- One fluid bar per supported fluid: icon, progressbar tinted to the
-- fluid's own color, and an amount/capacity label — same information a
-- vanilla fluid gauge shows. Returns { [fluid_name] = { bar = .., label = .. } }
-- so M.on_tick can update values in place without rebuilding the GUI.
local function add_fluid_bars(frame, data)
    local content = frame.add({ type = "frame", style = "inside_shallow_frame_with_padding", direction = "vertical" })
    local bars = {}
    for _, fluid_name in ipairs(FLUID_PMR_FLUIDS) do
        local subtank = data.subtanks[fluid_name]
        local fluid = subtank and subtank.valid and subtank.get_fluid(1)
        local amount = fluid and fluid.amount or 0
        local capacity = (subtank and subtank.valid) and subtank.get_fluid_capacity(1) or 1

        local fluid_proto = prototypes.fluid[fluid_name]
        local display_name = fluid_proto and fluid_proto.localised_name or fluid_name

        local row = content.add({ type = "flow" })
        row.style.vertical_align = "center"
        row.add({ type = "sprite", sprite = "fluid/" .. fluid_name, tooltip = display_name })

        local bar = row.add({ type = "progressbar", value = amount / capacity })
        bar.style.width = 150
        if fluid_proto and fluid_proto.base_color then
            bar.style.color = fluid_proto.base_color
        end

        local label = row.add({ type = "label", caption = { "", display_name, string.format(": %d / %d", amount, capacity) } })

        bars[fluid_name] = { bar = bar, label = label, display_name = display_name, capacity = capacity }
    end
    return bars
end

-- Refreshes an already-built fluid bar/label pair from the sub-tank's
-- current contents — no element creation, so no flicker.
local function update_fluid_bar(bar_ref, subtank)
    local fluid = subtank and subtank.valid and subtank.get_fluid(1)
    local amount = fluid and fluid.amount or 0
    bar_ref.bar.value = amount / bar_ref.capacity
    bar_ref.label.caption = { "", bar_ref.display_name, string.format(": %d / %d", amount, bar_ref.capacity) }
end

-- Docking beneath the native storage-tank window isn't possible: that
-- window is rendered by the engine itself and isn't exposed as a child of
-- player.gui.screen (that root only ever contains mod-created elements),
-- so there's no on-screen position to read. Confirmed by testing, not just
-- unverified — a fixed position is the only option here. Which corner is
-- controlled by the "the-reef-fluid-pmr-gui-position" runtime-per-user
-- setting (same idea as Bob's Adjustable Inserters' own dock-position
-- setting), so players who don't like the default can move it.
local SCREEN_MARGIN = 100
local TOP_Y = 200

local function panel_location(player, frame)
    local usable_width  = player.display_resolution.width  / player.display_scale
    local usable_height = player.display_resolution.height / player.display_scale
    local frame_width  = frame.style.minimal_width  or 250
    local frame_height = frame.style.minimal_height or 200

    local position = settings.get_player_settings(player)["the-reef-fluid-pmr-gui-position"].value

    if position == "top-left" then
        return { x = SCREEN_MARGIN, y = TOP_Y }
    elseif position == "bottom-right" then
        return { x = usable_width - frame_width - SCREEN_MARGIN, y = usable_height - frame_height - SCREEN_MARGIN }
    elseif position == "bottom-left" then
        return { x = SCREEN_MARGIN, y = usable_height - frame_height - SCREEN_MARGIN }
    else -- "top-right", the default
        return { x = usable_width - frame_width - SCREEN_MARGIN, y = TOP_Y }
    end
end

-- Returns { frame = .., status = .., bars = .. } — status and bars are the
-- live-updatable element refs used by M.on_tick's refresh loop.
local function build_subtank_gui(player, data, gate_open)
    local frame = player.gui.screen.add({
        type      = "frame",
        name      = "fluid_pmr_readout",
        direction = "vertical",
    })
    local status = add_titlebar(frame, gate_open)
    local bars = add_fluid_bars(frame, data)

    frame.location = panel_location(player, frame)

    return { frame = frame, status = status, bars = bars }
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
    if old and old.frame and old.frame.valid then old.frame.destroy() end

    local staged = entity.valid and entity.get_fluid(1)
    local gate_open = not (staged and staged.amount > 0)

    -- Deliberately not setting player.opened here — leaving it as the
    -- entity itself (the default) is what gives us the native GUI. Our
    -- frame is purely a supplementary window.
    local gui = build_subtank_gui(player, data, gate_open)
    gui.unit_number = entity.unit_number
    storage.fluid_pmr_guis[event.player_index] = gui
end

function M.on_gui_closed(event)
    storage.fluid_pmr_guis = storage.fluid_pmr_guis or {}
    local gui = storage.fluid_pmr_guis[event.player_index]
    if gui and gui.frame and gui.frame.valid then gui.frame.destroy() end
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
    if space <= 0 then
        -- Sub-tank is full — void whatever's staged in the shell rather than
        -- leaving it stuck there. That backup would otherwise keep the
        -- intake pump's circuit gate closed (signal-everything == 0 on the
        -- shell) indefinitely, blocking all other fluids too. Accepted
        -- tradeoff: no back-pressure friction, just loss.
        data.shell.remove_fluid(1, fluid.amount)
        return true
    end

    local take = math.min(fluid.amount, space)
    subtank.add_fluid(1, { name = fluid.name, amount = take, temperature = fluid.temperature })
    data.shell.remove_fluid(1, take)

    return true
end

-- ─── Item output ─────────────────────────────────────────────────────────────
-- No loader entity — the sub-tanks are fluidboxes, not item inventories, so
-- there is no item stack for a loader to pull from. Fallback chain on the
-- east-adjacent tile: belt, then container, then bare ground. The target is
-- resolved ONCE per output cycle and reused for every item moved that cycle
-- (the previous per-item re-scan cost several find_entities_filtered calls
-- per single item).

local function output_pos(entity)
    local p = entity.position
    return { x = p.x + 2, y = p.y }
end

-- Belts are matched by type, never by prototype name — fast/express/turbo
-- belts have different names but all share type = "transport-belt".
-- (Name-matching was confirmed as the cause of items silently falling
-- through to the ground-spill fallback when a turbo belt was in place.)
local function resolve_output(surface, pos)
    local belt = surface.find_entities_filtered({ position = pos, type = "transport-belt" })[1]
    if belt then return { kind = "belt", belt = belt } end

    local area = { { pos.x - 0.5, pos.y - 0.5 }, { pos.x + 0.5, pos.y + 0.5 } }
    local containers = surface.find_entities_filtered({ area = area, type = { "container", "logistic-container" } })
    if #containers > 0 then return { kind = "containers", containers = containers } end

    -- Bare ground: allow at most one spilled item per cycle (matching the
    -- old behavior, where an existing item-entity blocked further output).
    local clear = #surface.find_entities_filtered({ area = area, type = "item-entity" }) == 0
    return { kind = "ground", clear = clear }
end

-- Moves one item to the resolved target. Returns false when the target is
-- full/blocked, which ends the cycle for that stack.
local function output_one(target, surface, pos, item_name)
    if target.kind == "belt" then
        if not target.belt.valid then return false end
        local left  = target.belt.get_transport_line(defines.transport_line.left_line)
        local right = target.belt.get_transport_line(defines.transport_line.right_line)
        if left.can_insert_at_back() then
            left.insert_at_back({ name = item_name, count = 1 })
            return true
        elseif right.can_insert_at_back() then
            right.insert_at_back({ name = item_name, count = 1 })
            return true
        end
        return false
    elseif target.kind == "containers" then
        for _, cont in ipairs(target.containers) do
            if cont.valid then
                local inv = cont.get_inventory(defines.inventory.chest)
                if inv and inv.can_insert({ name = item_name, count = 1 }) then
                    inv.insert({ name = item_name, count = 1 })
                    return true
                end
            end
        end
        return false
    else
        if not target.clear then return false end
        surface.spill_item_stack({
            position = pos,
            stack = { name = item_name, count = 1 },
            max_radius = 0,
            use_start_position_on_failure = true,
            allow_belts = false,
        })
        target.clear = false
        return true
    end
end

-- ─── Crafter feeding ─────────────────────────────────────────────────────────
-- The crafter is only fed a new batch once its own fluidboxes are fully
-- drained — this keeps "exactly enough fluid, no leftover" true by
-- construction (n batches worth of each ingredient divides out to exactly
-- 0 remaining once the crafter finishes its n-th craft). If any fluid is
-- somehow still sitting in the crafter's boxes when this runs, it's simply
-- left alone until it drains — no voiding needed here, that's only for the
-- (deferred) input-tank-on-destruction policy.

-- Only the fluidbox indices the crafter's *currently assigned* recipe
-- actually references are valid to query — a recipe with fewer fluid
-- ingredients than the crafter's declared 3 boxes leaves the unused
-- index(es) genuinely out of range (not just empty), confirmed by an
-- out-of-bounds get_fluid crash when switching from a 3-ingredient recipe
-- to a 2-ingredient one. No recipe assigned means nothing to sum.
local function crafter_fluid_total(crafter)
    local recipe = crafter.get_recipe()
    if not recipe then return 0 end

    local total = 0
    for _, ingredient in pairs(recipe.ingredients) do
        if ingredient.type == "fluid" then
            local fluid = crafter.get_fluid(ingredient.fluidbox_index)
            if fluid then total = total + fluid.amount end
        end
    end
    return total
end

-- Picks the affordable "fluid-pmr" recipe with the most fluid ingredients,
-- given the sub-tanks' current contents. Returns recipe, batch count (the
-- maximum number of full crafts affordable right now) — or nil if nothing
-- is affordable.
local function pick_recipe(data)
    local best, best_batches, best_count = nil, 0, -1

    for _, recipe in pairs(get_fluid_pmr_recipes()) do
        local batches = math.huge
        local affordable = true

        for _, ingredient in pairs(recipe.ingredients) do
            if ingredient.type ~= "fluid" then
                affordable = false
                break
            end
            local subtank = data.subtanks[ingredient.name]
            local fluid = subtank and subtank.valid and subtank.get_fluid(1)
            local amount = fluid and fluid.amount or 0
            local possible = math.floor(amount / ingredient.amount)
            if possible < batches then batches = possible end
        end

        if affordable and batches >= 1 then
            local ingredient_count = #recipe.ingredients
            if ingredient_count > best_count then
                best, best_batches, best_count = recipe, batches, ingredient_count
            end
        end
    end

    return best, best_batches
end

-- Removes exactly batches * ingredient.amount from each relevant sub-tank
-- and inserts it into the crafter's matching fluidbox (fluidbox_index set
-- explicitly on each ingredient in prototypes/recipes.lua).
local function feed_crafter(data, recipe, batches)
    local crafter = data.crafter
    if crafter.get_recipe() ~= recipe then
        crafter.set_recipe(recipe)
    end

    for _, ingredient in pairs(recipe.ingredients) do
        local subtank = data.subtanks[ingredient.name]
        local fluid = subtank.get_fluid(1)
        local amount = ingredient.amount * batches
        subtank.remove_fluid(1, amount)
        crafter.add_fluid(ingredient.fluidbox_index, {
            name        = ingredient.name,
            amount      = amount,
            temperature = fluid.temperature,
        })
    end
end

-- ─── Crafter output drain ────────────────────────────────────────────────────
-- Pulls finished items out of the crafter's own output inventory (vanilla
-- assembling-machine logic fills this automatically once fed) and places
-- them via the resolved output target above.

local function drain_crafter_output(data)
    local crafter = data.crafter
    if not crafter.valid then return end

    local inventory = crafter.get_output_inventory()
    if not inventory then return end

    local pos = output_pos(data.shell)
    local surface = data.shell.surface
    local target = resolve_output(surface, pos)

    for i = 1, #inventory do
        local stack = inventory[i]
        while stack.valid_for_read and stack.count > 0
            and output_one(target, surface, pos, stack.name)
        do
            stack.count = stack.count - 1
        end
    end
end

local function produce(data)
    if not data.shell.valid or not data.crafter.valid then return false end

    if crafter_fluid_total(data.crafter) == 0 then
        local recipe, batches = pick_recipe(data)
        if recipe then
            feed_crafter(data, recipe, batches)
        end
    end

    drain_crafter_output(data)

    return true
end

-- Refreshes every open fluid-bar panel from its PMR's current sub-tank
-- contents. Runs on the same cadence as the drain step, since that's the
-- only thing that changes sub-tank amounts.
local function refresh_open_guis()
    storage.fluid_pmr_guis = storage.fluid_pmr_guis or {}
    for player_index, gui in pairs(storage.fluid_pmr_guis) do
        if not gui.frame or not gui.frame.valid then
            storage.fluid_pmr_guis[player_index] = nil
        else
            local data = storage.fluid_pmrs[gui.unit_number]
            if not data or not data.shell.valid then
                gui.frame.destroy()
                storage.fluid_pmr_guis[player_index] = nil
            else
                local staged = data.shell.get_fluid(1)
                set_status(gui.status, not (staged and staged.amount > 0))
                for fluid_name, bar_ref in pairs(gui.bars) do
                    update_fluid_bar(bar_ref, data.subtanks[fluid_name])
                end
            end
        end
    end
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

    if do_drain then refresh_open_guis() end
end

return M
