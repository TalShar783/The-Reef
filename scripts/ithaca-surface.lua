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
