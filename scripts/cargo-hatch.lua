-- Cargo Hatch script.
--
-- A 1-slot container that bridges inserters and the platform cargo hub.
--
-- Extract mode (default): when the hatch buffer is empty, pulls one full
--   stack of the configured item from the cargo hub. Inserters then take
--   from the hatch. Buffer only refills when completely drained (Option B).
--
-- Insert mode: anything placed in the hatch by inserters is moved to the
--   cargo hub on the next sync tick.
--
-- Wrong-type items in the buffer are always returned to cargo immediately.
--
-- Tuning:
local SYNC_INTERVAL = 30   -- ticks between syncs (30 = twice per second)

local M = {}

-- ─── Storage initialisation ──────────────────────────────────────────────────
-- storage.hatches[unit_number]   = { entity, item, mode }
-- storage.hatch_gui[player_index] = unit_number

function M.on_init()
    storage.hatches   = {}
    storage.hatch_gui = {}
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
    -- Close any player GUIs that were open on this hatch
    for pid, uid in pairs(storage.hatch_gui) do
        if uid == entity.unit_number then
            local player = game.players[pid]
            local frame  = player.gui.screen["cargo-hatch-gui"]
            if frame then frame.destroy() end
            storage.hatch_gui[pid] = nil
        end
    end
    storage.hatches[entity.unit_number] = nil
end

function M.on_built(event)
    local entity = event.entity or event.created_entity
    if entity and entity.name == "cargo-hatch" then
        register(entity)
    end
end

function M.on_removed(event)
    local entity = event.entity
    if entity and entity.name == "cargo-hatch" then
        unregister(entity)
    end
end

-- ─── Platform cargo inventory ────────────────────────────────────────────────

local function get_cargo_inventory(surface)
    -- Prefer the LuaSpacePlatform API (Factorio 2.x)
    if surface.platform then
        local cargo = surface.platform.cargo_inventory
        if cargo then return cargo end
    end
    -- Fallback: inventory 1 of the hub entity
    local hubs = surface.find_entities_filtered({ type = "space-platform-hub" })
    if hubs[1] then return hubs[1].get_inventory(1) end
    return nil
end

-- ─── Sync ────────────────────────────────────────────────────────────────────

local function sync(data)
    local hatch = data.entity
    if not hatch.valid then return end
    if not data.item   then return end

    local cargo = get_cargo_inventory(hatch.surface)
    if not cargo then return end

    local inv  = hatch.get_inventory(defines.inventory.chest)
    local item = data.item

    -- Return any wrong-type items to cargo immediately
    for i = 1, #inv do
        local stack = inv[i]
        if stack.valid_for_read and stack.name ~= item then
            local moved = cargo.insert(stack)
            stack.count = stack.count - moved
        end
    end

    if data.mode == "extract" then
        -- Option B: only pull when buffer is completely empty
        if inv.get_item_count(item) == 0 then
            local available = cargo.get_item_count(item)
            if available > 0 then
                local stack_size = game.item_prototypes[item].stack_size
                local n = cargo.remove({ name = item, count = math.min(stack_size, available) })
                inv.insert({ name = item, count = n })
            end
        end

    else  -- insert
        local count = inv.get_item_count(item)
        if count > 0 then
            local inserted = cargo.insert({ name = item, count = count })
            inv.remove({ name = item, count = inserted })
        end
    end
end

function M.on_tick(event)
    if event.tick % SYNC_INTERVAL ~= 0 then return end
    for _, data in pairs(storage.hatches) do
        sync(data)
    end
end

-- ─── GUI ─────────────────────────────────────────────────────────────────────

local function flush_buffer(data)
    -- Return hatch buffer contents to cargo (called on item/mode change)
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

local function close_gui(player)
    local frame = player.gui.screen["cargo-hatch-gui"]
    if frame then frame.destroy() end
    storage.hatch_gui[player.index] = nil
end

local function build_gui(player, data)
    close_gui(player)

    local frame = player.gui.screen.add({
        type      = "frame",
        name      = "cargo-hatch-gui",
        caption   = { "entity-name.cargo-hatch" },
        direction = "vertical",
    })
    frame.auto_center = true

    -- Item picker
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

    frame.add({ type = "button", name = "cargo-hatch-close", caption = { "gui.close" } })
end

function M.on_gui_opened(event)
    if event.gui_type ~= defines.gui_type.entity then return end
    local entity = event.entity
    if not entity or entity.name ~= "cargo-hatch" then return end

    local player = game.players[event.player_index]
    local data   = storage.hatches[entity.unit_number]
    if not data then return end

    storage.hatch_gui[event.player_index] = entity.unit_number
    player.opened = nil   -- suppress the default container GUI
    build_gui(player, data)
end

function M.on_gui_click(event)
    local el = event.element
    if not el or not el.valid then return end
    local player = game.players[event.player_index]

    if el.name == "cargo-hatch-close" then
        close_gui(player)

    elseif el.name == "cargo-hatch-mode-toggle" then
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

    flush_buffer(data)    -- return old item to cargo before switching
    data.item = el.elem_value
end

return M
