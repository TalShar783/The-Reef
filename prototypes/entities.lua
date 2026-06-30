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
-- Burner-generator base: consumes Dilithium Fuel Cells from a built-in fuel slot
-- and outputs to the electric network. No scripting required.
-- 1 cell = 3GJ at 100% effectivity → 600s at 5MW.
-- Size: 2x2. Placeholder graphics: accumulator (tinted). Replace before release.

local reactor = table.deepcopy(data.raw["burner-generator"]["burner-generator"])
reactor.name          = "dilithium-reactor-1"
reactor.icon          = "__base__/graphics/icons/nuclear-reactor.png"
reactor.icon_size     = 64
reactor.hidden        = false
reactor.subgroup      = "the-reef-machines"
reactor.order         = "b[reactor]"
reactor.minable       = { mining_time = 1, result = "dilithium-reactor-1" }
reactor.collision_box = {{ -0.9, -0.9 }, { 0.9, 0.9 }}
reactor.selection_box = {{ -1,   -1   }, { 1,   1   }}
reactor.max_power_output = "5MW"
reactor.surface_conditions = {{ property = "gravity", min = 0, max = 0 }}
reactor.burner = {
    type               = "burner",
    fuel_categories    = { "dilithium" },
    effectivity        = 1,
    fuel_inventory_size = 1,
}
reactor.energy_source = {
    type           = "electric",
    usage_priority = "primary-output",
}

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
-- A 2×2 container that syncs with the platform cargo hub.
-- inventory_size = 1 enforces the single-stack buffer at the entity level.
-- surface_conditions: gravity = 0 restricts placement to space platforms only.
-- Placeholder graphics: iron chest. Replace with custom art before release.

local hatch = table.deepcopy(data.raw["container"]["iron-chest"])
hatch.name              = "cargo-hatch"
hatch.icon              = "__base__/graphics/icons/iron-chest.png"
hatch.icon_size         = 64
hatch.inventory_size    = 1
hatch.minable           = { mining_time = 0.5, result = "cargo-hatch" }
hatch.collision_box     = {{ -0.9, -0.9 }, { 0.9, 0.9 }}
hatch.selection_box     = {{ -1,   -1   }, { 1,   1   }}
hatch.dying_explosion   = nil   -- suppress poof on silent script-destroy
hatch.corpse            = nil   -- suppress remnants on silent script-destroy
hatch.surface_conditions = {
    {
        property = "gravity",
        min      = 0,
        max      = 0,
    }
}

data:extend({ hatch })

-- Advanced Cargo Hatch (4-slot multi-item)
-- Same 2×2 footprint and surface_conditions as the basic hatch.
-- inventory_size = 4: one buffer slot per configurable filter item.
-- Placeholder graphics: steel chest. Replace with custom art before release.

local adv_hatch = table.deepcopy(data.raw["container"]["iron-chest"])
adv_hatch.name              = "advanced-cargo-hatch"
adv_hatch.icon              = "__base__/graphics/icons/steel-chest.png"
adv_hatch.icon_size         = 64
adv_hatch.inventory_size    = 4
adv_hatch.minable           = { mining_time = 0.5, result = "advanced-cargo-hatch" }
adv_hatch.collision_box     = {{ -0.9, -0.9 }, { 0.9, 0.9 }}
adv_hatch.selection_box     = {{ -1,   -1   }, { 1,   1   }}
adv_hatch.dying_explosion   = nil
adv_hatch.corpse            = nil
adv_hatch.surface_conditions = {{ property = "gravity", min = 0, max = 0 }}

data:extend({ adv_hatch })
