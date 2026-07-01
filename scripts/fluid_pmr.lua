-- Fluid PMR — scripted fluid voiding, virtual-tank accumulation, and item output.
--
-- Entity base: storage-tank (not assembling-machine). Storage tanks accept any
-- fluid without recipe constraints; the script reads fluid out each tick via
-- entity.get_fluid(1) / entity.remove_fluid(1, amount).
--
-- Virtual tanks: fluid accumulation tracked in data.fluids (plain numbers).
-- Backpressure: when virtual tank is full, script stops voiding → real tank
-- fills → pipe network backs up naturally.
--
-- Item output: mining-drill style, onto the east-adjacent tile (position+{2,0}).
-- Output tile is checked FIRST; if anything blocks the output (full belt, full
-- container, ground item already present), nothing is consumed and the machine
-- simply waits until the tile clears.

local BOX_INPUT       = 1
local DRAIN_INTERVAL  = 6    -- ticks between void pulses
local PRODUCE_INTERVAL = 30  -- ticks between production attempts (0.5 s at 60 UPS)
local DRAIN_PER_CRAFT = 10   -- virtual fluid units consumed per iron plate
local MAX_INTERNAL    = 500  -- virtual tank capacity per fluid type

local M = {}

-- ─── Storage ─────────────────────────────────────────────────────────────────

function M.on_init()
    storage.fluid_pmrs = storage.fluid_pmrs or {}
end

-- ─── Registration ────────────────────────────────────────────────────────────

function M.on_built(event)
    local entity = event.entity or event.created_entity
    if not entity or entity.name ~= "fluid-pmr" then return end
    storage.fluid_pmrs = storage.fluid_pmrs or {}
    storage.fluid_pmrs[entity.unit_number] = {
        entity = entity,
        fluids = { iron = 0, copper = 0 },
    }
end

function M.on_removed(event)
    local entity = event.entity
    if not entity or entity.name ~= "fluid-pmr" then return end
    storage.fluid_pmrs = storage.fluid_pmrs or {}
    storage.fluid_pmrs[entity.unit_number] = nil
end

-- ─── Output tile ─────────────────────────────────────────────────────────────

-- East-adjacent tile center for a 3×3 entity with west pipe input.
local function output_pos(entity)
    local p = entity.position
    return { x = p.x + 2, y = p.y }
end

-- ─── Output availability check ───────────────────────────────────────────────

-- Returns true if the output tile can accept one item of item_name RIGHT NOW.
-- Checks belts first, then containers, then ground.
-- If ANY of those entity types is present and full, returns false immediately.
local function can_output(surface, pos, item_name)
    -- Transport belt at output tile?
    local belt = surface.find_entity("transport-belt", pos)
    if belt then
        local left  = belt.get_transport_line(defines.transport_line.left_line)
        local right = belt.get_transport_line(defines.transport_line.right_line)
        return left.can_insert_at_back() or right.can_insert_at_back()
    end

    -- Container (chest, logistic chest) at output tile?
    local area = { { pos.x - 0.5, pos.y - 0.5 }, { pos.x + 0.5, pos.y + 0.5 } }
    local containers = surface.find_entities_filtered({
        area = area,
        type = { "container", "logistic-container" },
    })
    if #containers > 0 then
        for _, cont in ipairs(containers) do
            local inv = cont.get_inventory(defines.inventory.chest)
            if inv and inv.can_insert({ name = item_name, count = 1 }) then
                return true
            end
        end
        return false  -- container(s) present but all full
    end

    -- Ground: fail if any item-entity is already on this tile.
    local ground = surface.find_entities_filtered({ area = area, type = "item-entity" })
    return #ground == 0
end

-- Place one item at the output tile. Mirrors the logic in can_output.
local function do_output(surface, pos, item_name)
    local belt = surface.find_entity("transport-belt", pos)
    if belt then
        local left  = belt.get_transport_line(defines.transport_line.left_line)
        local right = belt.get_transport_line(defines.transport_line.right_line)
        if left.can_insert_at_back() then
            left.insert_at_back({ name = item_name, count = 1 })
            return
        end
        if right.can_insert_at_back() then
            right.insert_at_back({ name = item_name, count = 1 })
            return
        end
        return  -- belt full (should not reach here — can_output returned true)
    end

    local area = { { pos.x - 0.5, pos.y - 0.5 }, { pos.x + 0.5, pos.y + 0.5 } }
    local containers = surface.find_entities_filtered({
        area = area,
        type = { "container", "logistic-container" },
    })
    if #containers > 0 then
        for _, cont in ipairs(containers) do
            local inv = cont.get_inventory(defines.inventory.chest)
            if inv and inv.can_insert({ name = item_name, count = 1 }) then
                inv.insert({ name = item_name, count = 1 })
                return
            end
        end
        return  -- all full (should not reach here — can_output returned true)
    end

    -- Drop on ground at the exact tile, no belt redirect.
    surface.spill_item_stack({
        position = pos,
        stack = { name = item_name, count = 1 },
        max_radius = 0,
        use_start_position_on_failure = true,
        allow_belts = false,
    })
end

-- ─── Fluid voiding ───────────────────────────────────────────────────────────

-- Read fluid from the real tank, remove it, and credit the virtual tank.
-- If the virtual tank is full, leave fluid in the real tank (backpressure).
local function drain_tank(entity, fluids)
    local fluid = entity.get_fluid(BOX_INPUT)
    if not fluid or fluid.amount <= 0 then return end

    local target
    if     fluid.name == "molten-iron"   then target = "iron"
    elseif fluid.name == "molten-copper" then target = "copper" end
    if not target then return end  -- unrecognised fluid; backpressure

    local space = MAX_INTERNAL - fluids[target]
    if space <= 0 then return end  -- virtual tank full; backpressure

    local take = math.min(fluid.amount, space)
    fluids[target] = fluids[target] + take
    entity.remove_fluid(BOX_INPUT, take)
end

-- ─── Production ──────────────────────────────────────────────────────────────

-- Every PRODUCE_INTERVAL ticks: if virtual iron tank ≥ DRAIN_PER_CRAFT AND
-- the output tile can accept an item, consume fluid and drop the item.
local function try_produce(entity, fluids)
    if fluids.iron < DRAIN_PER_CRAFT then return end

    local pos = output_pos(entity)
    if not can_output(entity.surface, pos, "iron-plate") then return end

    -- Output clear and sufficient fluid available — consume and produce.
    fluids.iron = fluids.iron - DRAIN_PER_CRAFT
    do_output(entity.surface, pos, "iron-plate")
end

-- ─── Tick ────────────────────────────────────────────────────────────────────

function M.on_tick(event)
    storage.fluid_pmrs = storage.fluid_pmrs or {}
    local tick = event.tick
    local do_drain   = (tick % DRAIN_INTERVAL   == 0)
    local do_produce = (tick % PRODUCE_INTERVAL == 0)

    if not do_drain and not do_produce then return end

    for uid, data in pairs(storage.fluid_pmrs) do
        local entity = data.entity
        if not entity.valid then
            storage.fluid_pmrs[uid] = nil
        else
            if do_drain   then drain_tank(entity, data.fluids) end
            if do_produce then try_produce(entity, data.fluids) end
        end
    end
end

return M
