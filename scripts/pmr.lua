-- Basic PMR belt I/O — on-tick item transfer.
--
-- loader-1x1 geometry (belt_distance hardcoded to 0) means a loader must sit
-- ON the belt tile and reach to an adjacent container; it cannot sit on the PMR
-- tile and reach out to a belt. To get zero-visible-junction belt I/O the
-- approach is on-tick scripting: each sync interval, pull items from the belt
-- on the south tile into the PMR's input inventory, and push items from the
-- PMR's output inventory onto the belt on the north tile.
--
-- Adjacent belts are cached per PMR instead of re-scanned every sync: a
-- cached belt is trusted while it stays valid and correctly oriented, and
-- missing/rotated belts are re-scanned at most once per BELT_RESCAN_TICKS —
-- so a newly placed belt starts flowing within ~2 seconds.
--
-- Fixed south-in/north-out for now. Rotation deferred until PMR has a
-- rotatable sprite.

local M = {}

local SYNC_INTERVAL     = 6     -- ticks between transfers (~10/sec, matches fast inserter)
local BELT_RESCAN_TICKS = 120   -- ticks between belt lookups when none is cached

local SOUTH = { 0,  1 }
local NORTH = { 0, -1 }

-- ─── Storage ─────────────────────────────────────────────────────────────────
-- storage.pmrs: unit_number -> { entity, south = cache, north = cache }
-- cache = { belt = LuaEntity?, next_scan = tick }

function M.on_init()
    storage.pmrs = storage.pmrs or {}
end

-- ─── Registration ────────────────────────────────────────────────────────────

local function new_record(entity)
    return {
        entity = entity,
        south  = { belt = nil, next_scan = 0 },
        north  = { belt = nil, next_scan = 0 },
    }
end

function M.on_built(event)
    local entity = event.entity or event.created_entity
    if not entity or entity.name ~= "basic-pmr" then return end
    storage.pmrs = storage.pmrs or {}
    storage.pmrs[entity.unit_number] = new_record(entity)
end

function M.on_removed(event)
    local entity = event.entity
    if not entity or entity.name ~= "basic-pmr" then return end
    storage.pmrs = storage.pmrs or {}
    storage.pmrs[entity.unit_number] = nil
end

-- Rebuilds records whose shape predates the belt cache (they were bare
-- LuaEntity values). Detected via object_name — always safe to read on a
-- Factorio object, whereas probing .entity on a LuaEntity would throw.
function M.on_configuration_changed()
    storage.pmrs = storage.pmrs or {}
    for uid, rec in pairs(storage.pmrs) do
        if rec.object_name then   -- old shape: the record IS the entity
            storage.pmrs[uid] = rec.valid and new_record(rec) or nil
        elseif not (rec.entity and rec.entity.valid) then
            storage.pmrs[uid] = nil
        end
    end
end

-- ─── Belt cache ──────────────────────────────────────────────────────────────

-- Returns the transport-belt at the given tile offset only if it faces the
-- required direction. Underground belts, splitters, cross-belts, and any
-- non-belt entity at that tile are all excluded. Cached: trusted while
-- valid and correctly oriented, re-scanned on schedule otherwise.
local function adjacent_belt(entity, cache, offset, required_direction, tick)
    local belt = cache.belt
    if belt and belt.valid and belt.direction == required_direction then
        return belt
    end

    if tick < cache.next_scan then return nil end
    cache.next_scan = tick + BELT_RESCAN_TICKS

    local pos = entity.position
    local area = {
        { pos.x + offset[1] - 0.5, pos.y + offset[2] - 0.5 },
        { pos.x + offset[1] + 0.5, pos.y + offset[2] + 0.5 },
    }
    belt = entity.surface.find_entities_filtered({ area = area, type = "transport-belt" })[1]
    cache.belt = belt
    if belt and belt.direction == required_direction then return belt end
    return nil
end

-- ─── Tick ────────────────────────────────────────────────────────────────────

local function sync(rec, tick)
    local entity = rec.entity
    if not entity.valid then return false end

    local inv_in  = entity.get_inventory(defines.inventory.crafter_input)
    local inv_out = entity.get_inventory(defines.inventory.crafter_output)

    -- South belt → PMR input: belt must face north (flowing into the PMR).
    -- get_contents() returns ItemWithQualityCount[] in 2.x — use ipairs.
    local south_belt = adjacent_belt(entity, rec.south, SOUTH, defines.direction.north, tick)
    if south_belt then
        for lane = 1, 2 do
            local tl = south_belt.get_transport_line(lane)
            for _, item in ipairs(tl.get_contents()) do
                if inv_in.can_insert({ name = item.name, count = 1 }) then
                    local n = inv_in.insert({ name = item.name, count = 1 })
                    if n > 0 then tl.remove_item({ name = item.name, count = 1 }) end
                end
            end
        end
    end

    -- PMR output → north belt: belt must face north (carrying items away from PMR).
    -- insert_at_back(items, belt_stack_size) — items is param 0, size is param 1.
    local north_belt = adjacent_belt(entity, rec.north, NORTH, defines.direction.north, tick)
    if north_belt then
        for i = 1, #inv_out do
            local stack = inv_out[i]
            if stack.valid_for_read then
                for lane = 1, 2 do
                    local tl = north_belt.get_transport_line(lane)
                    if tl.can_insert_at_back() then
                        tl.insert_at_back({ name = stack.name, count = 1 }, 1)
                        inv_out.remove({ name = stack.name, count = 1 })
                        break
                    end
                end
            end
        end
    end

    return true
end

-- Registered via script.on_nth_tick(M.TICK_INTERVAL, ...) in control.lua.
function M.on_nth_tick(event)
    storage.pmrs = storage.pmrs or {}
    for uid, rec in pairs(storage.pmrs) do
        if not sync(rec, event.tick) then
            storage.pmrs[uid] = nil
        end
    end
end
M.TICK_INTERVAL = SYNC_INTERVAL

return M
