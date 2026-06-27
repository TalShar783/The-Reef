-- Crusher recipe: Starship Scrap Chunk → raw materials + rare Dilithium Crystal.
-- Follows the vanilla asteroid-crushing pattern:
--   category = "crushing", auto_recycle = false, allow_productivity = true
--   A fraction of chunks survive crushing (probability < 1 on the chunk result).
--
-- Recycler recipe: Starship Scrap → varied raw outputs.
--   category = "recycling-or-hand-crafting" matches the Fulgoran scrap pattern.

data:extend({
  -- Crushing ---------------------------------------------------------------
  {
    type     = "recipe",
    name     = "starship-scrap-crushing",
    icon     = "__space-age__/graphics/icons/metallic-asteroid-chunk.png",
    icon_size = 64,
    category = "crushing",
    subgroup = "space-crushing",
    order    = "e-a",
    enabled  = false,
    auto_recycle = false,
    allow_productivity  = true,
    allow_decomposition = false,
    energy_required = 2,
    ingredients = {
      { type = "item", name = "starship-scrap-chunk", amount = 1 },
    },
    results = {
      { type = "item", name = "iron-plate",      amount = 5 },
      { type = "item", name = "copper-plate",    amount = 3 },
      { type = "item", name = "steel-plate",     amount = 1 },
      -- Chunk survives intact with 15% probability (reprocess it)
      { type = "item", name = "starship-scrap-chunk", amount = 1, probability = 0.15 },
      -- Dilithium Crystal: rare find deep in the ship debris
      { type = "item", name = "dilithium-crystal", amount = 1, probability = 0.03 },
    },
  },

  -- Recycling --------------------------------------------------------------
  -- Takes processed Starship Scrap and extracts misc components.
  -- Lower yields than crushing a raw chunk — reward for the extra processing step.
  {
    type     = "recipe",
    name     = "starship-scrap-recycling",
    icon     = "__space-age__/graphics/icons/metallic-asteroid-chunk.png",
    icon_size = 64,
    category = "recycling-or-hand-crafting",
    subgroup = "space-crushing",
    order    = "e-b",
    enabled  = false,
    auto_recycle = false,
    energy_required = 0.5,
    ingredients = {
      { type = "item", name = "starship-scrap", amount = 1 },
    },
    results = {
      { type = "item", name = "iron-plate",       amount = 1, probability = 0.30, show_details_in_recipe_tooltip = false },
      { type = "item", name = "copper-plate",     amount = 1, probability = 0.20, show_details_in_recipe_tooltip = false },
      { type = "item", name = "steel-plate",      amount = 1, probability = 0.08, show_details_in_recipe_tooltip = false },
      { type = "item", name = "advanced-circuit", amount = 1, probability = 0.03, show_details_in_recipe_tooltip = false },
      { type = "item", name = "dilithium-crystal",amount = 1, probability = 0.01, show_details_in_recipe_tooltip = false },
    },
  },
})
