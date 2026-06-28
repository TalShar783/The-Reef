-- Unlocks the Dilithium Reactor T1.
-- Gated behind dilithium science, and costs dilithium science packs to research.
-- Phase 5 will add water requirement and direct-electricity scripting.

data:extend({
  {
    type      = "technology",
    name      = "the-reef-dilithium-reactor-1",
    icon      = "__space-age__/graphics/icons/nuclear-reactor.png",
    icon_size = 64,
    prerequisites = { "the-reef-dilithium-science" },
    unit = {
      count = 300,
      ingredients = {
        { "automation-science-pack",       1 },
        { "logistic-science-pack",         1 },
        { "chemical-science-pack",         1 },
        { "space-science-pack",            1 },
        { "electromagnetic-science-pack",  1 },
        { "dilithium-science-pack",        1 },
      },
      time = 60,
    },
    effects = {
      { type = "unlock-recipe", recipe = "dilithium-reactor-1" },
      { type = "unlock-recipe", recipe = "dilithium-fuel-cell" },
    },
  },
})
