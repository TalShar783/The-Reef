-- Fluid PMR — scripted fluid routing and production.
--
-- All fluid boxes use production_type="none" so the native crafter never
-- matches them as recipe ingredients and never fires on its own.
-- This script owns the full production cycle:
--   1. Route staging box → matching internal tank each SYNC_INTERVAL.
--   2. Advance progress while any internal fluid is present.
--   3. On completion: evaluate dominant fluid, drain 10 units, insert 1 plate.
--   4. Set active recipe to the predicted output for ghost/circuit signal.
--
-- Fluid box indices (must match prototype definition order in entities.lua):
local BOX_STAGING = 1   -- external input, left pipe connection
local BOX_IRON    = 2   -- molten-iron internal tank
local BOX_COPPER  = 3   -- molten-copper internal tank

local SYNC_INTERVAL  = 6     -- ticks between sync calls
local CRAFT_TICKS    = 180   -- ticks per production cycle (~3 seconds at 60 UPS)
local DRAIN_PER_CRAFT = 10   -- fluid units consumed per output item

-- Display recipes (set on entity for ghost + circuit signal output).
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
    -- Default ghost to iron output on placement.
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
    local staging = entity.fluidbox[BOX_STAGING]
    if not staging or staging.amount <= 0 then return end

    local target_box = nil
    if staging.name == "molten-iron" then
        target_box = BOX_IRON
    elseif staging.name == "molten-copper" then
        target_box = BOX_COPPER
    end

    if not target_box then return end  -- unrecognised fluid; leave in staging

    local current = entity.fluidbox[target_box]
    local current_amount = current and current.amount or 0

    -- Capacity is defined in the prototype; read it at runtime.
    local capacity = entity.fluidbox.get_capacity(target_box)
    local space = capacity - current_amount
    if space <= 0 then return end

    local transfer = math.min(staging.amount, space)
    entity.fluidbox[target_box] = { name = staging.name, amount = current_amount + transfer }
    local remaining = staging.amount - transfer
    if remaining <= 0 then
        entity.fluidbox[BOX_STAGING] = nil
    else
        entity.fluidbox[BOX_STAGING] = { name = staging.name, amount = remaining }
    end
end

local function sync(data)
    local entity = data.entity
    if not entity.valid then return false end

    route_staging(entity)

    local iron_box   = entity.fluidbox[BOX_IRON]
    local copper_box = entity.fluidbox[BOX_COPPER]
    local iron_amt   = iron_box   and iron_box.amount   or 0
    local copper_amt = copper_box and copper_box.amount or 0
    local total      = iron_amt + copper_amt

    -- Update predicted-output recipe for ghost + circuit signal.
    local dominant_recipe = (iron_amt >= copper_amt) and RECIPE_IRON or RECIPE_COPPER
    if entity.get_recipe() ~= dominant_recipe then
        entity.set_recipe(dominant_recipe)
    end

    if total <= 0 then
        -- No fluid: stall progress, keep crafting_progress visual where it is.
        return true
    end

    -- Advance production progress.
    data.progress = data.progress + (SYNC_INTERVAL / CRAFT_TICKS)

    -- Clamp visual bar below 1.0 — we control the completion event, not the
    -- native crafter. The native crafter never fires because production_type="none"
    -- means it sees no recipe ingredients regardless of what's in the fluid boxes.
    entity.crafting_progress = math.min(data.progress, 0.99)

    if data.progress >= 1.0 then
        -- Determine output.
        local output_item, drain_box, drain_amt
        if iron_amt >= copper_amt and iron_amt >= DRAIN_PER_CRAFT then
            output_item = "iron-plate"
            drain_box   = BOX_IRON
            drain_amt   = iron_amt - DRAIN_PER_CRAFT
        elseif copper_amt > iron_amt and copper_amt >= DRAIN_PER_CRAFT then
            output_item = "copper-plate"
            drain_box   = BOX_COPPER
            drain_amt   = copper_amt - DRAIN_PER_CRAFT
        end

        if output_item then
            -- Insert into output inventory.
            local inv = entity.get_inventory(defines.inventory.crafter_output)
            if inv then inv.insert({ name = output_item, count = 1 }) end

            -- Drain the consumed fluid.
            if drain_amt <= 0 then
                entity.fluidbox[drain_box] = nil
            else
                local box = entity.fluidbox[drain_box]
                entity.fluidbox[drain_box] = { name = box.name, amount = drain_amt }
            end
        end
        -- Reset regardless of whether output fired (avoids stall when fluid runs low).
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
