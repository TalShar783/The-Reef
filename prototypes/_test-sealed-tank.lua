-- TEMPORARY TEST FILE — delete once the sealed-fluid-box / add_fluid question
-- is answered (see docs/common-errors.md entry "add_fluid silently discards
-- fluid added to sealed fluid boxes"). Not part of the mod's real content.
--
-- Purpose: reproduce the exact shape planned for the new Fluid PMR's hidden
-- sub-tanks (storage-tank deepcopy, pipe_connections = {}, filter set) so we
-- can confirm in-sandbox whether entity.add_fluid()/get_fluid() actually
-- works on a sealed box in the current game version, before committing the
-- real design to it.

local test_tank = table.deepcopy(data.raw["storage-tank"]["storage-tank"])
test_tank.name              = "fluid-pmr-test-sealed-tank"
test_tank.icon              = "__space-age__/graphics/icons/shattered-planet.png"
test_tank.icon_size         = 64
test_tank.minable           = nil  -- editor-only probe, not mined by a player
test_tank.collision_mask    = { layers = {} }
test_tank.flags             = { "not-on-map", "placeable-off-grid" }
test_tank.fluid_box = {
    volume           = 1000,
    filter           = "water",
    pipe_connections = {},
}

data:extend({ test_tank })
