-- Fluid PMR — scripted fluid routing and production.
--
-- In Factorio 2.x, entity.fluidbox was removed from LuaEntity.
-- Fluid box access is now via explicit methods:
--   entity.get_fluid(index)            → Fluid? {name, amount, temperature}
--   entity.set_fluid(fluid, index)     → fluid first, index second
--   entity.clear_fluid(index)          → empty a box
--   entity.get_fluid_capacity(index)   → max capacity of box N
--   entity.add_fluid(fluid, index)     → add to existing contents
--   entity.remove_fluid(amount, index) → remove N units from box N
--
-- All fluid boxes use production_type="input" (required by 2.x for crafting
-- machines). Native crafting is blocked by pmr-void-fluid in all display
-- recipes — never producible, so the crafter can never satisfy all ingredients.
--
-- Fluid box indices (must match prototype definition order in entities.lua):
local BOX_STAGING = 1   -- external input, left pipe connection
local BOX_IRON    = 2   -- molten-iron internal tank
local BOX_COPPER  = 3   -- molten-copper internal tank

local SYNC_INTERVAL   = 6     -- ticks between sync calls
local CRAFT_TICKS     = 180   -- ticks per production cycle (~3 seconds at 60 UPS)
local DRAIN_PER_CRAFT = 10    -- fluid units consumed per output item

-- Display recipes set on entity for ghost + circuit predicted-output signal.
local RECIPE_IRON   = "fluid-pmr-iron-plate"
local RECIPE_COPPER = "fluid-pmr-copper-plate"

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
    }
    entity.set_recipe(RECIPE_IRON)
end

function M.on_removed(event)
    local entity = event.entity
    if not entity or entity.name ~= "fluid-pmr" then return end
    storage.fluid_pmrs = storage.fluid_pmrs or {}
    storage.fluid_pmrs[entity.unit_number] = nil
end

-- ─── Production ──────────────────────────────────────────────────────────────

local function route_staging(entity)
    local staging = entity.get_fluid(BOX_STAGING)
    if not staging or staging.amount <= 0 then return end

    local target_box = nil
    if staging.name == "molten-iron" then
        target_box = BOX_IRON
    elseif staging.name == "molten-copper" then
        target_box = BOX_COPPER
    end

    if not target_box then return end  -- unrecognised fluid; leave in staging

    local capacity = entity.get_fluid_capacity(target_box)
    local current  = entity.get_fluid(target_box)
    local current_amount = current and current.amount or 0
    local space    = capacity - current_amount
    if space <= 0 then return end

    local transfer = math.min(staging.amount, space)
    entity.add_fluid({ name = staging.name, amount = transfer }, target_box)
    entity.remove_fluid(transfer, BOX_STAGING)
end

local function sync(data)
    local entity = data.entity
    if not entity.valid then return false end

    route_staging(entity)

    local iron_box   = entity.get_fluid(BOX_IRON)
    local copper_box = entity.get_fluid(BOX_COPPER)
    local iron_amt   = iron_box   and iron_box.amount   or 0
    local copper_amt = copper_box and copper_box.amount or 0
    local total      = iron_amt + copper_amt

    -- Update predicted-output recipe for ghost + circuit signal.
    local dominant_recipe = (iron_amt >= copper_amt) and RECIPE_IRON or RECIPE_COPPER
    local current_recipe  = entity.get_recipe()
    local current_name    = current_recipe and current_recipe.name
    if current_name ~= dominant_recipe then
        entity.set_recipe(dominant_recipe)
    end

    if total <= 0 then return true end

    -- Advance production progress.
    data.progress = data.progress + (SYNC_INTERVAL / CRAFT_TICKS)

    -- Keep visual bar below 1.0 — we own the completion event, not the native
    -- crafter. (Native crafter is permanently blocked by pmr-void-fluid.)
    entity.crafting_progress = math.min(data.progress, 0.99)

    if data.progress >= 1.0 then
        local output_item, drain_box, drain_amt
        if iron_amt >= copper_amt and iron_amt >= DRAIN_PER_CRAFT then
            output_item = "iron-plate"
            drain_box   = BOX_IRON
            drain_amt   = DRAIN_PER_CRAFT
        elseif copper_amt > iron_amt and copper_amt >= DRAIN_PER_CRAFT then
            output_item = "copper-plate"
            drain_box   = BOX_COPPER
            drain_amt   = DRAIN_PER_CRAFT
        end

        if output_item then
            local inv = entity.get_inventory(defines.inventory.crafter_output)
            if inv then inv.insert({ name = output_item, count = 1 }) end
            entity.remove_fluid(drain_amt, drain_box)
        end

        data.progress = 0
        entity.crafting_progress = 0
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
