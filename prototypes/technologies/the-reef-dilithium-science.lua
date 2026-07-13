-- Unlocks the Dilithium Science Pack recipe.
-- This gates the entire Dilithium Era — everything beyond basic-pmr
-- requires dilithium science packs to research.

data:extend({
  {
    type      = "technology",
    name      = "the-reef-dilithium-science",
    icon      = "__space-age__/graphics/icons/promethium-science-pack.png",
    icon_size = 64,
    prerequisites = { "the-reef-basic-pmr" },
    unit = {
      count = 500,
      ingredients = {
        { "automation-science-pack",       1 },
        { "logistic-science-pack",         1 },
        { "chemical-science-pack",         1 },
        { "space-science-pack",            1 },
        { "electromagnetic-science-pack",  1 },
      },
      time = 60,
    },
    effects = {
      { type = "unlock-recipe", recipe = "dilithium-science-pack" },
    },
  },
})
