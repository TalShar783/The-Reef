-- Fluid PMR — scripted fluid routing and production.
--
-- In Factorio 2.x, entity.fluidbox was removed from LuaEntity.
-- Fluid box access is now via explicit methods (index is ALWAYS first):
--   entity.get_fluid(index)            → Fluid? {name, amount, temperature}
--   entity.set_fluid(index, fluid)     → index first, fluid second
--   entity.clear_fluid(index)          → empty a box
--   entity.get_fluid_capacity(index)   → max capacity of box N
--   entity.add_fluid(index, fluid)     → index first, fluid second
--   entity.remove_fluid(index, amount) → index first, amount second
--
-- Sealed fluid boxes (pipe_connections={}) silently discard fluid passed via
-- add_fluid — confirmed in testing. Internal iron/copper accumulation is
-- tracked in data.fluids (Lua table), not in entity fluid boxes.
--
-- Only one physical fluid box on the entity:
local BOX_STAGING = 1   -- external input, left pipe connection

local SYNC_INTERVAL   = 6      -- ticks between sync calls
local CRAFT_TICKS     = 180    -- ticks per production cycle (~3 seconds at 60 UPS)
local DRAIN_PER_CRAFT = 10     -- fluid units consumed per output item
local MAX_INTERNAL    = 500    -- script-tracked capacity per fluid type

local RECIPE = "fluid-pmr-process"

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
        entity   = entity,
        progress = 0,
        fluids   = { iron = 0, copper = 0 },
    }
    entity.set_recipe(RECIPE)
end

function M.on_removed(event)
    local entity = event.entity
    if not entity or entity.name ~= "fluid-pmr" then return end
    storage.fluid_pmrs = storage.fluid_pmrs or {}
    storage.fluid_pmrs[entity.unit_number] = nil
end

-- ─── Production ──────────────────────────────────────────────────────────────

local function route_staging(entity, fluids)
    local staging = entity.get_fluid(BOX_STAGING)
    if not staging or staging.amount <= 0 then return end

    local target = nil
    if staging.name == "molten-iron" then
        target = "iron"
    elseif staging.name == "molten-copper" then
        target = "copper"
    end

    if not target then return end  -- unrecognised fluid; leave in staging

    local space    = MAX_INTERNAL - fluids[target]
    if space <= 0 then return end

    local transfer = math.min(staging.amount, space)
    fluids[target] = fluids[target] + transfer
    entity.remove_fluid(BOX_STAGING, transfer)
end

local function sync(data)
    local entity = data.entity
    if not entity.valid then return false end

    -- Respect machine state (circuit disable, power loss, etc.)
    if not entity.active then
        data.progress = 0
        entity.crafting_progress = 0
        return true
    end

    route_staging(entity, data.fluids)

    local iron_amt   = data.fluids.iron
    local copper_amt = data.fluids.copper
    local total      = iron_amt + copper_amt

    if total <= 0 then return true end

    -- Advance progress only while below completion threshold.
    -- Once >= 1.0 we hold at 0.99 until the output clears.
    if data.progress < 1.0 then
        data.progress = data.progress + (SYNC_INTERVAL / CRAFT_TICKS)
    end
    entity.crafting_progress = math.min(data.progress, 0.99)

    if data.progress >= 1.0 then
        local output_item, drain_key

        if iron_amt >= copper_amt and iron_amt >= DRAIN_PER_CRAFT then
            output_item = "iron-plate"
            drain_key   = "iron"
        elseif copper_amt > iron_amt and copper_amt >= DRAIN_PER_CRAFT then
            output_item = "copper-plate"
            drain_key   = "copper"
        end

        if output_item then
            local inv = entity.get_inventory(defines.inventory.crafter_output)
            if inv and inv.can_insert({ name = output_item, count = 1 }) then
                inv.insert({ name = output_item, count = 1 })
                data.fluids[drain_key] = data.fluids[drain_key] - DRAIN_PER_CRAFT
                data.progress = 0
                entity.crafting_progress = 0
            end
            -- Output full: hold at 0.99 and retry next sync.
        else
            -- Not enough fluid in the dominant tank; reset.
            data.progress = 0
            entity.crafting_progress = 0
        end
    end

    return true
end

-- ─── Tick ────────────────────────────────────────────────────────────────────

function M.on_tick(event)
    if event.tick % SYNC_INTERVAL ~= 0 then return end
    storage.fluid_pmrs = storage.fluid_pmrs or {}
    for uid, data in pairs(storage.fluid_pmrs) do
        if not sync(data) then
            storage.fluid_pmrs[uid] = nil
        end
    end
end

return M
