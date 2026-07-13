-- Basic PMR technology: unlocks the Probabilistic Matter Recombinator and its
-- initial recipe set. Gated behind Reef discovery.
-- Science pack cost uses EM packs (Fulgora) as the appropriate post-Fulgora tier.

data:extend({
  {
    type    = "technology",
    name    = "the-reef-basic-pmr",
    icon    = "__space-age__/graphics/icons/shattered-planet.png",
    icon_size = 64,
    prerequisites = { "the-reef-discovery" },
    unit = {
      count = 1000,
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
      { type = "unlock-recipe", recipe = "basic-pmr" },
      { type = "unlock-recipe", recipe = "pmr-green-circuits" },
      { type = "unlock-recipe", recipe = "pmr-grenades" },
      { type = "unlock-recipe", recipe = "pmr-piercing-magazines" },
      { type = "unlock-recipe", recipe = "dilithium-fuel-cell" },
    },
  },
})
