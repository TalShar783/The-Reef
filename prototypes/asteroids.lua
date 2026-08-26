-- Starship Scrap Chunk entity — collected by asteroid collectors in space.
-- Full deepcopy of metallic-asteroid-chunk to inherit all required fields.
-- Replace graphics_set with custom scrap art before release.

local explosion_animations = require("__space-age__.prototypes.entity.explosion-animations")
local space_age_sounds = require("__space-age__.prototypes.entity.sounds")

-- Dedicated starship-scrap explosion entities, using vanilla's own asteroid-explosion
-- sprite sheets (graphics/entity/asteroid-explosions/) rather than reusing the vanilla
-- metallic-asteroid-explosion-N entities outright. No custom tint yet.
data:extend({
    {
        type = "explosion",
        name = "starship-scrap-explosion-chunk",
        flags = {"not-on-map"},
        hidden = true,
        height = 0,
        animations = explosion_animations.asteroid_explosion_chunk(),
        sound = space_age_sounds.asteroid_collision_metallic_small,
    },
    {
        type = "explosion",
        name = "starship-scrap-explosion-small",
        flags = {"not-on-map"},
        hidden = true,
        height = 0,
        animations = explosion_animations.asteroid_explosion_small(),
        sound = space_age_sounds.asteroid_damage_metallic_small,
    },
    {
        type = "explosion",
        name = "starship-scrap-explosion-medium",
        flags = {"not-on-map"},
        hidden = true,
        height = 0,
        animations = explosion_animations.asteroid_explosion_medium(),
        sound = space_age_sounds.asteroid_damage_metallic_medium,
    },
})

local scrap_chunk = table.deepcopy(data.raw["asteroid-chunk"]["metallic-asteroid-chunk"])
scrap_chunk.name    = "starship-scrap-chunk"
scrap_chunk.order   = "e[starship-scrap]-a[chunk]"
scrap_chunk.minable = {
    mining_time     = 0.2,
    result          = "starship-scrap-chunk",
    mining_particle = "metallic-asteroid-chunk-particle-medium",
}
scrap_chunk.graphics_set.variations =
{
    {
        color_texture = {
            filename =          "__the-reef__/graphics/entity/starship-scrap/chunk/asteroid-starship-scrap-chunks-color-1.png",
            size = 50,
            scale = 0.5,
        },
        normal_map = {
        filename =              "__the-reef__/graphics/entity/starship-scrap/chunk/asteroid-starship-scrap-chunks-normal-1.png",
        size = 50,
        scale = 0.5,
        premul_alpha = false,
        },
        roughness_map = {
            filename =         "__the-reef__/graphics/entity/starship-scrap/chunk/asteroid-starship-scrap-chunks-roughness-1.png",
            size = 50,
            scale = 0.5,
            premul_alpha = false,
        }
    },
        {
        color_texture = {
            filename =          "__the-reef__/graphics/entity/starship-scrap/chunk/asteroid-starship-scrap-chunks-color-2.png",
            size = 50,
            scale = 0.5,
        },
        normal_map = {
        filename =              "__the-reef__/graphics/entity/starship-scrap/chunk/asteroid-starship-scrap-chunks-normal-2.png",
        size = 50,
        scale = 0.5,
        premul_alpha = false,
        },
        roughness_map = {
            filename =         "__the-reef__/graphics/entity/starship-scrap/chunk/asteroid-starship-scrap-chunks-roughness-2.png",
            size = 50,
            scale = 0.5,
            premul_alpha = false,
        }
    },
            {
        color_texture = {
            filename =          "__the-reef__/graphics/entity/starship-scrap/chunk/asteroid-starship-scrap-chunks-color-3.png",
            size = 50,
            scale = 0.5,
        },
        normal_map = {
        filename =              "__the-reef__/graphics/entity/starship-scrap/chunk/asteroid-starship-scrap-chunks-normal-3.png",
        size = 50,
        scale = 0.5,
        premul_alpha = false,
        },
        roughness_map = {
            filename =         "__the-reef__/graphics/entity/starship-scrap/chunk/asteroid-starship-scrap-chunks-roughness-3.png",
            size = 50,
            scale = 0.5,
            premul_alpha = false,
        }
    },
            {
        color_texture = {
            filename =          "__the-reef__/graphics/entity/starship-scrap/chunk/asteroid-starship-scrap-chunks-color-4.png",
            size = 50,
            scale = 0.5,
        },
        normal_map = {
        filename =              "__the-reef__/graphics/entity/starship-scrap/chunk/asteroid-starship-scrap-chunks-normal-4.png",
        size = 50,
        scale = 0.5,
        premul_alpha = false,
        },
        roughness_map = {
            filename =         "__the-reef__/graphics/entity/starship-scrap/chunk/asteroid-starship-scrap-chunks-roughness-4.png",
            size = 50,
            scale = 0.5,
            premul_alpha = false,
        }
    },
            {
        color_texture = {
            filename =          "__the-reef__/graphics/entity/starship-scrap/chunk/asteroid-starship-scrap-chunks-color-5.png",
            size = 50,
            scale = 0.5,
        },
        normal_map = {
        filename =              "__the-reef__/graphics/entity/starship-scrap/chunk/asteroid-starship-scrap-chunks-normal-5.png",
        size = 50,
        scale = 0.5,
        premul_alpha = false,
        },
        roughness_map = {
            filename =         "__the-reef__/graphics/entity/starship-scrap/chunk/asteroid-starship-scrap-chunks-roughness-5.png",
            size = 50,
            scale = 0.5,
            premul_alpha = false,
        }
    }
}
scrap_chunk.dying_trigger_effect[1].entity_name = "starship-scrap-explosion-chunk"

local scrap_small = table.deepcopy(data.raw["asteroid"]["small-metallic-asteroid"])
scrap_small.name  = "starship-scrap-small"
scrap_small.order = "e[starship-scrap]-b[small]"
scrap_small.graphics_set.variations =
{
    {
        color_texture = {
            filename = "__the-reef__/graphics/entity/starship-scrap/small/asteroid-starship-scrap-small-color-1.png",
            size = 128,
            scale = 0.5,
        },
        shadow_shift = { 0.5, 0.5 },
        normal_map = {
            filename = "__the-reef__/graphics/entity/starship-scrap/small/asteroid-starship-scrap-small-normal-1.png",
            size = 128,
            scale = 0.5,
            premul_alpha = false,
        },
        roughness_map = {
            filename = "__the-reef__/graphics/entity/starship-scrap/small/asteroid-starship-scrap-small-roughness-1.png",
            size = 128,
            scale = 0.5,
            premul_alpha = false,
        }
    }
}
-- Break into starship-scrap-chunk instead of vanilla metallic-asteroid-chunk.
scrap_small.dying_trigger_effect[1].entity_name = "starship-scrap-explosion-small"
scrap_small.dying_trigger_effect[2].asteroid_name = "starship-scrap-chunk"

local scrap_medium = table.deepcopy(data.raw["asteroid"]["medium-metallic-asteroid"])
scrap_medium.name  = "starship-scrap-medium"
scrap_medium.order = "e[starship-scrap]-c[medium]"
scrap_medium.graphics_set.variations =
{
    {
        color_texture = {
            filename = "__the-reef__/graphics/entity/starship-scrap/medium/asteroid-starship-scrap-medium-color-1.png",
            size = 230,
            scale = 0.5,
        },
        shadow_shift = { 0.75, 0.75 },
        normal_map = {
            filename = "__the-reef__/graphics/entity/starship-scrap/medium/asteroid-starship-scrap-medium-normal-1.png",
            size = 230,
            scale = 0.5,
            premul_alpha = false,
        },
        roughness_map = {
            filename = "__the-reef__/graphics/entity/starship-scrap/medium/asteroid-starship-scrap-medium-roughness-1.png",
            size = 230,
            scale = 0.5,
            premul_alpha = false,
        }
    },
    {
        color_texture = {
            filename = "__the-reef__/graphics/entity/starship-scrap/medium/asteroid-starship-scrap-medium-color-2.png",
            size = 230,
            scale = 0.5,
        },
        shadow_shift = { 0.75, 0.75 },
        normal_map = {
            filename = "__the-reef__/graphics/entity/starship-scrap/medium/asteroid-starship-scrap-medium-normal-2.png",
            size = 230,
            scale = 0.5,
            premul_alpha = false,
        },
        roughness_map = {
            filename = "__the-reef__/graphics/entity/starship-scrap/medium/asteroid-starship-scrap-medium-roughness-2.png",
            size = 230,
            scale = 0.5,
            premul_alpha = false,
        }
    }
}

-- Break into starship-scrap-small instead of vanilla small-metallic-asteroid.
scrap_medium.dying_trigger_effect[1].entity_name = "starship-scrap-explosion-medium"
scrap_medium.dying_trigger_effect[2].entity_name = "starship-scrap-small"

data:extend({ scrap_chunk, scrap_small, scrap_medium })
