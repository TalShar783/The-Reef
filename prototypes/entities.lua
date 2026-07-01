-- The Reef entities: machines and structures.

data:extend({
  -- PMR crafting category — used by all Basic PMR recipes.
  { type = "recipe-category", name = "the-reef-pmr" },

  -- Fluid PMR crafting category — display recipes only; native crafting blocked.
  -- All fluid boxes use production_type="none" so the crafter never sees ingredients.
  -- Script drives all fluid routing and production via on_tick.
  { type = "recipe-category", name = "the-reef-fluid-pmr" },
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
pmr.fixed_recipe     = nil
pmr.next_upgrade     = nil

-- 1x1 footprint (standard chest inset).
pmr.collision_box = {{ -0.35, -0.35 }, { 0.35, 0.35 }}
pmr.selection_box = {{ -0.5,  -0.5  }, { 0.5,  0.5  }}

-- Disable module slots and circuit connector (positions mismatch on 1x1).
pmr.module_slots              = 0
pmr.circuit_connector         = nil
pmr.circuit_wire_max_distance = 0

-- Replace assembler graphics with requester-chest sprite.
-- Directional arrows deferred to companion loader feature (loader-1x1 entities
-- placed on either side will provide directional sprites natively).
pmr.graphics_set = {
    animation = {
        filename    = "__base__/graphics/entity/logistic-chest/requester-chest.png",
        width       = 66,
        height      = 74,
        shift       = util.by_pixel(0, -2),
        scale       = 0.5,
        frame_count = 1,
    },
}

data:extend({ pmr })

-- Fluid PMR (Probabilistic Matter Recombinator — Fluid Variant)
-- 3×3 machine (chemical-plant footprint). Accepts one fluid input on the left
-- face. Internal tanks for molten-iron and molten-copper (production_type="none"
-- so the native crafter never matches them as recipe ingredients). All fluid
-- movement and production driven by scripts/fluid_pmr.lua.
--
-- Display recipes (fluid-pmr-iron-plate, fluid-pmr-copper-plate) are set by
-- script via entity.set_recipe() to show the predicted output ghost and expose
-- the predicted-output item signal on the circuit network.
--
-- Placeholder graphics: chemical-plant sprites. Replace with custom art before release.

local fluid_pmr = table.deepcopy(data.raw["assembling-machine"]["chemical-plant"])
fluid_pmr.name              = "fluid-pmr"
fluid_pmr.icon              = "__space-age__/graphics/icons/shattered-planet.png"
fluid_pmr.icon_size         = 64
fluid_pmr.crafting_categories = { "the-reef-fluid-pmr" }
fluid_pmr.crafting_speed    = 1
fluid_pmr.ingredient_count  = 4
fluid_pmr.minable           = { mining_time = 1, result = "fluid-pmr" }
fluid_pmr.fixed_recipe      = nil
fluid_pmr.next_upgrade      = nil
fluid_pmr.module_slots      = 0
fluid_pmr.allowed_effects   = nil

-- One external input on the left (west) face only.
-- production_type="none" on all boxes: native crafter sees no recipe ingredients
-- and will never fire. Script handles all fluid routing and production.
--
-- Fluid box index map (used in fluid_pmr.lua):
--   [1] staging / external input (has pipe connection, left face)
--   [2] molten-iron internal tank  (no connections, filtered)
--   [3] molten-copper internal tank (no connections, filtered)
fluid_pmr.fluid_boxes = {
    {
        production_type  = "input",
        pipe_covers      = pipecoverspictures(),
        volume           = 200,
        pipe_connections = {
            {
                flow_direction = "input",
                direction      = defines.direction.west,
                position       = { -1, 0 },
            }
        },
    },
    {
        production_type  = "input",
        filter           = "molten-iron",
        volume           = 500,
        pipe_connections = {},
    },
    {
        production_type  = "input",
        filter           = "molten-copper",
        volume           = 500,
        pipe_connections = {},
    },
}
fluid_pmr.fluid_boxes_off_when_no_fluid_recipe = false

data:extend({ fluid_pmr })

-- Dilithium Reactor T1
-- Burner-generator base: consumes Dilithium Fuel Cells from a built-in fuel slot
-- and outputs to the electric network. No scripting required.
-- 1 cell = 3GJ at 100% effectivity → 600s at 5MW.
-- Size: 2x2. Placeholder graphics: stone furnace (2x scale). Replace before release.

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
    type                = "burner",
    fuel_categories     = { "dilithium" },
    effectivity         = 1,
    fuel_inventory_size = 1,
}
reactor.energy_source = {
    type           = "electric",
    usage_priority = "primary-output",
}
-- Replace steam-engine animation with stone-furnace at 2x scale (2x2 footprint).
reactor.animation = {
    filename    = "__base__/graphics/entity/stone-furnace/stone-furnace.png",
    width       = 151,
    height      = 146,
    shift       = util.by_pixel(-0.25, 6),
    scale       = 0.5,
    frame_count = 1,
}
reactor.idle_animation = nil

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

-- Advanced Cargo Hatch
-- cargo-bay type: its inventory IS the platform hub inventory (shared pool).
-- allow_unloading = true lets inserters extract from it natively.
-- Inserters can also insert into it — items go straight into the hub.
-- No script needed; no GUI filter; no mode toggle.
-- Placeholder graphics: deepcopy vanilla cargo-bay. Replace before release.

local adv_hatch = table.deepcopy(data.raw["cargo-bay"]["cargo-bay"])
adv_hatch.name                 = "advanced-cargo-hatch"
adv_hatch.icon                 = "__base__/graphics/icons/steel-chest.png"
adv_hatch.icon_size            = 64
adv_hatch.inventory_size_bonus = 20
adv_hatch.minable              = { mining_time = 0.5, result = "advanced-cargo-hatch" }
adv_hatch.collision_box        = {{ -0.9, -0.9 }, { 0.9, 0.9 }}
adv_hatch.selection_box        = {{ -1,   -1   }, { 1,   1   }}
adv_hatch.surface_conditions   = {{ property = "gravity", min = 0, max = 0 }}

-- Replace cargo-bay visuals with steel-chest placeholder.
-- cargo-bay graphics_set reads `picture` (array of render-layer entries), not `animation`.
adv_hatch.graphics_set = {
    picture = {
        {
            render_layer = "object",
            layers = {
                {
                    filename    = "__base__/graphics/entity/steel-chest/steel-chest.png",
                    priority    = "extra-high",
                    width       = 64,
                    height      = 80,
                    shift       = util.by_pixel(-0.25, -0.5),
                    scale       = 0.5,
                    frame_count = 1,
                }
            }
        }
    }
}
adv_hatch.platform_graphics_set = nil
-- Remove the animated hatch-lid that the cargo-bay deepcopy inherits.
adv_hatch.hatch_definitions = nil

data:extend({ adv_hatch })

-- Proxy-container for advanced-cargo-hatch.
-- Invisible, zero-collision entity placed on top of the advanced hatch.
-- Script sets proxy_target_entity = hub so inserters/loaders read and write
-- the hub inventory transparently without any tick-based sync.
data:extend({
    {
        type               = "proxy-container",
        name               = "advanced-cargo-hatch-proxy",
        collision_box      = {{ -0.9, -0.9 }, { 0.9, 0.9 }},
        selection_box      = {{ -1,   -1   }, { 1,   1   }},
        collision_mask     = { layers = {} },
        build_grid_size    = 2,
        flags              = { "player-creation", "not-on-map" },
        draw_inventory_content = false,
        selectable_in_game = false,
        selection_priority = 49,
        hidden             = true,
    }
})
