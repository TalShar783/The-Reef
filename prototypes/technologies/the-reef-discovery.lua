-- Unlocks travel to The Reef.
-- Gated behind fulgora-visitation so the player has already used Recyclers
-- and understands the scrap-processing loop before arriving.

data:extend({
  {
    type    = "technology",
    name    = "the-reef-discovery",
    icon    = "__space-age__/graphics/icons/shattered-planet.png",
    icon_size = 64,
    prerequisites = { "fulgora-visitation" },
    unit = {
      count = 500,
      ingredients = {
        { "automation-science-pack",  1 },
        { "logistic-science-pack",    1 },
        { "chemical-science-pack",    1 },
        { "space-science-pack",       1 },
        { "electromagnetic-science-pack", 1 },
      },
      time = 60,
    },
    effects = {
      {
        type           = "unlock-space-location",
        space_location = "the-reef",
      },
    },
    order = "e[the-reef]",
  },
})
