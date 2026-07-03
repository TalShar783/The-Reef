-- Cargo Hatch script.
--
-- The hatch is a cargo-bay-lookalike entity plus a hidden proxy-container
-- (cargo-hatch-proxy) on the same tiles that exposes the platform hub's main
-- inventory directly to inserters — native engine passthrough, no per-item
-- scripting and no configuration GUI.
--
-- Script enforces three research-scalable rules per force:
--   * placement limit per platform (count)
--   * max placement distance from the hub
--   * throughput throttle — a token bucket refilled at R items/sec. A
--     proxy-container is engine passthrough and fires no transfer events, so
--     items moving through the hatch are counted by watching the hands of
--     the inserters that target it. When the bucket runs dry, the proxy's
--     target detaches (inserters stall harmlessly) and the hatch shows a red
--     "On cooldown" status until the bucket refills. Whole swings always
--     pass: the budget may go negative, which just lengthens the cooldown
--     (a 12-item bulk swing on a 4/sec hatch costs 3 seconds of cooldown).
--     Player hand-transfers through the GUI are deliberately not counted —
--     the throttle governs automation, not the player. The final throughput
--     research level removes the throttle entirely.

local BASE_LIMIT      = 1
local BASE_RANGE      = 20
local RANGE_PER_LEVEL = 5

local BASE_RATE            = 4    -- items/sec with no throughput research
local RATE_PER_LEVEL       = 4    -- added per throughput research level
local MAX_THROUGHPUT_LEVEL = 10   -- this level removes the throttle

local THROTTLE_INTERVAL       = 5    -- ticks between throttle passes
local INSERTER_RESCAN_TICKS   = 120  -- ticks between adjacent-inserter rescans
local INSERTER_SCAN_RADIUS    = 4    -- tiles around the hatch center

local M = {}

-- ─── Storage ─────────────────────────────────────────────────────────────────

function M.on_init()
    storage.hatches                    = {}   -- unit_number -> hatch data
    storage.cargo_hatch_extra_capacity = {}   -- force index -> extra hatches
    storage.cargo_hatch_extra_range    = {}   -- force index -> extra tiles
    storage.cargo_hatch_throughput     = {}   -- force index -> research level
end

-- ─── Research-scaled values ──────────────────────────────────────────────────

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

-- Items/sec budget for the force, or nil when the throttle is researched away.
local function get_rate(force)
    local level = storage.cargo_hatch_throughput
                  and storage.cargo_hatch_throughput[force.index] or 0
    if level >= MAX_THROUGHPUT_LEVEL then return nil end
    return BASE_RATE + RATE_PER_LEVEL * level
end

-- ─── Surface helpers ─────────────────────────────────────────────────────────

local function get_platform_hatch_count(surface)
    return #surface.find_entities_filtered({ name = "cargo-hatch" })
end

local function get_hub(surface)
    local platform = surface.platform
    return platform and platform.hub or nil
end

local function tile_distance(pos1, pos2)
    local dx = pos1.x - pos2.x
    local dy = pos1.y - pos2.y
    return math.sqrt(dx * dx + dy * dy)
end

-- ─── Proxy ───────────────────────────────────────────────────────────────────

local function spawn_proxy(entity)
    local proxy = entity.surface.create_entity({
        name     = "cargo-hatch-proxy",
        force    = entity.force,
        position = entity.position,
    })
    if not proxy then return nil end
    proxy.destructible           = false
    proxy.proxy_target_inventory = defines.inventory.hub_main
    local hub = get_hub(entity.surface)
    if hub then proxy.proxy_target_entity = hub end
    return proxy
end

-- ─── Throttle ────────────────────────────────────────────────────────────────

local STATUS_COOLDOWN = {
    diode = defines.entity_status_diode.red,
    label = { "cargo-hatch.on-cooldown" },
}

local function held_count(inserter)
    local stack = inserter.held_stack
    return stack.valid_for_read and stack.count or 0
end

-- Refreshes the set of inserters whose pickup or drop target is this hatch
-- (targets resolve to whichever entity occupies the tile, so match both the
-- hatch and its proxy). Existing entries keep their hand baseline.
local function rescan_inserters(data, tick)
    data.next_scan = tick + INSERTER_RESCAN_TICKS
    local entity = data.entity
    local pos = entity.position
    local area = {
        { pos.x - INSERTER_SCAN_RADIUS, pos.y - INSERTER_SCAN_RADIUS },
        { pos.x + INSERTER_SCAN_RADIUS, pos.y + INSERTER_SCAN_RADIUS },
    }
    local tracked = {}
    for _, ins in ipairs(entity.surface.find_entities_filtered({ area = area, type = "inserter" })) do
        local drop = ins.drop_target
        local pick = ins.pickup_target
        if drop == entity or drop == data.proxy
            or pick == entity or pick == data.proxy then
            tracked[ins.unit_number] = data.inserters[ins.unit_number]
                or { entity = ins, prev = held_count(ins) }
        end
    end
    data.inserters = tracked
end

-- Counts items that moved through the hatch since the last pass by diffing
-- each tracked inserter's held stack: a decrease while dropping at the hatch
-- is an insertion into the hub; an increase while picking from the hatch is
-- an extraction. Hand changes on inserters interacting elsewhere don't touch
-- the budget because their targets don't match.
local function count_transfers(data)
    local moved = 0
    for uid, rec in pairs(data.inserters) do
        local ins = rec.entity
        if not ins.valid then
            data.inserters[uid] = nil
        else
            local cur = held_count(ins)
            if cur < rec.prev then
                local drop = ins.drop_target
                if drop == data.entity or drop == data.proxy then
                    moved = moved + (rec.prev - cur)
                end
            elseif cur > rec.prev then
                local pick = ins.pickup_target
                if pick == data.entity or pick == data.proxy then
                    moved = moved + (cur - rec.prev)
                end
            end
            rec.prev = cur
        end
    end
    return moved
end

local function detach(data)
    data.detached = true
    data.proxy.proxy_target_entity = nil
    data.entity.custom_status = STATUS_COOLDOWN
end

local function attach(data)
    data.detached = false
    local hub = get_hub(data.entity.surface)
    if hub then data.proxy.proxy_target_entity = hub end
    data.entity.custom_status = nil
    -- Re-baseline hands so movement during the cooldown (inserters swinging
    -- to/from other targets) isn't attributed to the hatch.
    for _, rec in pairs(data.inserters) do
        if rec.entity.valid then rec.prev = held_count(rec.entity) end
    end
end

-- One throttle pass for one hatch. Returns false when the hatch is gone.
local function throttle(data, tick)
    local entity = data.entity
    if not entity.valid then return false end

    if not (data.proxy and data.proxy.valid) then
        data.proxy = spawn_proxy(entity)   -- self-heal a lost proxy
        if not data.proxy then return true end
    end

    local rate = get_rate(entity.force)
    if not rate then
        -- Throttle researched away: make sure the hatch is live and idle out.
        if data.detached then attach(data) end
        return true
    end

    if tick >= data.next_scan then rescan_inserters(data, tick) end

    local bucket = rate   -- one second's worth of budget
    data.budget = math.min(data.budget + rate * (THROTTLE_INTERVAL / 60), bucket)

    if data.detached then
        if data.budget >= bucket then attach(data) end
        return true
    end

    data.budget = data.budget - count_transfers(data)
    if data.budget <= 0 then detach(data) end
    return true
end

function M.on_tick(event)
    if event.tick % THROTTLE_INTERVAL ~= 0 then return end
    for uid, data in pairs(storage.hatches) do
        if not throttle(data, event.tick) then
            if data.proxy and data.proxy.valid then data.proxy.destroy() end
            storage.hatches[uid] = nil
        end
    end
end

-- ─── Registration ────────────────────────────────────────────────────────────

local function register(entity)
    local rate = get_rate(entity.force)
    storage.hatches[entity.unit_number] = {
        entity    = entity,
        proxy     = spawn_proxy(entity),
        budget    = rate or 0,
        detached  = false,
        inserters = {},
        next_scan = 0,
    }
end

local function unregister(entity)
    local data = storage.hatches[entity.unit_number]
    if data and data.proxy and data.proxy.valid then data.proxy.destroy() end
    storage.hatches[entity.unit_number] = nil
end

-- ─── Build validation ────────────────────────────────────────────────────────

-- on_pre_build fires BEFORE the entity is created, giving us the chance to
-- show the "can't build" sound and flying text exactly where the cursor is.
function M.on_pre_build(event)
    local player = game.get_player(event.player_index)
    if not player then return end
    local cursor = player.cursor_stack
    if not (cursor and cursor.valid_for_read) then return end
    if cursor.name ~= "cargo-hatch" then return end

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
        local player = game.get_player(event.player_index)
        if player then
            player.insert({ name = item_name, count = 1 })
            return
        end
    end
    surface.spill_item_stack({
        position                      = pos,
        stack                         = { name = item_name, count = 1 },
        enable_looted                 = false,
        allow_belts                   = false,
        use_start_position_on_failure = true,
    })
end

-- ─── Build / remove ──────────────────────────────────────────────────────────

function M.on_built(event)
    local entity = event.entity or event.created_entity
    if not entity or entity.name ~= "cargo-hatch" then return end

    local surface = entity.surface
    if surface.platform then
        local pos = entity.position

        local hub = get_hub(surface)
        if hub then
            local range = get_range(entity.force)
            if tile_distance(pos, hub.position) > range then
                entity.destroy({ raise_destroy = false })
                refund_hatch(event, surface, pos, "cargo-hatch")
                return
            end
        end

        local limit = get_limit(entity.force)
        local count = get_platform_hatch_count(surface)
        if count > limit then
            entity.destroy({ raise_destroy = false })
            refund_hatch(event, surface, pos, "cargo-hatch")
            return
        end
    end

    register(entity)
end

function M.on_removed(event)
    local entity = event.entity
    if not entity or entity.name ~= "cargo-hatch" then return end
    unregister(entity)
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
    elseif name == "the-reef-cargo-hatch-throughput" then
        storage.cargo_hatch_throughput = storage.cargo_hatch_throughput or {}
        storage.cargo_hatch_throughput[fi] =
            math.min((storage.cargo_hatch_throughput[fi] or 0) + 1, MAX_THROUGHPUT_LEVEL)
    end
end

-- ─── Configuration changed ───────────────────────────────────────────────────

-- Prunes hatch records whose entities did not survive a mod update (the old
-- container-based basic hatch and the advanced hatch both died in the
-- unification), drops the old design's storage tables, and self-heals
-- proxies for surviving hatches.
function M.on_configuration_changed()
    storage.hatch_gui         = nil   -- old basic-hatch GUI tracking
    storage.adv_hatch_proxies = nil   -- old advanced-hatch proxy registry
    storage.cargo_hatch_throughput = storage.cargo_hatch_throughput or {}
    storage.hatches = storage.hatches or {}

    for uid, data in pairs(storage.hatches) do
        if not (data.entity and data.entity.valid) then
            if data.proxy and data.proxy.valid then data.proxy.destroy() end
            storage.hatches[uid] = nil
        else
            if not (data.proxy and data.proxy.valid) then
                data.proxy = spawn_proxy(data.entity)
            end
            data.budget    = data.budget or (get_rate(data.entity.force) or 0)
            data.detached  = data.detached or false
            data.inserters = data.inserters or {}
            data.next_scan = data.next_scan or 0
        end
    end
end

return M
