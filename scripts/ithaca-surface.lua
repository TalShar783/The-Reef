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

-- ─── Deposit and chunk configuration ─────────────────────────────────────────

-- Island deposits: fill each island with multiple deposit tiles.
local DEPOSIT_DENSITY = 0.40   -- fraction of islands that get a deposit
local DEPOSIT_MIN     = 300
local DEPOSIT_MAX     = 500

-- Center patch: placed once near the station edge as a starter deposit.
-- ~29 tiles in a radius-3 circle at roughly (50, 20) from station center.
local CENTER_PATCH_X          = 50
local CENTER_PATCH_Y          = 20
local CENTER_PATCH_RADIUS     = 3
local CENTER_PATCH_AMOUNT_MIN = 450
local CENTER_PATCH_AMOUNT_MAX = 550

-- Returns island data for grid cell (cx, cy), or nil.
local function get_island_data(cx, cy)
    if hash(cx * 3.7 + 0.5, cy * 6.1 + 1.3) < ISLAND_DENSITY then
        local jx = cx * ISLAND_GRID_SIZE
               + math.floor(hash(cx + 0.1, cy + 0.2) * ISLAND_GRID_SIZE)
        local jy = cy * ISLAND_GRID_SIZE
               + math.floor(hash(cx + 0.3, cy + 0.4) * ISLAND_GRID_SIZE)
        local r  = 2 + math.floor(hash(cx + 0.7, cy + 0.9) * (ISLAND_MAX_RADIUS - 1))
        return { x = jx, y = jy, r = r }
    end
    return nil
end

-- ─── Chunk handler ───────────────────────────────────────────────────────────
-- Direct (non-deferred): The Reef loads after Alien Biomes alphabetically, so
-- our on_chunk_generated handler is registered second and fires second — we
-- always overwrite whatever Alien Biomes placed.

script.on_event(defines.events.on_chunk_generated, function(event)
    if event.surface.name ~= "ithaca" then return end

    local surface     = event.surface
    local area        = event.area
    local tiles       = {}
    local exclusion_r = STATION_RADIUS + EDGE_RAGGEDNESS + ISLAND_EXCLUSION

    -- ── Tile placement ────────────────────────────────────────────────────────
    for x = area.left_top.x, area.right_bottom.x - 1 do
        for y = area.left_top.y, area.right_bottom.y - 1 do
            local name
            local dist      = math.sqrt(x * x + y * y)
            local eff_r     = STATION_RADIUS + edge_noise(x, y)

            if dist <= eff_r then
                name = "space-platform-foundation"
            elseif dist > exclusion_r and is_island(x, y) then
                name = "space-platform-foundation"
            else
                name = "empty-space"
            end

            tiles[#tiles + 1] = { name = name, position = { x, y } }
        end
    end

    surface.set_tiles(tiles)

    -- ── Center starter patch (placed once) ───────────────────────────────────
    if not storage.ithaca_center_patch_placed then
        local cpx, cpy = CENTER_PATCH_X, CENTER_PATCH_Y
        if cpx >= area.left_top.x and cpx < area.right_bottom.x
        and cpy >= area.left_top.y and cpy < area.right_bottom.y then
            storage.ithaca_center_patch_placed = true
            local r2 = CENTER_PATCH_RADIUS * CENTER_PATCH_RADIUS
            for dx = -CENTER_PATCH_RADIUS, CENTER_PATCH_RADIUS do
                for dy = -CENTER_PATCH_RADIUS, CENTER_PATCH_RADIUS do
                    if dx * dx + dy * dy <= r2 then
                        local amt = CENTER_PATCH_AMOUNT_MIN + math.floor(
                            hash(cpx + dx + 0.3, cpy + dy + 0.7)
                            * (CENTER_PATCH_AMOUNT_MAX - CENTER_PATCH_AMOUNT_MIN)
                        )
                        surface.create_entity({
                            name     = "ithaca-scrap-deposit",
                            position = { cpx + dx, cpy + dy },
                            amount   = amt,
                        })
                    end
                end
            end
        end
    end

    -- ── Island deposits (fill each island) ───────────────────────────────────
    local gx_min = math.floor(area.left_top.x          / ISLAND_GRID_SIZE) - 1
    local gx_max = math.floor((area.right_bottom.x - 1) / ISLAND_GRID_SIZE) + 1
    local gy_min = math.floor(area.left_top.y          / ISLAND_GRID_SIZE) - 1
    local gy_max = math.floor((area.right_bottom.y - 1) / ISLAND_GRID_SIZE) + 1

    for cx = gx_min, gx_max do
        for cy = gy_min, gy_max do
            local island = get_island_data(cx, cy)
            if island and hash(cx + 41.1, cy + 73.7) < DEPOSIT_DENSITY then
                local ix, iy = island.x, island.y
                -- Only trigger when island centre falls in this chunk
                if ix >= area.left_top.x and ix < area.right_bottom.x
                and iy >= area.left_top.y and iy < area.right_bottom.y then
                    -- Fill the island area, staying 2 tiles from the edge
                    local dep_r  = math.max(0, island.r - 2)
                    local dep_r2 = dep_r * dep_r
                    for dx = -dep_r, dep_r do
                        for dy = -dep_r, dep_r do
                            if dx * dx + dy * dy <= dep_r2 then
                                local amt = DEPOSIT_MIN + math.floor(
                                    hash(ix + dx + 0.5, iy + dy + 0.3)
                                    * (DEPOSIT_MAX - DEPOSIT_MIN)
                                )
                                surface.create_entity({
                                    name     = "ithaca-scrap-deposit",
                                    position = { ix + dx, iy + dy },
                                    amount   = amt,
                                })
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- ─── Tile restoration ────────────────────────────────────────────────────────
-- Any mined/deconstructed space-platform-foundation on Ithaca reveals
-- fulgoran-machinery underneath. sprite_usage_surface="fulgora" on that tile
-- is a renderer hint, not a hard placement restriction — testing confirmed it
-- renders acceptably on non-Fulgora surfaces. If it shows as a missing texture,
-- swap to "empty-space" as the fallback.

local function restore_tiles(surface_index, tiles)
    local surface = game.surfaces[surface_index]
    if not (surface and surface.valid and surface.name == "ithaca") then return end
    local replacements = {}
    for _, t in ipairs(tiles) do
        if t.old_tile and t.old_tile.name == "space-platform-foundation" then
            replacements[#replacements + 1] = { name = "fulgoran-machinery", position = t.position }
        end
    end
    if #replacements > 0 then
        surface.set_tiles(replacements)
    end
end

-- ─── Nuclear decorative cleanup ──────────────────────────────────────────────
-- Atomic bombs place nuclear-ground-patch decoratives (not tile replacement).
-- Clear them from Ithaca every second so they don't persist on the station.

script.on_nth_tick(60, function()
    local surface = game.surfaces["ithaca"]
    if not (surface and surface.valid) then return end
    surface.destroy_decoratives({ name = "nuclear-ground-patch" })
end)

script.on_event(defines.events.on_player_mined_tile, function(event)
    restore_tiles(event.surface_index, event.tiles)
end)

script.on_event(defines.events.on_robot_mined_tile, function(event)
    restore_tiles(event.surface_index, event.tiles)
end)
