-- Crusher recipe: Starship Scrap Chunk → raw materials + rare Dilithium Crystal.
-- Follows the vanilla asteroid-crushing pattern:
--   category = "crushing", auto_recycle = false, allow_productivity = true
--   A fraction of chunks survive crushing (probability < 1 on the chunk result).
--
-- Recycler recipe: Starship Scrap → varied raw outputs.
--   category = "recycling-or-hand-crafting" matches the Fulgoran scrap pattern.

data:extend({
  -- Crushing ---------------------------------------------------------------
  {
    type     = "recipe",
    name     = "starship-scrap-crushing",
    icon     = "__space-age__/graphics/icons/metallic-asteroid-chunk.png",
    icon_size = 64,
    categories = { "crushing" },
    subgroup = "the-reef-processing",
    order    = "e-a",
    enabled  = false,
    auto_recycle = false,
    allow_productivity  = true,
    allow_decomposition = false,
    energy_required = 2,
    ingredients = {
      { type = "item", name = "starship-scrap-chunk", amount = 1 },
    },
    results = {
      { type = "item", name = "iron-plate",      amount = 5 },
      { type = "item", name = "copper-plate",    amount = 3 },
      { type = "item", name = "steel-plate",     amount = 1 },
      -- Chunk survives intact with 15% probability (reprocess it)
      { type = "item", name = "starship-scrap-chunk", amount = 1, independent_probability =0.15 },
      -- Dilithium Crystal: rare find deep in the ship debris
      { type = "item", name = "dilithium-crystal", amount = 1, independent_probability =0.03 },
    },
  },

  -- PMR recipes (test) -----------------------------------------------------
  -- Raw inputs are exact totals for each step in the vanilla crafting chain
  -- at 100% efficiency with no modules or speed bonuses.

  -- Green Circuits: 1 circuit = 1 iron plate + 3 copper cables (= 1.5 copper plate)
  -- LCM gives: 2 iron ore + 3 copper ore → 2 electronic-circuit
  {
    type     = "recipe",
    name     = "pmr-green-circuits",
    icon     = "__base__/graphics/icons/electronic-circuit.png",
    icon_size = 64,
    categories = { "the-reef-pmr" },
    subgroup = "intermediate-product",
    order    = "z[pmr]-a",
    enabled  = false,
    energy_required = 1,
    ingredients = {
      { type = "item", name = "iron-ore",    amount = 2 },
      { type = "item", name = "copper-ore",  amount = 3 },
    },
    results = {
      { type = "item", name = "electronic-circuit", amount = 2 },
    },
  },

  -- Grenades: 1 grenade = 5 iron plates + 1 coal (direct recipe, no intermediates)
  -- → 5 iron ore + 1 coal → 1 grenade
  {
    type     = "recipe",
    name     = "pmr-grenades",
    icon     = "__base__/graphics/icons/grenade.png",
    icon_size = 64,
    categories = { "the-reef-pmr" },
    order    = "z[pmr]-b",
    enabled  = false,
    energy_required = 1,
    ingredients = {
      { type = "item", name = "iron-ore", amount = 5 },
      { type = "item", name = "coal",     amount = 1 },
    },
    results = {
      { type = "item", name = "grenade", amount = 1 },
    },
  },

  -- Piercing Rounds Magazine:
  --   1 firearm mag (4 iron) + 5 steel (25 iron) + 1 copper plate (1 copper ore)
  --   = 29 iron ore + 1 copper ore → 1 piercing-rounds-magazine
  {
    type     = "recipe",
    name     = "pmr-piercing-magazines",
    icon     = "__base__/graphics/icons/piercing-rounds-magazine.png",
    icon_size = 64,
    categories = { "the-reef-pmr" },
    order    = "z[pmr]-c",
    enabled  = false,
    energy_required = 1,
    ingredients = {
      { type = "item", name = "iron-ore",   amount = 13 },
      { type = "item", name = "copper-ore", amount = 2  },
    },
    results = {
      { type = "item", name = "piercing-rounds-magazine", amount = 2 },
    },
  },

  -- Dilithium Fuel Cell: powers Tier 1 Dilithium Reactors.
  -- Produced in the Basic PMR; 3 ingredient types (hence ingredient_count = 4 on entity).
  {
    type     = "recipe",
    name     = "dilithium-fuel-cell",
    icon     = "__space-age__/graphics/icons/promethium-asteroid-chunk.png",
    icon_size = 64,
    categories = { "the-reef-pmr" },
    subgroup = "the-reef-materials",
    order    = "z[pmr]-d",
    enabled  = false,
    energy_required = 5,
    ingredients = {
      { type = "item", name = "steel-plate",        amount = 2 },
      { type = "item", name = "dilithium-crystal",  amount = 2 },
      { type = "item", name = "electronic-circuit", amount = 2 },
    },
    results = {
      { type = "item", name = "dilithium-fuel-cell", amount = 2 },
    },
  },

  -- Dilithium Science Pack — produced in the PMR from reef materials.
  -- 2 crystals + 2 scrap → 2 packs in 10 seconds.
  {
    type     = "recipe",
    name     = "dilithium-science-pack",
    icon     = "__space-age__/graphics/icons/promethium-science-pack.png",
    icon_size = 64,
    categories = { "the-reef-pmr" },
    order    = "z[pmr]-e",
    enabled  = false,
    energy_required = 10,
    ingredients = {
      { type = "item", name = "dilithium-crystal", amount = 2 },
      { type = "item", name = "starship-scrap",    amount = 2 },
    },
    results = {
      { type = "item", name = "dilithium-science-pack", amount = 2 },
    },
  },

  -- Dilithium Reactor T1 (building recipe) — crafted in an assembling machine.
  -- Costs more than the PMR; it's an advanced power structure.
  {
    type     = "recipe",
    name     = "dilithium-reactor-1",
    icon     = "__base__/graphics/icons/nuclear-reactor.png",
    icon_size = 64,
    categories = { "crafting" },
    subgroup = "the-reef-machines",
    order    = "z[reactor]-a",
    enabled  = false,
    energy_required = 30,
    ingredients = {
      { type = "item", name = "steel-plate",         amount = 30 },
      { type = "item", name = "advanced-circuit",    amount = 20 },
      { type = "item", name = "dilithium-crystal",   amount = 5  },
      { type = "item", name = "copper-plate",        amount = 20 },
    },
    results = {
      { type = "item", name = "dilithium-reactor-1", amount = 1 },
    },
  },

  -- Cargo Hatch (building recipe).
  {
    type     = "recipe",
    name     = "cargo-hatch",
    icon     = "__space-age__/graphics/icons/cargo-unloading-bay.png",
    icon_size = 64,
    categories = { "crafting" },
    subgroup = "the-reef-machines",
    order    = "z[hatch]",
    enabled  = false,
    energy_required = 5,
    ingredients = {
      { type = "item", name = "iron-plate",         amount = 10 },
      { type = "item", name = "steel-plate",        amount = 5  },
      { type = "item", name = "electronic-circuit", amount = 5  },
    },
    results = {
      { type = "item", name = "cargo-hatch", amount = 1 },
    },
  },

  -- Basic PMR (building recipe) — crafted in an assembling machine.
  {
    type     = "recipe",
    name     = "basic-pmr",
    icon     = "__space-age__/graphics/icons/shattered-planet.png",
    icon_size = 64,
    categories = { "crafting" },
    subgroup = "the-reef-machines",
    order    = "z[pmr]-a",
    enabled  = false,
    energy_required = 5,
    ingredients = {
      { type = "item", name = "iron-plate",        amount = 20 },
      { type = "item", name = "steel-plate",       amount = 10 },
      { type = "item", name = "electronic-circuit", amount = 10 },
    },
    results = {
      { type = "item", name = "basic-pmr", amount = 1 },
    },
  },

  -- Fluid PMR (building recipe) — crafted in an assembling machine.
  {
    type     = "recipe",
    name     = "fluid-pmr",
    icon     = "__space-age__/graphics/icons/shattered-planet.png",
    icon_size = 64,
    categories = { "crafting" },
    subgroup = "the-reef-machines",
    order    = "z[pmr]-c",
    enabled  = false,
    energy_required = 10,
    ingredients = {
      { type = "item", name = "iron-plate",        amount = 30 },
      { type = "item", name = "steel-plate",       amount = 15 },
      { type = "item", name = "electronic-circuit", amount = 10 },
      { type = "item", name = "pipe",              amount = 20 },
    },
    results = {
      { type = "item", name = "fluid-pmr", amount = 1 },
    },
  },

  -- Fluid PMR crafter recipes ------------------------------------------------
  -- "fluid-pmr" category is strictly one-to-one with fluid-pmr-crafter (see
  -- prototypes/fluid-pmr.lua) — no other machine can craft these, and these
  -- have no other category. hidden/enabled=true: never shown to or unlocked
  -- by the player, only ever assigned via entity.set_recipe() from
  -- scripts/fluid-pmr.lua. Test case only — fluorine substitutes for oil
  -- purely for testing since oil isn't a tracked PMR fluid.
  {
    type     = "recipe",
    name     = "fluid-pmr-test-assembling-machine-2",
    icon     = "__base__/graphics/icons/assembling-machine-2.png",
    icon_size = 64,
    categories = { "fluid-pmr" },
    subgroup = "the-reef-processing",
    order    = "z[pmr]-fluid-a",
    hidden   = true,
    enabled  = true,
    energy_required = 0.5,
    ingredients = {
      { type = "fluid", name = "molten-iron",  amount = 10, fluidbox_index = 1 },
      { type = "fluid", name = "molten-copper", amount = 10, fluidbox_index = 2 },
      { type = "fluid", name = "fluorine",      amount = 10, fluidbox_index = 3 },
    },
    results = {
      { type = "item", name = "assembling-machine-2", amount = 1 },
    },
  },

  -- Second test recipe — used to test the shell's recipe-selection logic
  -- (prefers the affordable recipe with the most fluid ingredients) once
  -- both recipes are simultaneously affordable.
  {
    type     = "recipe",
    name     = "fluid-pmr-test-assembling-machine-3",
    icon     = "__base__/graphics/icons/assembling-machine-3.png",
    icon_size = 64,
    categories = { "fluid-pmr" },
    subgroup = "the-reef-processing",
    order    = "z[pmr]-fluid-b",
    hidden   = true,
    enabled  = true,
    energy_required = 0.5,
    ingredients = {
      { type = "fluid", name = "fluorine", amount = 10, fluidbox_index = 1 },
      { type = "fluid", name = "lava",     amount = 10, fluidbox_index = 2 },
    },
    results = {
      { type = "item", name = "assembling-machine-3", amount = 1 },
    },
  },

  -- Recycling --------------------------------------------------------------
  -- Starship Scrap → salvage from alien vessel interiors.
  -- Three tiers: raw materials (high), platform foundations (middling),
  -- fully assembled platform structures (low/rare).
  -- All item names verified against game files before use.
  {
    type     = "recipe",
    name     = "starship-scrap-recycling",
    icon     = "__space-age__/graphics/icons/metallic-asteroid-chunk.png",
    icon_size = 64,
    categories = { "recycling", "hand-crafting" },
    subgroup = "the-reef-processing",
    order    = "e-b",
    enabled  = false,
    auto_recycle = false,
    energy_required = 2,
    ingredients = {
      { type = "item", name = "starship-scrap", amount = 1 },
    },
    results = {
      -- ── High chance: raw materials ──────────────────────────────────────
      { type = "item", name = "low-density-structure", amount = 1, independent_probability =0.28, show_details_in_recipe_tooltip = false },
      { type = "item", name = "steel-plate",            amount = 2, independent_probability =0.25, show_details_in_recipe_tooltip = false },
      { type = "item", name = "copper-cable",           amount = 3, independent_probability =0.22, show_details_in_recipe_tooltip = false },
      { type = "item", name = "electronic-circuit",     amount = 2, independent_probability =0.20, show_details_in_recipe_tooltip = false },
      { type = "item", name = "advanced-circuit",       amount = 1, independent_probability =0.12, show_details_in_recipe_tooltip = false },
      { type = "item", name = "plastic-bar",            amount = 1, independent_probability =0.10, show_details_in_recipe_tooltip = false },
      { type = "item", name = "battery",                amount = 1, independent_probability =0.08, show_details_in_recipe_tooltip = false },
      { type = "item", name = "processing-unit",        amount = 1, independent_probability =0.05, show_details_in_recipe_tooltip = false },

      -- ── Middling chance: platform structure ─────────────────────────────
      { type = "item", name = "space-platform-foundation", amount = 2, independent_probability =0.12, show_details_in_recipe_tooltip = false },

      -- ── Low chance: assembled platform structures ────────────────────────
      { type = "item", name = "solar-panel",        amount = 1, independent_probability =0.04, show_details_in_recipe_tooltip = false },
      { type = "item", name = "accumulator",        amount = 1, independent_probability =0.03, show_details_in_recipe_tooltip = false },
      { type = "item", name = "gun-turret",         amount = 1, independent_probability =0.03, show_details_in_recipe_tooltip = false },
      { type = "item", name = "asteroid-collector", amount = 1, independent_probability =0.03, show_details_in_recipe_tooltip = false },
      { type = "item", name = "radar",              amount = 1, independent_probability =0.02, show_details_in_recipe_tooltip = false },
      { type = "item", name = "laser-turret",       amount = 1, independent_probability =0.02, show_details_in_recipe_tooltip = false },
      { type = "item", name = "rocket-turret",      amount = 1, independent_probability =0.02, show_details_in_recipe_tooltip = false },
      { type = "item", name = "thruster",           amount = 1, independent_probability =0.02, show_details_in_recipe_tooltip = false },
      { type = "item", name = "roboport",           amount = 1, independent_probability =0.01, show_details_in_recipe_tooltip = false },
      { type = "item", name = "dilithium-crystal",  amount = 1, independent_probability =0.01, show_details_in_recipe_tooltip = false },
    },
  },
})
