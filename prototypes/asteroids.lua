-- Starship Scrap Chunk entity — the asteroid-chunk that floats in The Reef's
-- approach corridor and is collected by asteroid collectors.
--
-- graphics_set is deep-copied from metallic-asteroid-chunk as a placeholder.
-- Replace with custom scrap art (jagged metal debris look) before release.

data:extend({
  {
    type      = "asteroid-chunk",
    name      = "starship-scrap-chunk",
    icon      = "__space-age__/graphics/icons/metallic-asteroid-chunk.png",
    icon_size = 64,
    subgroup  = "space-material",
    order     = "e[starship-scrap]-a[chunk]",

    graphics_set = table.deepcopy(
      data.raw["asteroid-chunk"]["metallic-asteroid-chunk"].graphics_set
    ),

    minable = {
      mining_time    = 0.2,
      result         = "starship-scrap-chunk",
      mining_particle = "metallic-asteroid-chunk-particle-medium",
    },
  },
})
