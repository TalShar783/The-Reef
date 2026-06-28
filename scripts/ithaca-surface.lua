-- Ithaca surface tile placement.
-- Runs on every chunk generated on the "ithaca" surface.
-- Places space-platform-foundation in a circle of STATION_RADIUS tiles
-- centered at (0,0), and empty-space everywhere outside.
-- Players can walk on the station area; empty-space is impassable void.

local STATION_RADIUS = 64  -- tiles from center (~128x128 tile station pad)

local function on_chunk_generated(event)
    if event.surface.name ~= "ithaca" then return end

    local area   = event.area
    local tiles  = {}
    local r2     = STATION_RADIUS * STATION_RADIUS

    for x = area.left_top.x, area.right_bottom.x - 1 do
        for y = area.left_top.y, area.right_bottom.y - 1 do
            local name = (x * x + y * y <= r2) and "space-platform-foundation" or "empty-space"
            tiles[#tiles + 1] = { name = name, position = { x, y } }
        end
    end

    event.surface.set_tiles(tiles)
end

script.on_event(defines.events.on_chunk_generated, on_chunk_generated)
