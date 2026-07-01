-- Fluid PMR: 3x3 building that accepts up to 5 different fluids through a
-- single external pipe connection, routing each fluid to its own isolated
-- internal storage. See PMR_handoff.md (repo root, one level up) for the
-- full design rationale.
--
-- Four entities share one tile position (the shell's), created together by
-- scripts/fluid-pmr.lua on_built:
--   1. fluid-pmr             — visible 3x3 shell, no fluid box at all.
--   2. fluid-pmr-intake-tank — hidden storage-tank, NO pipe connections.
--      Fed by script from the intake pump's fluidbox, not a real engine link.
--   3. fluid-pmr-intake-pump — hidden pump, sits one tile west of the shell
--      center. Its single west port is the assembly's only real, externally-
--      reachable pipe connection. No internal engine connection to the
--      intake tank — script moves fluid from the pump's own fluidbox into
--      the intake tank. Circuit-gated (enabled only while the intake tank is
--      empty) so the external network can never push a second fluid in
--      before the first has been fully drained to a sub-tank.
--   4. fluid-pmr-subtank-<fluid> (x5) — hidden storage-tanks with NO pipe
--      connections at all, one per supported fluid. Never touch the fluid
--      network; only ever written to via entity.add_fluid() from script.
--
local FLUID_PMR_FLUIDS = require("constants.fluid-pmr")

-- ─── 1. Shell ────────────────────────────────────────────────────────────────
-- Purely cosmetic/structural placeholder. No fluid_box, so zero ambiguity
-- about it interacting with the fluid system. Visible and selectable — the
-- entity the player actually sees, clicks, and mines. Uses the storage-tank
-- sprite (borrowed straight off the storage-tank prototype) so it looks like
-- a tank even though it isn't one.

local shell = table.deepcopy(data.raw["simple-entity-with-owner"]["simple-entity-with-owner"])
shell.name          = "fluid-pmr"
shell.icon          = "__space-age__/graphics/icons/shattered-planet.png"
shell.icon_size     = 64
shell.hidden        = false
shell.subgroup      = "the-reef-machines"
shell.order         = "a[pmr]-c"
shell.minable       = { mining_time = 1, result = "fluid-pmr" }
shell.collision_box = {{ -1.4, -1.4 }, { 1.4, 1.4 }}
shell.selection_box = {{ -1.5, -1.5 }, { 1.5, 1.5 }}
shell.picture = data.raw["storage-tank"]["storage-tank"].pictures.picture

data:extend({ shell })

-- ─── 2. Intake tank ──────────────────────────────────────────────────────────
-- No pipe_connections at all — sealed, same as the sub-tanks. Fluid gets in
-- via scripts/fluid-pmr.lua reading it out of the intake pump's own fluidbox
-- (entity.get_fluid/add_fluid), not through a real engine pipe connection.
-- Its only jobs are (a) staging buffer and (b) circuit_connector content
-- signal for gating the pump — no real fluid network link needed for either.
-- Invisible and unselectable — the shell (above) is the visible/clickable one.

local intake_tank = table.deepcopy(data.raw["storage-tank"]["storage-tank"])
intake_tank.name           = "fluid-pmr-intake-tank"
intake_tank.minable        = nil
intake_tank.collision_mask = { layers = {} }
intake_tank.hidden         = true
intake_tank.flags          = { "not-on-map", "placeable-off-grid", "not-blueprintable", "not-deconstructable" }
intake_tank.fluid_box.pipe_connections = {}
intake_tank.pictures            = nil
intake_tank.selectable_in_game  = false

data:extend({ intake_tank })

-- ─── 3. Intake pump ──────────────────────────────────────────────────────────
-- Placed one tile west of the shell's center by the control-stage script.
-- Its single west port (world position = shell_position + {-1.5, 0}, the
-- west edge of the 3x3 footprint) is the assembly's only real, externally-
-- reachable pipe connection. There is no second (internal) engine connection
-- to the intake tank — the pump's own fluidbox just accumulates fluid from
-- the network up to its own capacity, and scripts/fluid-pmr.lua reads it out
-- via get_fluid/remove_fluid straight into the intake tank, the same way it
-- already moves fluid from the intake tank into a sub-tank.
-- collision_box is widened (harmless — collision_mask is empty, so it never
-- actually collides with anything) so the west connection point sits inside
-- the prototype's declared bounding box.
-- circuit_connector is inherited from the pump deepcopy; scripts/fluid-pmr.lua
-- wires it to the intake tank's circuit_connector and sets a circuit_condition
-- of signal-everything == 0 so the pump only runs while the tank is empty.

local intake_pump = table.deepcopy(data.raw["pump"]["pump"])
intake_pump.name           = "fluid-pmr-intake-pump"
intake_pump.minable        = nil
intake_pump.collision_mask = { layers = {} }
intake_pump.collision_box  = {{ -1, -1 }, { 1, 1 }}
intake_pump.hidden         = true
intake_pump.flags          = { "not-on-map", "placeable-off-grid", "not-blueprintable", "not-deconstructable" }
intake_pump.fluid_box.pipe_connections = {
    { direction = defines.direction.west, position = { -0.5, 0 }, flow_direction = "input" },
}
intake_pump.animations                 = nil
intake_pump.fluid_animation            = nil
intake_pump.glass_pictures             = nil
intake_pump.wagon_connection_graphics  = nil
intake_pump.selectable_in_game         = false

data:extend({ intake_pump })

-- ─── 4. Hidden sub-tanks ─────────────────────────────────────────────────────
-- No pipe_connections at all — never part of any fluid network/segment.
-- filter is set as a belt-and-suspenders check alongside the script-side
-- fluid-name -> sub-tank mapping built in scripts/fluid-pmr.lua.

for _, fluid_name in ipairs(FLUID_PMR_FLUIDS) do
    local subtank = table.deepcopy(data.raw["storage-tank"]["storage-tank"])
    subtank.name           = "fluid-pmr-subtank-" .. fluid_name
    subtank.minable        = nil
    subtank.collision_mask = { layers = {} }
    subtank.hidden         = true
    subtank.flags          = { "not-on-map", "placeable-off-grid", "not-blueprintable", "not-deconstructable" }
    subtank.fluid_box.pipe_connections = {}
    subtank.fluid_box.filter = fluid_name
    subtank.pictures            = nil
    subtank.selectable_in_game  = false

    data:extend({ subtank })
end
