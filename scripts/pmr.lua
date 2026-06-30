-- Basic PMR belt I/O.
--
-- The PMR has no native belt connection (plain assembling-machine deepcopy).
-- Two hidden loader-1x1 entities give it belt I/O: one on the south tile in
-- "input" mode (pulls from the belt south of the PMR into the PMR), one on
-- the north tile in "output" mode (pushes PMR output onto the belt north of
-- it). Both share direction = north, since "direction" means "the belt-side
-- flow direction" and the whole south->PMR->north line flows north.
--
-- Fixed south-in/north-out for now. Full rotation (output always opposite
-- input, any of the 4 facings) is deferred until the PMR's chest-derived
-- sprite can actually be rotated.

local M = {}

local SOUTH_OFFSET = { 0, 1 }
local NORTH_OFFSET = { 0, -1 }

local BELT_TYPES = { "transport-belt", "underground-belt", "splitter", "loader", "loader-1x1", "linked-belt" }

function M.on_init()
    storage.pmr_loaders = storage.pmr_loaders or {}   -- unit_number -> { input = LuaEntity, output = LuaEntity }
end

-- ─── Loader spawn / despawn ──────────────────────────────────────────────────

local function spawn_loader(pmr, offset, loader_type)
    local surface = pmr.surface
    local pos = { x = pmr.position.x + offset[1], y = pmr.position.y + offset[2] }

    -- A real belt run may already occupy this tile (the player builds belts
    -- right up to the machine); clear it so the loader can take its place.
    -- The loader is itself belt-connectable, so the run still functions.
    local existing = surface.find_entities_filtered({ position = pos, type = BELT_TYPES })[1]
    if existing then existing.destroy() end

    local loader = surface.create_entity{
        name      = "loader-1x1",
        position  = pos,
        direction = defines.direction.north,
        force     = pmr.force,
        create_build_effect_smoke = false,
    }
    if not loader then return nil end

    loader.loader_type   = loader_type
    loader.destructible   = false

    return loader
end

local function spawn_pmr_loaders(entity)
    storage.pmr_loaders = storage.pmr_loaders or {}
    storage.pmr_loaders[entity.unit_number] = {
        input  = spawn_loader(entity, SOUTH_OFFSET, "input"),
        output = spawn_loader(entity, NORTH_OFFSET, "output"),
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
