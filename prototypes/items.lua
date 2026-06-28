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
  {
    type      = "item",
    name      = "dilithium-crystal",
    icon      = "__space-age__/graphics/icons/promethium-asteroid-chunk.png",
    icon_size = 64,
    subgroup  = "space-material",
    order     = "e[starship-scrap]-c[dilithium]",
    stack_size = 50,
  },

  -- Dilithium Fuel Cell: powers Tier 1 Dilithium Reactors. Produced in the Basic PMR.
  {
    type      = "item",
    name      = "dilithium-fuel-cell",
    icon      = "__space-age__/graphics/icons/promethium-asteroid-chunk.png",
    icon_size = 64,
    subgroup  = "space-material",
    order     = "e[starship-scrap]-d[fuel-cell]",
    stack_size = 50,
  },

  -- Basic PMR: the Probabilistic Matter Recombinator (buildable item).
  {
    type         = "item",
    name         = "basic-pmr",
    icon         = "__space-age__/graphics/icons/shattered-planet.png",
    icon_size    = 64,
    subgroup     = "production-machine",
    order        = "z[pmr]-a",
    stack_size   = 50,
    place_result = "basic-pmr",
  },
})
