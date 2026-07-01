-- Fluid PMR technology: unlocks the multi-fluid storage facility. Gated
-- behind Reef discovery, same tier as the basic PMR.

data:extend({
  {
    type    = "technology",
    name    = "the-reef-fluid-pmr",
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
      { type = "unlock-recipe", recipe = "fluid-pmr" },
    },
  },
})
