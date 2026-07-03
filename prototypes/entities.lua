-- The Reef entities: machines and structures.

data:extend({
  -- PMR crafting category — used by all Basic PMR recipes.
  { type = "recipe-category", name = "the-reef-pmr" },
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

-- Cargo Hatch
-- landing-pad-unloading-bay deepcopy (4×4 directional cargo-bay with
-- extractor visuals and bay connection graphics) + hidden proxy-container
-- (spawned by script) that exposes the platform hub's main inventory to
-- inserters. Throughput is throttled by script (token bucket,
-- research-scalable — see scripts/cargo-hatch.lua); placement count and hub
-- distance are also research-gated, and the script keeps the proxy detached
-- while the bay is not connected to the hub network.
--
-- allow_unloading = false is load-bearing: native unloading would let
-- inserters pull from the hub directly, bypassing the throttled (and
-- counted) proxy entirely.

local hatch = table.deepcopy(data.raw["cargo-bay"]["landing-pad-unloading-bay"])
hatch.name                 = "cargo-hatch"
hatch.icon                 = "__space-age__/graphics/icons/cargo-unloading-bay.png"
hatch.icon_size            = 64
hatch.minable              = { mining_time = 0.5, result = "cargo-hatch" }
hatch.inventory_size_bonus = 0        -- must not extend the hub inventory
hatch.allow_unloading      = false    -- all flow goes through the proxy
hatch.use_unloading_distance_limit = false   -- planet landing-pad concept, n/a here
hatch.surface_conditions   = {{ property = "gravity", min = 0, max = 0 }}
-- Platform-style bay connection sprites (the deepcopy ships planet ones).
hatch.graphics_set.connections =
    require("__space-age__.graphics.entity.cargo-hubs.connections.platform-connections")

data:extend({ hatch })

-- Proxy-container for the cargo hatch.
-- Invisible, zero-collision entity placed on top of the hatch. Script sets
-- proxy_target_entity = hub so inserters read/write the hub inventory
-- transparently; the throttle (and the connection gate) detach the target
-- to refuse traffic. Boxes cover the hatch's 4×4 core so inserters anywhere
-- on the footprint resolve their target to the proxy.
data:extend({
    {
        type               = "proxy-container",
        name               = "cargo-hatch-proxy",
        collision_box      = {{ -1.9, -1.9 }, { 1.9, 1.9 }},
        selection_box      = {{ -2,   -2   }, { 2,   2   }},
        collision_mask     = { layers = {} },
        build_grid_size    = 2,
        flags              = { "player-creation", "not-on-map" },
        draw_inventory_content = false,
        selectable_in_game = false,
        selection_priority = 49,
        hidden             = true,
    }
})
