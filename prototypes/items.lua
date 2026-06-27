-- Starship Scrap Chunk: the asteroid-chunk item collected by asteroid collectors.
-- stack_size = 1 and weight = 100kg matches the vanilla asteroid-chunk pattern.
-- Icons are placeholders; replace with final art before release.

data:extend({
  {
    type      = "item",
    name      = "starship-scrap-chunk",
    icon      = "__space-age__/graphics/icons/metallic-asteroid-chunk.png",
    icon_size = 64,
    subgroup  = "space-material",
    order     = "e[starship-scrap]-a[chunk]",
    stack_size = 1,
    weight    = 100000,  -- 100 kg; matches vanilla asteroid-chunk weight
  },

  -- Processed output from the crusher. Higher stack size since it's a refined resource.
  {
    type      = "item",
    name      = "starship-scrap",
    icon      = "__space-age__/graphics/icons/metallic-asteroid-chunk.png",
    icon_size = 64,
    subgroup  = "space-material",
    order     = "e[starship-scrap]-b[processed]",
    stack_size = 200,
  },

  -- Rare crystalline energy substrate found in alien ship cores.
  -- Full tech tree comes in Phase 3; defined here because it drops from Phase 2 crushing.
  {
    type      = "item",
    name      = "dilithium-crystal",
    icon      = "__space-age__/graphics/icons/promethium-asteroid-chunk.png",
    icon_size = 64,
    subgroup  = "space-material",
    order     = "e[starship-scrap]-c[dilithium]",
    stack_size = 50,
  },
})
