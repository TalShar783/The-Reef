-- The Reef entities: machines and structures.

-- PMR crafting category — used by all Basic PMR recipes.
data:extend({
  {
    type = "recipe-category",
    name = "the-reef-pmr",
  },
})

-- Basic PMR (Probabilistic Matter Recombinator)
-- A 1x1 compact machine that converts raw materials directly into finished goods,
-- skipping intermediate production steps. Wrong inputs produce Unstable Isotopes
-- (mechanic deferred to a later phase — pure data for now).
--
-- Visual placeholder: deep copy of assembling-machine-1.
-- Replace with custom 1x1 art before release.
-- Belt I/O mechanic (Loaders or scripting) deferred to a later phase.

local pmr = table.deepcopy(data.raw["assembling-machine"]["assembling-machine-1"])
pmr.name             = "basic-pmr"
pmr.icon             = "__space-age__/graphics/icons/shattered-planet.png"
pmr.icon_size        = 64
pmr.crafting_categories = { "the-reef-pmr" }
pmr.crafting_speed   = 1
pmr.ingredient_count = 4  -- max 4 ingredient types (fuel cell needs 3)
pmr.minable          = { mining_time = 0.5, result = "basic-pmr" }
pmr.fixed_recipe     = nil  -- assembling-machine-1 has no fixed recipe but clear it anyway

data:extend({ pmr })
