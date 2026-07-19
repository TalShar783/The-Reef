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
    }

}
data:extend({ scrap_chunk })
