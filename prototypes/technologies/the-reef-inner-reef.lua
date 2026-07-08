-- Unlocks travel to The Inner Reef.
-- Gated behind Dilithium Era, meant as the second stage of the mod.

data:extend({
  {
    type    = "technology",
    name    = "the-reef-inner-reef",
    icon    = "__space-age__/graphics/icons/shattered-planet.png",
    icon_size = 64,
    prerequisites = { "the-reef-dilithium-science" },
    unit = {
      count = 500,
      ingredients = {
        { "automation-science-pack",  1 },
        { "logistic-science-pack",    1 },
        { "chemical-science-pack",    1 },
        { "space-science-pack",       1 },
        { "electromagnetic-science-pack", 1 },
        { "dilithium-science-pack",   1 },
      },
      time = 60,
    },
    effects = {
      {
        type           = "unlock-space-location",
        space_location = "the-inner-reef",
      },
    },
    order = "e[the-reef]",
  },
})
