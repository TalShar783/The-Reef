-- Ithaca surface tile placement.
--
-- Uses smooth value noise (fBm) + domain warping for organic, irregular shapes.
-- Sine waves at fixed frequencies were replaced because they produce visible
-- repeating patterns — fBm gives multi-scale, chaotic variation.
--
-- Tuning knobs at the top:

local STATION_RADIUS    = 64   -- base station pad radius (tiles)
local EDGE_RAGGEDNESS   = 20   -- max deviation at station edge (tiles); larger = more beat-up
local ISLAND_GRID_SIZE  = 35   -- grid cell size for island centers (~80% sparser than before)
local ISLAND_DENSITY    = 0.09 -- fraction of cells with islands (~80% less than before)
local ISLAND_MAX_RADIUS = 10   -- max island radius (tiles)
local ISLAND_WARP       = 0.6  -- island shape irregularity (0 = circle, 1 = very jagged)
local ISLAND_EXCLUSION  = 20   -- clear gap between station edge and nearest island

-- ─── Noise primitives ───────────────────────────────────────────────────────

-- Hash: maps two floats to a pseudo-random value in [0, 1).
local function hash(a, b)
    local v = math.sin(a * 127.1 + b * 311.7) * 43758.5453
    return v - math.floor(v)
end

-- Smooth value noise: bilinear interpolation over a hash grid with smoothstep.
local function vnoise(x, y)
    local ix, iy = math.floor(x), math.floor(y)
    local fx, fy = x - ix, y - iy
    local ux = fx * fx * (3 - 2 * fx)   -- smoothstep
    local uy = fy * fy * (3 - 2 * fy)
    local a = hash(ix,   iy  )
    local b = hash(ix+1, iy  )
    local c = hash(ix,   iy+1)
    local d = hash(ix+1, iy+1)
    return a + (b-a)*ux + (c-a)*uy + (a-b-c+d)*ux*uy
end

-- Fractal Brownian Motion: 4 octaves of value noise, result in [~0, 1].
local function fbm(x, y)
    return vnoise(x,       y      ) * 0.500
         + vnoise(x * 2.1, y * 2.1) * 0.250
         + vnoise(x * 4.3, y * 4.3) * 0.125
         + vnoise(x * 8.7, y * 8.7) * 0.063
end

-- ─── Station edge ────────────────────────────────────────────────────────────

-- Returns a signed offset applied to the station radius at position (x, y).
-- fBm with a moderate scale creates large dents and small bumps simultaneously.
local function edge_noise(x, y)
    return (fbm(x * 0.04, y * 0.04) - 0.5) * EDGE_RAGGEDNESS * 2
end

-- ─── Island placement ────────────────────────────────────────────────────────

-- Returns true if (x, y) falls inside a scattered island fragment.
-- Islands are placed on a jittered grid; each cell independently decides
-- whether it hosts an island, its center, and its base radius.
-- The shape is then domain-warped so islands look amoeba-like, not circular.
local function is_island(x, y)
    local gx = math.floor(x / ISLAND_GRID_SIZE)
    local gy = math.floor(y / ISLAND_GRID_SIZE)

    for dgx = -1, 1 do
        for dgy = -1, 1 do
            local cx = gx + dgx
            local cy = gy + dgy

            -- Does this cell contain an island?
            if hash(cx * 3.7 + 0.5, cy * 6.1 + 1.3) < ISLAND_DENSITY then
                -- Jitter center within the cell
                local jx = cx * ISLAND_GRID_SIZE
                         + math.floor(hash(cx + 0.1, cy + 0.2) * ISLAND_GRID_SIZE)
                local jy = cy * ISLAND_GRID_SIZE
                         + math.floor(hash(cx + 0.3, cy + 0.4) * ISLAND_GRID_SIZE)

                -- Random base radius: 2 to ISLAND_MAX_RADIUS
                local r = 2 + math.floor(hash(cx + 0.7, cy + 0.9) * (ISLAND_MAX_RADIUS - 1))

                -- Domain-warp the local coordinates for an organic shape.
                -- Two independent fbm samples displace dx and dy.
                local dx = x - jx
                local dy = y - jy
                local s = 0.18   -- noise scale relative to island
                local wdx = dx + (fbm(dx * s + cx * 0.1,       dy * s + cy * 0.1      ) - 0.5) * r * ISLAND_WARP * 2
                local wdy = dy + (fbm(dx * s + cx * 0.1 + 5.3, dy * s + cy * 0.1 + 3.7) - 0.5) * r * ISLAND_WARP * 2

                if wdx * wdx + wdy * wdy <= r * r then
                    return true
                end
            end
        end
    end
    return false
end

-- ─── Chunk handler ───────────────────────────────────────────────────────────

local function on_chunk_generated(event)
    if event.surface.name ~= "ithaca" then return end

    local area  = event.area
    local tiles = {}
    local exclusion_r = STATION_RADIUS + EDGE_RAGGEDNESS + ISLAND_EXCLUSION

    for x = area.left_top.x, area.right_bottom.x - 1 do
        for y = area.left_top.y, area.right_bottom.y - 1 do
            local name
            local dist = math.sqrt(x * x + y * y)
            local effective_r = STATION_RADIUS + edge_noise(x, y)

            if dist <= effective_r then
                name = "space-platform-foundation"
            elseif dist > exclusion_r and is_island(x, y) then
                name = "space-platform-foundation"
            else
                name = "empty-space"
            end

            tiles[#tiles + 1] = { name = name, position = { x, y } }
        end
    end

    event.surface.set_tiles(tiles)
end

script.on_event(defines.events.on_chunk_generated, on_chunk_generated)

-- ─── Debris spawning ─────────────────────────────────────────────────────────
-- Spawns type="asteroid" entities on the station pad. These are stationary but
-- visually spin. When destroyed they drop chunk items via on_entity_died below.
-- (type="asteroid-chunk" cannot be created on planet surfaces — see common-errors.md)
--
-- Tuning:
local SPAWN_INTERVAL   = 300   -- ticks between spawns (every 5 seconds)
local SPAWN_PAD_RADIUS = 55    -- stay inside the station circle

-- Pool maps asteroid entity name → drop item name.
-- Cerys pattern: asteroid entity dies → script spills item, not entity.
local DEBRIS_POOL = {
    { entity = "small-metallic-asteroid", item = "metallic-asteroid-chunk", weight = 6 },
    { entity = "small-carbonic-asteroid", item = "carbonic-asteroid-chunk",  weight = 4 },
    { entity = "small-oxide-asteroid",    item = "oxide-asteroid-chunk",     weight = 2 },
    { entity = "ithaca-scrap-debris",     item = "starship-scrap-chunk",     weight = 2 },
}
local DEBRIS_TOTAL = 14

-- Quick lookup: entity name → item to drop
local DEBRIS_DROPS = {}
for _, entry in ipairs(DEBRIS_POOL) do
    DEBRIS_DROPS[entry.entity] = entry.item
end

local function pick_debris()
    local roll = math.random() * DEBRIS_TOTAL
    local cum  = 0
    for _, entry in ipairs(DEBRIS_POOL) do
        cum = cum + entry.weight
        if roll < cum then return entry.entity end
    end
    return "small-metallic-asteroid"
end

script.on_nth_tick(SPAWN_INTERVAL, function()
    local surface = game.surfaces["ithaca"]
    if not (surface and surface.valid) then return end

    local angle = math.random() * 2 * math.pi
    local dist  = math.random() * SPAWN_PAD_RADIUS
    surface.create_entity({
        name     = pick_debris(),
        position = {
            math.floor(dist * math.cos(angle) + 0.5),
            math.floor(dist * math.sin(angle) + 0.5),
        },
        force = "neutral",
    })
end)

-- ─── Item drops when debris is destroyed ─────────────────────────────────────
-- Mimics Cerys approach: intercept on_entity_died for our asteroid entities on
-- Ithaca, spill the corresponding chunk item. The asteroid's own dying_trigger_effect
-- would attempt create-asteroid-chunk which silently fails on planet surfaces.

script.on_event(defines.events.on_entity_died, function(event)
    local entity = event.entity
    if not (entity and entity.valid) then return end
    if entity.surface.name ~= "ithaca" then return end

    local drop = DEBRIS_DROPS[entity.name]
    if not drop then return end

    entity.surface.spill_item_stack({
        position                  = entity.position,
        stack                     = { name = drop, count = 1 },
        enable_looted             = true,
        force                     = event.force,
        allow_belts               = true,
        max_radius                = 2,
        use_start_position_on_failure = true,
    })
end)

-- ─── Tile restoration ────────────────────────────────────────────────────────
-- When space-platform-foundation tiles are mined on Ithaca, the surface reverts
-- to its map-gen base tile (Nauvis terrain). Immediately replace with empty-space.

local function restore_tiles(surface_index, tiles)
    local surface = game.surfaces[surface_index]
    if not (surface and surface.valid and surface.name == "ithaca") then return end
    local replacements = {}
    for _, t in ipairs(tiles) do
        if t.old_tile and t.old_tile.name == "space-platform-foundation" then
            replacements[#replacements + 1] = { name = "empty-space", position = t.position }
        end
    end
    if #replacements > 0 then
        surface.set_tiles(replacements)
    end
end

script.on_event(defines.events.on_player_mined_tile, function(event)
    restore_tiles(event.surface_index, event.tiles)
end)

script.on_event(defines.events.on_robot_mined_tile, function(event)
    restore_tiles(event.surface_index, event.tiles)
end)
