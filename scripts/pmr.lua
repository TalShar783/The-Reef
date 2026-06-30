-- Basic PMR belt I/O — on-tick item transfer.
--
-- loader-1x1 geometry (belt_distance hardcoded to 0) means a loader must sit
-- ON the belt tile and reach to an adjacent container; it cannot sit on the PMR
-- tile and reach out to a belt. To get zero-visible-junction belt I/O the
-- approach is on-tick scripting: each sync interval, pull items from the belt
-- on the south tile into the PMR's input inventory, and push items from the
-- PMR's output inventory onto the belt on the north tile.
--
-- Fixed south-in/north-out for now. Rotation deferred until PMR has a
-- rotatable sprite.

local M = {}

local SYNC_INTERVAL = 6   -- ticks between transfers (~10/sec, matches fast inserter)

local SOUTH = { 0,  1 }
local NORTH = { 0, -1 }

-- ─── Storage ─────────────────────────────────────────────────────────────────

function M.on_init()
    storage.pmrs = storage.pmrs or {}   -- unit_number -> LuaEntity
end

-- ─── Registration ────────────────────────────────────────────────────────────

function M.on_built(event)
    local entity = event.entity or event.created_entity
    if not entity or entity.name ~= "basic-pmr" then return end
    storage.pmrs = storage.pmrs or {}
    storage.pmrs[entity.unit_number] = entity
end

function M.on_removed(event)
    local entity = event.entity
    if not entity or entity.name ~= "basic-pmr" then return end
    storage.pmrs = storage.pmrs or {}
    storage.pmrs[entity.unit_number] = nil
end

-- ─── Belt helpers ─────────────────────────────────────────────────────────────

-- Returns the transport-belt at the given tile offset only if it faces the
-- required direction. Underground belts, splitters, cross-belts, and any
-- non-belt entity at that tile are all excluded.
local function adjacent_belt(entity, offset, required_direction)
    local pos = entity.position
    local area = {
        { pos.x + offset[1] - 0.5, pos.y + offset[2] - 0.5 },
        { pos.x + offset[1] + 0.5, pos.y + offset[2] + 0.5 },
    }
    local belt = entity.surface.find_entities_filtered({ area = area, type = "transport-belt" })[1]
    if not belt or belt.direction ~= required_direction then return nil end
    return belt
end

-- ─── Tick ────────────────────────────────────────────────────────────────────

local function sync(entity)
    if not entity.valid then return false end

    local inv_in  = entity.get_inventory(defines.inventory.crafter_input)
    local inv_out = entity.get_inventory(defines.inventory.crafter_output)

    -- South belt → PMR input: belt must face north (flowing into the PMR).
    -- get_contents() returns ItemWithQualityCount[] in 2.x — use ipairs.
    local south_belt = adjacent_belt(entity, SOUTH, defines.direction.north)
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
    local north_belt = adjacent_belt(entity, NORTH, defines.direction.north)
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

function M.on_tick(event)
    if event.tick % SYNC_INTERVAL ~= 0 then return end
    storage.pmrs = storage.pmrs or {}
    for uid, entity in pairs(storage.pmrs) do
        if not sync(entity) then
            storage.pmrs[uid] = nil
        end
    end
end

return M
