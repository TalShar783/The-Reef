-- Basic PMR belt I/O.
--
-- The PMR has no native belt connection (plain assembling-machine deepcopy).
-- Two invisible pmr-belt-loader entities give it belt I/O: one on the south
-- tile in "input" mode, one on the north tile in "output" mode.
--
-- Direction convention: for both loader_types, `direction` points AWAY from
-- the connected container, toward the continuing belt.
--   south (input)  loader: direction = south (arrow points further south, container north = PMR)
--   north (output) loader: direction = north (arrow points further north, container south = PMR)
--
-- Fixed south-in/north-out for now. Full rotation deferred until PMR sprite
-- can actually be rotated.

local M = {}

local SOUTH_OFFSET = { 0, 1 }
local NORTH_OFFSET = { 0, -1 }

local BELT_TYPES = { "transport-belt", "underground-belt", "splitter", "loader", "loader-1x1", "linked-belt" }

function M.on_init()
    storage.pmr_loaders = storage.pmr_loaders or {}   -- unit_number -> { input = LuaEntity, output = LuaEntity }
end

-- ─── Loader spawn / despawn ──────────────────────────────────────────────────

local function spawn_loader(pmr, offset, direction, loader_type)
    local surface = pmr.surface
    local pos = { x = pmr.position.x + offset[1], y = pmr.position.y + offset[2] }

    -- A real belt run may already occupy this tile; clear it so the loader
    -- can take its place. The loader is belt-connectable, so the run still
    -- functions — the loader is the final segment bridging belt to machine.
    local existing = surface.find_entities_filtered({ position = pos, type = BELT_TYPES })[1]
    if existing then existing.destroy() end

    local loader = surface.create_entity{
        name      = "pmr-belt-loader",
        position  = pos,
        direction = direction,
        force     = pmr.force,
        create_build_effect_smoke = false,
    }
    if not loader then return nil end

    loader.loader_type  = loader_type
    loader.destructible = false

    return loader
end

local function spawn_pmr_loaders(entity)
    storage.pmr_loaders = storage.pmr_loaders or {}
    storage.pmr_loaders[entity.unit_number] = {
        -- direction always points AWAY from the PMR (toward the continuing belt)
        input  = spawn_loader(entity, SOUTH_OFFSET, defines.direction.south, "input"),
        output = spawn_loader(entity, NORTH_OFFSET, defines.direction.north, "output"),
    }
end

local function destroy_pmr_loaders(unit_number)
    storage.pmr_loaders = storage.pmr_loaders or {}
    local pair = storage.pmr_loaders[unit_number]
    if not pair then return end
    if pair.input  and pair.input.valid  then pair.input.destroy()  end
    if pair.output and pair.output.valid then pair.output.destroy() end
    storage.pmr_loaders[unit_number] = nil
end

-- ─── Build / remove ──────────────────────────────────────────────────────────

function M.on_built(event)
    local entity = event.entity or event.created_entity
    if not entity or entity.name ~= "basic-pmr" then return end
    spawn_pmr_loaders(entity)
end

function M.on_removed(event)
    local entity = event.entity
    if not entity or entity.name ~= "basic-pmr" then return end
    destroy_pmr_loaders(entity.unit_number)
end

return M
