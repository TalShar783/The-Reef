-- Cargo Hatch technology: branches from Dilithium Science alongside the reactor.
-- Costs dilithium science packs to reflect Reef-era logistics research.

data:extend({
  {
    type      = "technology",
    name      = "the-reef-cargo-hatch",
    icon      = "__base__/graphics/icons/iron-chest.png",
    icon_size = 64,
    prerequisites = { "the-reef-dilithium-science" },
    unit = {
      count = 200,
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
      { type = "unlock-recipe", recipe = "cargo-hatch" },
    },
  },
})
