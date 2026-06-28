-- Ithaca surface tile placement.
--
-- Main station: space-platform-foundation within STATION_RADIUS, ragged edge.
-- Void: empty-space everywhere else, with sparse scattered island fragments.
--
-- Tuning knobs:
--   STATION_RADIUS       main pad radius (tiles from origin)
--   EDGE_RAGGEDNESS      peak deviation of the jagged station edge (tiles)
--   ISLAND_GRID_SIZE     coarse grid cell size for island placement
--   ISLAND_DENSITY       fraction of grid cells that contain an island (0–1)
--   ISLAND_MAX_RADIUS    maximum island radius in tiles (user spec: 10)
--   ISLAND_EXCLUSION     tiles beyond the station edge before islands can appear
--                        (prevents islands from merging with the main pad)

local STATION_RADIUS   = 64
local EDGE_RAGGEDNESS  = 10
local ISLAND_GRID_SIZE = 20
local ISLAND_DENSITY   = 0.45
local ISLAND_MAX_RADIUS = 10
local ISLAND_EXCLUSION = 15   -- clear zone between station edge and first islands

-- Simple hash: maps two floats to a pseudo-random value in [0, 1).
-- Uses the sin-fract trick; fine for visual randomness.
local function hash(a, b)
    local v = math.sin(a * 127.1 + b * 311.7) * 43758.5453
    return v - math.floor(v)
end

-- Ragged offset for the station perimeter.
-- Angle-based so the waviness follows the circle contour naturally.
local function edge_offset(x, y)
    local a = math.atan2(y, x)
    return math.sin(a *  7        ) * 4
         + math.sin(a * 13 + 1.2  ) * 3
         + math.sin(a * 19 - 0.8  ) * 2
         + math.cos(a *  5 + 0.5  ) * 1
end

-- Returns true if (x, y) falls inside a scattered island.
-- Islands are placed on a jittered grid; each cell independently decides
-- whether to host an island and what size (1 to ISLAND_MAX_RADIUS).
local function is_island(x, y)
    local gx = math.floor(x / ISLAND_GRID_SIZE)
    local gy = math.floor(y / ISLAND_GRID_SIZE)

    for dgx = -1, 1 do
        for dgy = -1, 1 do
            local cx = gx + dgx
            local cy = gy + dgy

            -- Does this cell have an island?
            if hash(cx * 3.7 + 0.5, cy * 6.1 + 1.3) < ISLAND_DENSITY then
                -- Jitter the center within the cell
                local jx = cx * ISLAND_GRID_SIZE
                       + math.floor(hash(cx + 0.1, cy + 0.2) * ISLAND_GRID_SIZE)
                local jy = cy * ISLAND_GRID_SIZE
                       + math.floor(hash(cx + 0.3, cy + 0.4) * ISLAND_GRID_SIZE)

                -- Random radius: 2 to ISLAND_MAX_RADIUS
                local r = 2 + math.floor(hash(cx + 0.7, cy + 0.9) * (ISLAND_MAX_RADIUS - 1))

                local dx = x - jx
                local dy = y - jy
                if dx * dx + dy * dy <= r * r then
                    return true
                end
            end
        end
    end
    return false
end

local function on_chunk_generated(event)
    if event.surface.name ~= "ithaca" then return end

    local area  = event.area
    local tiles = {}
    local exclusion_r = STATION_RADIUS + EDGE_RAGGEDNESS + ISLAND_EXCLUSION

    for x = area.left_top.x, area.right_bottom.x - 1 do
        for y = area.left_top.y, area.right_bottom.y - 1 do
            local name
            local dist = math.sqrt(x * x + y * y)
            local pad_edge = STATION_RADIUS + edge_offset(x, y)

            if dist <= pad_edge then
                -- Main station pad
                name = "space-platform-foundation"
            elseif dist > exclusion_r and is_island(x, y) then
                -- Scattered island fragment (outside the clear zone)
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
