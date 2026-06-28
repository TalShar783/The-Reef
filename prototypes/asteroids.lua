-- Starship Scrap Chunk entity — the asteroid-chunk that floats in The Reef's
-- approach corridor and is collected by asteroid collectors.
--
-- Full deepcopy of metallic-asteroid-chunk so ALL required fields are present.
-- Only name, order, and minable are overridden.
-- Replace graphics_set with custom scrap art (jagged metal debris) before release.

local scrap_chunk = table.deepcopy(data.raw["asteroid-chunk"]["metallic-asteroid-chunk"])
scrap_chunk.name    = "starship-scrap-chunk"
scrap_chunk.order   = "e[starship-scrap]-a[chunk]"
scrap_chunk.minable = {
    mining_time     = 0.2,
    result          = "starship-scrap-chunk",
    mining_particle = "metallic-asteroid-chunk-particle-medium",
}

data:extend({ scrap_chunk })
