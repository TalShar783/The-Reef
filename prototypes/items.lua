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
  -- fuel_category and fuel_value make it burnable in the dilithium-fuel category.
  -- 2GJ per cell at 20MW output = 100 seconds of power per cell.
  {
    type          = "item",
    name          = "dilithium-fuel-cell",
    icon          = "__space-age__/graphics/icons/promethium-asteroid-chunk.png",
    icon_size     = 64,
    subgroup      = "space-material",
    order         = "e[starship-scrap]-d[fuel-cell]",
    stack_size    = 50,
    fuel_category = "dilithium-fuel",
    fuel_value    = "2GJ",
  },

  -- Dilithium Science Pack: unlocks the Dilithium Era tech tree.
  -- type = "tool" is required for science packs (not "item").
  -- Produced in the Basic PMR from Dilithium Crystals and Starship Scrap.
  {
    type      = "tool",
    name      = "dilithium-science-pack",
    icon      = "__space-age__/graphics/icons/promethium-science-pack.png",
    icon_size = 64,
    subgroup  = "science-pack",
    order     = "z[dilithium]",
    stack_size = 200,
    durability = 1,
    durability_description_key = "description.science-pack-remaining-amount-key",
  },

  -- Dilithium Reactor T1 (buildable item).
  {
    type         = "item",
    name         = "dilithium-reactor-1",
    icon         = "__base__/graphics/icons/nuclear-reactor.png",
    icon_size    = 64,
    subgroup     = "production-machine",
    order        = "z[reactor]-a",
    stack_size   = 5,
    place_result = "dilithium-reactor-1",
  },

  -- Cargo Hatch: single-stack access point to the platform cargo hub.
  {
    type         = "item",
    name         = "cargo-hatch",
    icon         = "__base__/graphics/icons/iron-chest.png",
    icon_size    = 64,
    subgroup     = "production-machine",
    order        = "z[hatch]-a",
    stack_size   = 50,
    place_result = "cargo-hatch",
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
