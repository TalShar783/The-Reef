-- Cargo Hatch script.
--
-- A 2x2 container that bridges inserters and the platform cargo hub.
-- The default container GUI shows the 1-slot buffer (current contents).
-- A relative panel (player.gui.relative) shows configuration controls.
--
-- Limit system:
--   Each space platform starts with a limit of BASE_LIMIT hatches.
--   Researching the-reef-cargo-hatch-capacity adds 1 per level.
--   Limits are per-platform automatically (each platform = separate surface).

local SYNC_INTERVAL = 30
local BASE_LIMIT    = 1   -- hatches per platform when first unlocked

local M = {}

-- ─── Storage ─────────────────────────────────────────────────────────────────

function M.on_init()
    storage.hatches                    = {}
    storage.hatch_gui                  = {}
    storage.cargo_hatch_extra_capacity = {}  -- [force_index] = extra slots from research
end

-- ─── Limit helpers ───────────────────────────────────────────────────────────

local function get_limit(force)
    local extra = storage.cargo_hatch_extra_capacity
                  and storage.cargo_hatch_extra_capacity[force.index] or 0
    return BASE_LIMIT + extra
end

local function get_platform_hatch_count(surface)
    return #surface.find_entities_filtered({ name = "cargo-hatch" })
end

-- ─── Registration ────────────────────────────────────────────────────────────

local function register(entity)
    storage.hatches[entity.unit_number] = {
        entity = entity,
        item   = nil,
        mode   = "extract",
    }
end

local function unregister(entity)
    for pid, uid in pairs(storage.hatch_gui) do
        if uid == entity.unit_number then
            local player = game.players[pid]
            local frame  = player.gui.relative["cargo-hatch-config"]
            if frame then frame.destroy() end
            storage.hatch_gui[pid] = nil
        end
    end
    storage.hatches[entity.unit_number] = nil
end

function M.on_built(event)
    local entity = event.entity or event.created_entity
    if not entity or entity.name ~= "cargo-hatch" then return end

    -- Enforce per-platform limit on space platforms
    local surface = entity.surface
    if surface.platform then
        local limit = get_limit(entity.force)
        local count = get_platform_hatch_count(surface)
        -- count includes this newly placed entity
        if count > limit then
            local pos   = entity.position
            local force = entity.force
            entity.destroy()

            if event.player_index then
                local player = game.players[event.player_index]
                player.insert({ name = "cargo-hatch", count = 1 })
                player.print({
                    "cargo-hatch.limit-reached",
                    count - 1,   -- current count before this one
                    limit,
                })
            else
                -- Placed by robot — spill item on ground for pickup
                surface.spill_item_stack({
                    position                  = pos,
                    stack                     = { name = "cargo-hatch", count = 1 },
                    enable_looted             = false,
                    allow_belts               = false,
                    use_start_position_on_failure = true,
                })
            end
            return
        end
    end

    register(entity)
end

function M.on_removed(event)
    local entity = event.entity
    if entity and entity.name == "cargo-hatch" then unregister(entity) end
end

-- ─── Research handler ────────────────────────────────────────────────────────

function M.on_research_finished(event)
    if event.research.name ~= "the-reef-cargo-hatch-capacity" then return end
    storage.cargo_hatch_extra_capacity = storage.cargo_hatch_extra_capacity or {}
    local fi = event.research.force.index
    storage.cargo_hatch_extra_capacity[fi] = (storage.cargo_hatch_extra_capacity[fi] or 0) + 1
end

-- ─── Platform cargo inventory ────────────────────────────────────────────────

local function get_cargo_inventory(surface)
    -- LuaSpacePlatform.cargo_inventory doesn't exist in Factorio 2.x;
    -- accessing a missing key on a C++ Factorio object throws rather than
    -- returning nil. Use the hub entity's inventory directly instead.
    local hubs = surface.find_entities_filtered({ type = "space-platform-hub" })
    if hubs[1] then return hubs[1].get_inventory(1) end
    return nil
end

-- ─── Buffer flush ────────────────────────────────────────────────────────────

local function flush_buffer(data)
    if not data.entity.valid then return end
    local inv   = data.entity.get_inventory(defines.inventory.chest)
    local cargo = get_cargo_inventory(data.entity.surface)
    if not inv or not cargo then return end
    for i = 1, #inv do
        local stack = inv[i]
        if stack.valid_for_read then
            cargo.insert(stack)
            stack.clear()
        end
    end
end

-- ─── Sync ────────────────────────────────────────────────────────────────────

local function sync(data)
    local hatch = data.entity
    if not hatch.valid or not data.item then return end

    local cargo = get_cargo_inventory(hatch.surface)
    if not cargo then return end

    local inv  = hatch.get_inventory(defines.inventory.chest)
    local item = data.item

    for i = 1, #inv do
        local stack = inv[i]
        if stack.valid_for_read and stack.name ~= item then
            local moved = cargo.insert(stack)
            stack.count = stack.count - moved
        end
    end

    if data.mode == "extract" then
        if inv.get_item_count(item) == 0 then
            local available = cargo.get_item_count(item)
            if available > 0 then
                local stack_size = prototypes.item[item].stack_size
                local n = cargo.remove({ name = item, count = math.min(stack_size, available) })
                inv.insert({ name = item, count = n })
            end
        end
    else
        local count = inv.get_item_count(item)
        if count > 0 then
            local inserted = cargo.insert({ name = item, count = count })
            inv.remove({ name = item, count = inserted })
        end
    end
end

function M.on_tick(event)
    if event.tick % SYNC_INTERVAL ~= 0 then return end
    for _, data in pairs(storage.hatches) do sync(data) end
end

-- ─── GUI ─────────────────────────────────────────────────────────────────────

local function build_gui(player, data)
    local rel = player.gui.relative
    if rel["cargo-hatch-config"] then rel["cargo-hatch-config"].destroy() end

    local frame = rel.add({
        type      = "frame",
        name      = "cargo-hatch-config",
        caption   = { "entity-name.cargo-hatch" },
        direction = "vertical",
        anchor    = {
            gui      = defines.relative_gui_type.container_gui,
            position = defines.relative_gui_position.right,
        },
    })

    -- Capacity display (only on space platforms)
    local surface = data.entity.surface
    if surface.platform then
        local limit = get_limit(data.entity.force)
        local count = get_platform_hatch_count(surface)
        local cap_row = frame.add({ type = "flow", direction = "horizontal" })
        cap_row.add({
            type    = "label",
            caption = { "cargo-hatch-gui.capacity", count, limit },
        })
    end

    -- Item filter
    local row1 = frame.add({ type = "flow", direction = "horizontal" })
    row1.style.vertical_align = "center"
    row1.add({ type = "label", caption = { "cargo-hatch-gui.item-label" } })
    row1.add({
        type      = "choose-elem-button",
        name      = "cargo-hatch-item-picker",
        elem_type = "item",
        item      = data.item or nil,
    })

    -- Mode toggle
    local row2 = frame.add({ type = "flow", direction = "horizontal" })
    row2.style.vertical_align = "center"
    row2.add({ type = "label", caption = { "cargo-hatch-gui.mode-label" } })
    row2.add({
        type    = "button",
        name    = "cargo-hatch-mode-toggle",
        caption = data.mode == "extract"
                  and { "cargo-hatch-gui.mode-extract" }
                  or  { "cargo-hatch-gui.mode-insert" },
    })
end

function M.on_gui_opened(event)
    if event.gui_type ~= defines.gui_type.entity then return end
    local entity = event.entity
    if not entity or entity.name ~= "cargo-hatch" then return end

    local player = game.players[event.player_index]
    local data   = storage.hatches[entity.unit_number]
    if not data then return end

    storage.hatch_gui[event.player_index] = entity.unit_number
    build_gui(player, data)
end

function M.on_gui_closed(event)
    if event.gui_type ~= defines.gui_type.entity then return end
    local entity = event.entity
    if not entity or entity.name ~= "cargo-hatch" then return end

    local player = game.players[event.player_index]
    local frame  = player.gui.relative["cargo-hatch-config"]
    if frame then frame.destroy() end
    storage.hatch_gui[event.player_index] = nil
end

function M.on_gui_click(event)
    local el = event.element
    if not el or not el.valid then return end

    if el.name == "cargo-hatch-mode-toggle" then
        local uid  = storage.hatch_gui[event.player_index]
        local data = uid and storage.hatches[uid]
        if not data then return end

        flush_buffer(data)
        data.mode  = data.mode == "extract" and "insert" or "extract"
        el.caption = data.mode == "extract"
                     and { "cargo-hatch-gui.mode-extract" }
                     or  { "cargo-hatch-gui.mode-insert" }
    end
end

function M.on_gui_elem_changed(event)
    local el = event.element
    if not el or not el.valid or el.name ~= "cargo-hatch-item-picker" then return end

    local uid  = storage.hatch_gui[event.player_index]
    local data = uid and storage.hatches[uid]
    if not data then return end

    flush_buffer(data)
    data.item = el.elem_value
end

return M
