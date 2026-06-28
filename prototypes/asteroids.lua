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
data:extend({ scrap_chunk })
