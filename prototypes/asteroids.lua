-- Starship Scrap Chunk entity — collected by asteroid collectors in space.
-- Full deepcopy of metallic-asteroid-chunk to inherit all required fields.
-- Replace graphics_set with custom scrap art before release.

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
            filename =          "__the-reef__/graphics/entity/starship-scrap/chunks/asteroid-starship-chunk-color-1.png",
            size = 128,
            scale = 0.195,
        },
        normal_map = {
        filename =              "__the-reef__/graphics/entity/starship-scrap/chunks/asteroid-starship-chunk-normal-1.png",
        size = 128,
        scale = 0.195,
        premul_alpha = false,
        },
        roughness_map = {
            filename =         "__the-reef__/graphics/entity/starship-scrap/chunks/asteroid-starship-chunk-roughness-1.png",
            size = 128,
            scale = 0.195,
            premul_alpha = false,
        }
    },
        {
        color_texture = {
            filename =          "__the-reef__/graphics/entity/starship-scrap/chunks/asteroid-starship-chunk-color-2.png",
            size = 128,
            scale = 0.195,
        },
        normal_map = {
        filename =              "__the-reef__/graphics/entity/starship-scrap/chunks/asteroid-starship-chunk-normal-2.png",
        size = 128,
        scale = 0.195,
        premul_alpha = false,
        },
        roughness_map = {
            filename =         "__the-reef__/graphics/entity/starship-scrap/chunks/asteroid-starship-chunk-roughness-2.png",
            size = 128,
            scale = 0.195,
            premul_alpha = false,
        }
    },
            {
        color_texture = {
            filename =          "__the-reef__/graphics/entity/starship-scrap/chunks/asteroid-starship-chunk-color-3.png",
            size = 128,
            scale = 0.195,
        },
        normal_map = {
        filename =              "__the-reef__/graphics/entity/starship-scrap/chunks/asteroid-starship-chunk-normal-3.png",
        size = 128,
        scale = 0.195,
        premul_alpha = false,
        },
        roughness_map = {
            filename =         "__the-reef__/graphics/entity/starship-scrap/chunks/asteroid-starship-chunk-roughness-3.png",
            size = 128,
            scale = 0.195,
            premul_alpha = false,
        }
    },
            {
        color_texture = {
            filename =          "__the-reef__/graphics/entity/starship-scrap/chunks/asteroid-starship-chunk-color-4.png",
            size = 128,
            scale = 0.195,
        },
        normal_map = {
        filename =              "__the-reef__/graphics/entity/starship-scrap/chunks/asteroid-starship-chunk-normal-4.png",
        size = 128,
        scale = 0.195,
        premul_alpha = false,
        },
        roughness_map = {
            filename =         "__the-reef__/graphics/entity/starship-scrap/chunks/asteroid-starship-chunk-roughness-4.png",
            size = 128,
            scale = 0.195,
            premul_alpha = false,
        }
    },
            {
        color_texture = {
            filename =          "__the-reef__/graphics/entity/starship-scrap/chunks/asteroid-starship-chunk-color-5.png",
            size = 128,
            scale = 0.195,
        },
        normal_map = {
        filename =              "__the-reef__/graphics/entity/starship-scrap/chunks/asteroid-starship-chunk-normal-5.png",
        size = 128,
        scale = 0.195,
        premul_alpha = false,
        },
        roughness_map = {
            filename =         "__the-reef__/graphics/entity/starship-scrap/chunks/asteroid-starship-chunk-roughness-5.png",
            size = 128,
            scale = 0.195,
            premul_alpha = false,
        }
    }
}
scrap_chunk.graphics_set.brightness = scrap_chunk.graphics_set.brightness * 1.5

local scrap_small = table.deepcopy(data.raw["asteroid"]["small-metallic-asteroid"])
scrap_small.name  = "starship-scrap-small"
scrap_small.order = "e[starship-scrap]-b[small]"
scrap_small.graphics_set.variations =
{
    {
        color_texture = {
            filename = "__the-reef__/graphics/entity/starship-scrap/small/asteroid-starship-small-color-1.png",
            size = 512,
            scale = 0.125,
        },
        shadow_shift = { 0.5, 0.5 },
        normal_map = {
            filename = "__the-reef__/graphics/entity/starship-scrap/small/asteroid-starship-small-normal-1.png",
            size = 512,
            scale = 0.125,
            premul_alpha = false,
        },
        roughness_map = {
            filename = "__the-reef__/graphics/entity/starship-scrap/small/asteroid-starship-small-roughness-1.png",
            size = 512,
            scale = 0.125,
            premul_alpha = false,
        }
    }
}
-- Break into starship-scrap-chunk instead of vanilla metallic-asteroid-chunk. Explosion effect left as vanilla metallic for now.
scrap_small.dying_trigger_effect[2].asteroid_name = "starship-scrap-chunk"
scrap_small.graphics_set.brightness = scrap_small.graphics_set.brightness * 1.5

local scrap_medium = table.deepcopy(data.raw["asteroid"]["medium-metallic-asteroid"])
scrap_medium.name  = "starship-scrap-medium"
scrap_medium.order = "e[starship-scrap]-c[medium]"
scrap_medium.graphics_set.variations =
{
    {
        color_texture = {
            filename = "__the-reef__/graphics/entity/starship-scrap/medium/asteroid-starship-medium-color-1.png",
            size = 512,
            scale = 0.125,
        },
        shadow_shift = { 0.75, 0.75 },
        normal_map = {
            filename = "__the-reef__/graphics/entity/starship-scrap/medium/asteroid-starship-medium-normal-1.png",
            size = 512,
            scale = 0.125,
            premul_alpha = false,
        },
        roughness_map = {
            filename = "__the-reef__/graphics/entity/starship-scrap/medium/asteroid-starship-medium-roughness-1.png",
            size = 512,
            scale = 0.125,
            premul_alpha = false,
        }
    },
    {
        color_texture = {
            filename = "__the-reef__/graphics/entity/starship-scrap/medium/asteroid-starship-medium-color-2.png",
            size = 512,
            scale = 0.125,
        },
        shadow_shift = { 0.75, 0.75 },
        normal_map = {
            filename = "__the-reef__/graphics/entity/starship-scrap/medium/asteroid-starship-medium-normal-2.png",
            size = 512,
            scale = 0.125,
            premul_alpha = false,
        },
        roughness_map = {
            filename = "__the-reef__/graphics/entity/starship-scrap/medium/asteroid-starship-medium-roughness-1.png",
            size = 512,
            scale = 0.125,
            premul_alpha = false,
        }
    }
}

-- Break into starship-scrap-small instead of vanilla small-metallic-asteroid. Explosion effect left as vanilla metallic for now.
scrap_medium.dying_trigger_effect[2].entity_name = "starship-scrap-small"
scrap_medium.graphics_set.brightness = scrap_medium.graphics_set.brightness * 1.5

data:extend({ scrap_chunk, scrap_small, scrap_medium })
