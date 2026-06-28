-- The Reef entities: machines and structures.

data:extend({
  -- PMR crafting category — used by all Basic PMR recipes.
  {
    type = "recipe-category",
    name = "the-reef-pmr",
  },

  -- Dilithium fuel category — Dilithium Fuel Cells burn only in dilithium-fuel burners.
  {
    type = "fuel-category",
    name = "dilithium-fuel",
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
-- Phase 4: data-only. Deepcopy of nuclear-reactor so all required heat/fuel
-- fields are populated correctly. Takes Dilithium Fuel Cells (dilithium-fuel
-- category), outputs 20MW of heat (half nuclear). Water requirement and
-- direct-electricity conversion (no heat pipes) are Phase 5 scripting goals.
-- Placeholder graphics: nuclear reactor. Replace with custom art before release.

local reactor = table.deepcopy(data.raw["reactor"]["nuclear-reactor"])
reactor.name              = "dilithium-reactor-1"
reactor.icon              = "__space-age__/graphics/icons/nuclear-reactor.png"
reactor.icon_size         = 64
reactor.minable           = { mining_time = 1, result = "dilithium-reactor-1" }
reactor.consumption       = "20MW"   -- heat output; half nuclear's 40MW for T1
reactor.neighbour_bonus   = 0        -- no adjacency bonus (it's not a nuclear array)
-- Override fuel category to dilithium-fuel only
reactor.energy_source = {
  type                    = "burner",
  fuel_category           = "dilithium-fuel",
  effectivity             = 1,
  fuel_inventory_size     = 1,
  burnt_inventory_size    = 1,
  emissions_per_minute    = {},
}

data:extend({ reactor })
