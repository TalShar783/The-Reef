-- Cargo Hatch script.
--
-- Handles both hatch types:
--   cargo-hatch          (basic)    — container with scripted tick-based hub sync and filter GUI
--   advanced-cargo-hatch (advanced) — cargo-bay type; inserter access via proxy-container that
--                                     forwards interactions directly to the hub inventory

local SYNC_INTERVAL   = 30
local BASE_LIMIT      = 1
local BASE_RANGE      = 20
local RANGE_PER_LEVEL = 5

local M = {}

-- ─── Storage ─────────────────────────────────────────────────────────────────

function M.on_init()
    storage.hatches                    = {}
    storage.hatch_gui                  = {}
    storage.cargo_hatch_extra_capacity = {}
    storage.cargo_hatch_extra_range    = {}
    storage.adv_hatch_proxies          = {}   -- unit_number -> proxy LuaEntity
end

-- ─── Limit / range helpers ───────────────────────────────────────────────────

local function get_limit(force)
    local extra = storage.cargo_hatch_extra_capacity
                  and storage.cargo_hatch_extra_capacity[force.index] or 0
    return BASE_LIMIT + extra
end

local function get_range(force)
    local extra = storage.cargo_hatch_extra_range
                  and storage.cargo_hatch_extra_range[force.index] or 0
    return BASE_RANGE + extra
end

local function get_platform_hatch_count(surface)
    return #surface.find_entities_filtered({ name = { "cargo-hatch", "advanced-cargo-hatch" } })
end

local function get_hub(surface)
    local hubs = surface.find_entities_filtered({ type = "space-platform-hub" })
    return hubs[1]
end

local function tile_distance(pos1, pos2)
    local dx = pos1.x - pos2.x
    local dy = pos1.y - pos2.y
    return math.sqrt(dx * dx + dy * dy)
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

-- ─── Build validation ────────────────────────────────────────────────────────

-- on_pre_build fires BEFORE the entity is created, giving us the chance to
-- show the "can't build" sound and flying text exactly where the cursor is.
function M.on_pre_build(event)
    local player = game.players[event.player_index]
    local cursor = player.cursor_stack
    if not (cursor and cursor.valid_for_read) then return end
    if cursor.name ~= "cargo-hatch" and cursor.name ~= "advanced-cargo-hatch" then return end

    local surface = player.surface
    if not surface.platform then return end

    local hub = get_hub(surface)
    if hub then
        local range = get_range(player.force)
        local dist  = tile_distance(event.position, hub.position)
        if dist > range then
            player.play_sound({ path = "utility/cannot_build" })
            player.create_local_flying_text({
                position     = event.position,
                text         = { "cargo-hatch.range-exceeded", math.floor(dist), range },
                color        = { r = 1, g = 0.5, b = 0.5 },
                time_to_live = 120,
            })
            return
        end
    end

    local limit = get_limit(player.force)
    local count = get_platform_hatch_count(surface)
    if count >= limit then
        player.play_sound({ path = "utility/cannot_build" })
        player.create_local_flying_text({
            position     = event.position,
            text         = { "cargo-hatch.limit-reached", count, limit },
            color        = { r = 1, g = 0.5, b = 0.5 },
            time_to_live = 120,
        })
    end
end

local function refund_hatch(event, surface, pos, item_name)
    if event.player_index then
        game.players[event.player_index].insert({ name = item_name, count = 1 })
    else
        surface.spill_item_stack({
            position                      = pos,
            stack                         = { name = item_name, count = 1 },
            enable_looted                 = false,
            allow_belts                   = false,
            use_start_position_on_failure = true,
        })
    end
end

local HATCH_NAMES = { ["cargo-hatch"] = true, ["advanced-cargo-hatch"] = true }

-- ─── Advanced hatch proxy ────────────────────────────────────────────────────

local function spawn_adv_hatch_proxy(entity)
    storage.adv_hatch_proxies = storage.adv_hatch_proxies or {}
    local proxy = entity.surface.create_entity({
        name     = "advanced-cargo-hatch-proxy",
        force    = entity.force,
        position = entity.position,
    })
    if not proxy then return end
    proxy.destructible             = false
    proxy.proxy_target_inventory   = defines.inventory.hub_main
    local hub = get_hub(entity.surface)
    if hub then proxy.proxy_target_entity = hub end
    storage.adv_hatch_proxies[entity.unit_number] = proxy
end

local function destroy_adv_hatch_proxy(unit_number)
    storage.adv_hatch_proxies = storage.adv_hatch_proxies or {}
    local proxy = storage.adv_hatch_proxies[unit_number]
    if proxy and proxy.valid then proxy.destroy() end
    storage.adv_hatch_proxies[unit_number] = nil
end

-- ─── Build / remove ──────────────────────────────────────────────────────────

function M.on_built(event)
    local entity = event.entity or event.created_entity
    if not entity or not HATCH_NAMES[entity.name] then return end

    local surface = entity.surface
    if surface.platform then
        local pos  = entity.position
        local item = entity.name

        local hub = get_hub(surface)
        if hub then
            local range = get_range(entity.force)
            if tile_distance(pos, hub.position) > range then
                entity.destroy({ raise_destroy = false })
                refund_hatch(event, surface, pos, item)
                return
            end
        end

        local limit = get_limit(entity.force)
        local count = get_platform_hatch_count(surface)
        if count > limit then
            entity.destroy({ raise_destroy = false })
            refund_hatch(event, surface, pos, item)
            return
        end
    end

    if entity.name == "advanced-cargo-hatch" then
        spawn_adv_hatch_proxy(entity)
    else
        register(entity)
    end
end

function M.on_removed(event)
    local entity = event.entity
    if not entity or not HATCH_NAMES[entity.name] then return end
    if entity.name == "advanced-cargo-hatch" then
        destroy_adv_hatch_proxy(entity.unit_number)
    else
        unregister(entity)
    end
end

-- ─── Research handler ────────────────────────────────────────────────────────

function M.on_research_finished(event)
    local name = event.research.name
    local fi   = event.research.force.index
    if name == "the-reef-cargo-hatch-capacity" then
        storage.cargo_hatch_extra_capacity = storage.cargo_hatch_extra_capacity or {}
        storage.cargo_hatch_extra_capacity[fi] = (storage.cargo_hatch_extra_capacity[fi] or 0) + 1
    elseif name == "the-reef-cargo-hatch-range" then
        storage.cargo_hatch_extra_range = storage.cargo_hatch_extra_range or {}
        storage.cargo_hatch_extra_range[fi] = (storage.cargo_hatch_extra_range[fi] or 0) + RANGE_PER_LEVEL
    end
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
    local inv = data.entity.get_inventory(defines.inventory.chest)
    if not inv then return end
    local cargo = get_cargo_inventory(data.entity.surface)
    for i = 1, #inv do
        local stack = inv[i]
        if stack.valid_for_read then
            local moved = cargo and cargo.insert(stack) or 0
            if moved < stack.count then
                -- Hub full (or missing) — spill the remainder at the hatch
                -- instead of destroying it with the stack.clear() below.
                data.entity.surface.spill_item_stack({
                    position                      = data.entity.position,
                    stack                         = {
                        name    = stack.name,
                        count   = stack.count - moved,
                        quality = stack.quality.name,
                    },
                    enable_looted                 = false,
                    allow_belts                   = false,
                    use_start_position_on_failure = true,
                })
            end
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

    local surface = data.entity.surface
    if surface.platform then
        local limit = get_limit(data.entity.force)
        local count = get_platform_hatch_count(surface)
        local cap_row = frame.add({ type = "flow", direction = "horizontal" })
        cap_row.add({
            type    = "label",
            caption = { "cargo-hatch-gui.capacity", count, limit },
        })

        local hub   = get_hub(surface)
        local range = get_range(data.entity.force)
        local dist  = hub and math.floor(tile_distance(data.entity.position, hub.position)) or 0
        local rng_row = frame.add({ type = "flow", direction = "horizontal" })
        rng_row.add({
            type    = "label",
            caption = { "cargo-hatch-gui.range", dist, range },
        })
    end

    local row1 = frame.add({ type = "flow", direction = "horizontal" })
    row1.style.vertical_align = "center"
    row1.add({ type = "label", caption = { "cargo-hatch-gui.item-label" } })
    row1.add({
        type      = "choose-elem-button",
        name      = "cargo-hatch-item-picker",
        elem_type = "item",
        item      = data.item or nil,
    })

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
