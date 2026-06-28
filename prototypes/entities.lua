-- The Reef entities: machines and structures.

data:extend({
  -- PMR crafting category — used by all Basic PMR recipes.
  {
    type = "recipe-category",
    name = "the-reef-pmr",
  },


})

-- Basic PMR (Probabilistic Matter Recombinator)
-- A 1x1 compact machine that converts raw materials directly into finished goods,
-- skipping intermediate production steps. Wrong inputs produce Unstable Isotopes
-- (mechanic deferred to a later phase — pure data for now).
--
-- Visual placeholder: deep copy of assembling-machine-1.
-- Replace with custom 1x1 art before release.
-- Belt I/O mechanic (Loaders or scripting) deferred to a later phase.

local pmr = table.deepcopy(data.raw["assembling-machine"]["assembling-machine-1"])
pmr.name             = "basic-pmr"
pmr.icon             = "__space-age__/graphics/icons/shattered-planet.png"
pmr.icon_size        = 64
pmr.crafting_categories = { "the-reef-pmr" }
pmr.crafting_speed   = 1
pmr.ingredient_count = 4  -- max 4 ingredient types (fuel cell needs 3)
pmr.minable          = { mining_time = 0.5, result = "basic-pmr" }
pmr.fixed_recipe     = nil  -- assembling-machine-1 has no fixed recipe but clear it anyway

data:extend({ pmr })

-- Dilithium Reactor T1
-- Phase 4: data-only. Uses electric-energy-interface as the base — this is the
-- correct foundation for an entity that injects electricity into the grid via script.
-- Static 20MW production for now; Phase 5 scripting makes it conditional on
-- Dilithium Fuel Cell + ice consumption.
-- Size: 2x2. Placeholder graphics: accumulator (tinted). Replace before release.

local reactor = table.deepcopy(data.raw["electric-energy-interface"]["electric-energy-interface"])
reactor.name          = "dilithium-reactor-1"
reactor.icon          = "__base__/graphics/icons/nuclear-reactor.png"
reactor.icon_size     = 64
reactor.hidden        = false
reactor.subgroup      = "the-reef-machines"
reactor.order         = "b[reactor]"
reactor.minable       = { mining_time = 1, result = "dilithium-reactor-1" }
reactor.collision_box = {{ -1, -1 }, { 1, 1 }}   -- 2x2
reactor.selection_box = {{ -1, -1 }, { 1, 1 }}
reactor.energy_source = {
    type              = "electric",
    buffer_capacity   = "2MJ",
    usage_priority    = "primary-output",
    output_flow_limit = "20MW",
}
reactor.energy_production = "20MW"
reactor.energy_usage      = "0kW"

data:extend({ reactor })

-- Ithaca Scrap Deposit — resource nodes on the scattered island fragments.
-- Deepcopy of iron-ore inherits all required stage/sprite/collision fields.
-- Produces starship-scrap when mined by electric mining drills.
-- Placeholder appearance: iron-ore sprites. Replace with custom art before release.

local scrap_deposit = table.deepcopy(data.raw["resource"]["iron-ore"])
scrap_deposit.name          = "ithaca-scrap-deposit"
scrap_deposit.icon          = "__space-age__/graphics/icons/metallic-asteroid-chunk.png"
scrap_deposit.icon_size     = 64
scrap_deposit.map_color     = { r = 0.6, g = 0.5, b = 0.4 }
scrap_deposit.minable       = {
    mining_time = 1,
    result      = "starship-scrap",
    count       = 1,
}
scrap_deposit.infinite      = false
scrap_deposit.subgroup      = "the-reef-materials"
scrap_deposit.order         = "z[scrap-deposit]"

data:extend({ scrap_deposit })

-- Cargo Hatch (basic)
-- A 1-slot container that syncs with the platform cargo hub.
-- inventory_size = 1 enforces the single-stack buffer at the entity level.
-- Placeholder graphics: iron chest. Replace with custom art before release.

local hatch = table.deepcopy(data.raw["container"]["iron-chest"])
hatch.name           = "cargo-hatch"
hatch.icon           = "__base__/graphics/icons/iron-chest.png"
hatch.icon_size      = 64
hatch.inventory_size = 1
hatch.minable        = { mining_time = 0.5, result = "cargo-hatch" }

data:extend({ hatch })
