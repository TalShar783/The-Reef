-- Cargo Hatch script.
--
-- The hatch is a landing-pad-unloading-bay lookalike (cargo-bay type) plus a
-- hidden proxy-container (cargo-hatch-proxy) on the same tiles that exposes
-- the platform hub's main inventory directly to inserters — native engine
-- passthrough, no per-item scripting and no configuration GUI. The bay
-- itself has allow_unloading = false and inventory_size_bonus = 0, so the
-- proxy is the ONLY item path; connecting the bay to the hub network is a
-- functional requirement (see connection gate below), not an item path.
--
-- Script enforces, per force, all derived live from technology levels
-- (force.technologies[...].level — never event counters, so script-researched
-- and editor-modified levels are always respected):
--   * placement limit per platform (count)
--   * max placement distance from the hub
--   * throughput throttle — a token bucket refilled at R items/sec. When
--     the bucket runs dry, the proxy's target detaches (inserters stall
--     harmlessly) and the hatch shows a red "On cooldown" status until the
--     bucket refills. Whole swings always pass: the budget may go negative,
--     which just lengthens the cooldown. The final throughput research
--     level removes the throttle; passes then reduce to the connection
--     check below.
--
-- COUNTING SCOPE — inserters only. A proxy-container is engine passthrough
-- and fires no transfer events, so items are counted by watching the hands
-- (held_stack) of the inserters whose pickup/drop target is the hatch or
-- its proxy. Anything that is not an inserter is invisible to the throttle:
-- player hand-transfers through the GUI are deliberately uncounted (the
-- throttle governs automation, not the player), and if some future mover
-- (loaders, bots, another mod's entity) gains access to the proxy it will
-- bypass the count — revisit this section if that ever becomes possible.
--
-- CONNECTION GATE — the hatch only functions while its bay is connected to
-- the hub network (entity.status ~= not_connected_to_hub_or_pad). While
-- disconnected the proxy target is detached and no custom_status is set, so
-- the engine's own broken-chain indicator stays visible.

local BASE_LIMIT      = 1
local BASE_RANGE      = 20
local RANGE_PER_LEVEL = 5

local BASE_RATE            = 4    -- items/sec with no throughput research
local RATE_PER_LEVEL       = 4    -- added per throughput research level
local MAX_THROUGHPUT_LEVEL = 10   -- this level removes the throttle

local THROTTLE_INTERVAL       = 5    -- ticks between throttle passes
local INSERTER_RESCAN_TICKS   = 120  -- ticks between adjacent-inserter rescans
local INSERTER_SCAN_RADIUS    = 5    -- tiles around the hatch center (4×4 body + reach)
local WARN_COOLDOWN_TICKS     = 120  -- min ticks between placement warnings per player

local M = {}

-- ─── Storage ─────────────────────────────────────────────────────────────────

function M.on_init()
    storage.hatches    = {}   -- unit_number -> hatch data
    storage.hatch_warn = {}   -- player_index -> tick of last placement warning
end

-- ─── Research-scaled values (read live from technology levels) ───────────────

-- Completed levels of an upgrade technology. For upgrade techs, .level is
-- the next researchable level, so the completed count is level - 1 until
-- the tech is fully researched.
local function tech_level(force, name)
    local tech = force.technologies[name]
    if not tech then return 0 end
    if tech.researched then return tech.level end
    return tech.level - 1
end

local function get_limit(force)
    return BASE_LIMIT + tech_level(force, "the-reef-cargo-hatch-capacity")
end

local function get_range(force)
    return BASE_RANGE + RANGE_PER_LEVEL * tech_level(force, "the-reef-cargo-hatch-range")
end

-- Items/sec budget for the force, or nil when the throttle is researched away.
local function get_rate(force)
    local level = tech_level(force, "the-reef-cargo-hatch-throughput")
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

    -- Connection gate: an unconnected bay is inert. Leave custom_status
    -- clear so the engine's own broken-chain status stays visible.
    if entity.status == defines.entity_status.not_connected_to_hub_or_pad then
        if not data.disconnected then
            data.disconnected = true
            data.proxy.proxy_target_entity = nil
            entity.custom_status = nil
        end
        return true
    elseif data.disconnected then
        data.disconnected = false
        if not data.detached then attach(data) end
    end

    local rate = get_rate(entity.force)
    if not rate then
        -- Throttle researched away: make sure the hatch is live; the pass
        -- reduces to the connection check above.
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
        entity       = entity,
        proxy        = spawn_proxy(entity),
        budget       = rate or 0,
        detached     = false,
        disconnected = false,
        inserters    = {},
        next_scan    = 0,
    }
end

local function unregister(entity)
    local data = storage.hatches[entity.unit_number]
    if data and data.proxy and data.proxy.valid then data.proxy.destroy() end
    storage.hatches[entity.unit_number] = nil
end

-- ─── Build validation ────────────────────────────────────────────────────────

-- Shows the "can't build" sound + flying text, rate-limited per player so
-- drag-building doesn't fire a warning on every tile the cursor crosses.
local function warn(player, tick, position, text)
    storage.hatch_warn = storage.hatch_warn or {}
    local last = storage.hatch_warn[player.index]
    if last and tick - last < WARN_COOLDOWN_TICKS then return end
    storage.hatch_warn[player.index] = tick
    player.play_sound({ path = "utility/cannot_build" })
    player.create_local_flying_text({
        position     = position,
        text         = text,
        color        = { r = 1, g = 0.5, b = 0.5 },
        time_to_live = 120,
    })
end

-- on_pre_build fires BEFORE the entity is created, giving us the chance to
-- show the warning exactly where the cursor is.
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
            warn(player, event.tick, event.position,
                { "cargo-hatch.range-exceeded", math.floor(dist), range })
            return
        end
    end

    local limit = get_limit(player.force)
    local count = get_platform_hatch_count(surface)
    if count >= limit then
        warn(player, event.tick, event.position,
            { "cargo-hatch.limit-reached", count, limit })
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

-- ─── Configuration changed ───────────────────────────────────────────────────

-- Prunes hatch records whose entities did not survive a mod update, drops
-- storage tables from retired designs (research is now read live from
-- technology levels, so the old event-counter tables are dead), and
-- self-heals proxies for surviving hatches.
function M.on_configuration_changed()
    storage.hatch_gui                  = nil   -- container-hatch GUI tracking
    storage.adv_hatch_proxies          = nil   -- pre-unification proxy registry
    storage.cargo_hatch_extra_capacity = nil   -- research event counters,
    storage.cargo_hatch_extra_range    = nil   -- replaced by live tech-level
    storage.cargo_hatch_throughput     = nil   -- reads
    storage.hatch_warn = storage.hatch_warn or {}
    storage.hatches    = storage.hatches or {}

    for uid, data in pairs(storage.hatches) do
        if not (data.entity and data.entity.valid) then
            if data.proxy and data.proxy.valid then data.proxy.destroy() end
            storage.hatches[uid] = nil
        else
            if not (data.proxy and data.proxy.valid) then
                data.proxy = spawn_proxy(data.entity)
            end
            data.budget       = data.budget or 0
            data.detached     = data.detached or false
            data.disconnected = data.disconnected or false
            data.inserters    = data.inserters or {}
            data.next_scan    = data.next_scan or 0
        end
    end
end

return M
