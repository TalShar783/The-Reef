-- Fluid PMR: 3x3 building that accepts up to 5 different fluids through a
-- single external pipe connection, routing each fluid to its own isolated
-- internal storage. See PMR_handoff.md (repo root, one level up) for the
-- full design rationale.
--
-- Four entities share one tile position (the shell's), created together by
-- scripts/fluid-pmr.lua on_built:
--   1. fluid-pmr             — visible 3x3 shell, no fluid box at all.
--   2. fluid-pmr-intake-tank — hidden storage-tank, one connection facing
--      the intake pump only. Accepts whatever fluid the pump lets through.
--   3. fluid-pmr-intake-pump — hidden pump, sits one tile west of the shell
--      center. Its west port is the assembly's only externally-reachable
--      pipe connection; its east port feeds the intake tank. Circuit-gated
--      by script (enabled only while the intake tank is empty) so the
--      external network can never push a second fluid in before the first
--      has been fully drained to a sub-tank.
--   4. fluid-pmr-subtank-<fluid> (x5) — hidden storage-tanks with NO pipe
--      connections at all, one per supported fluid. Never touch the fluid
--      network; only ever written to via entity.add_fluid() from script.
--
local FLUID_PMR_FLUIDS = require("constants.fluid-pmr")

-- ─── 1. Shell ────────────────────────────────────────────────────────────────
-- Purely cosmetic/structural. No fluid_box, so zero ambiguity about it
-- interacting with the fluid system. Placeholder graphics inherited from the
-- base game's generic simple-entity-with-owner (iron-chest sprite) — replace
-- with custom art before release.

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

data:extend({ shell })

-- ─── 2. Intake tank ──────────────────────────────────────────────────────────
-- Single connection faces the intake pump's east/output port (see pump
-- section below for the shared-coordinate derivation). No connection is
-- exposed to the outside world directly — the pump is the only gatekeeper.

local intake_tank = table.deepcopy(data.raw["storage-tank"]["storage-tank"])
intake_tank.name           = "fluid-pmr-intake-tank"
intake_tank.minable        = nil
intake_tank.collision_mask = { layers = {} }
intake_tank.hidden         = true
intake_tank.flags          = { "not-on-map", "placeable-off-grid", "not-blueprintable", "not-deconstructable" }
intake_tank.fluid_box.pipe_connections = {
    { direction = defines.direction.west, position = { -0.5, 0 }, flow_direction = "input" },
}

data:extend({ intake_tank })

-- ─── 3. Intake pump ──────────────────────────────────────────────────────────
-- Placed one tile west of the shell's center by the control-stage script.
-- West port (world position = shell_position + {-1.5, 0}, i.e. the west edge
-- of the 3x3 footprint) is where a real external pipe auto-connects. East
-- port (world position = shell_position + {-0.5, 0}) meets the intake tank's
-- own west-facing connection, since the tank is placed at the shell's exact
-- center — same world coordinate, opposite directions, per standard pipe
-- connection matching rules.
-- circuit_connector is inherited from the pump deepcopy; scripts/fluid-pmr.lua
-- wires it to the intake tank's circuit_connector and sets a circuit_condition
-- of signal-everything == 0 so the pump only runs while the tank is empty.

local intake_pump = table.deepcopy(data.raw["pump"]["pump"])
intake_pump.name           = "fluid-pmr-intake-pump"
intake_pump.minable        = nil
intake_pump.collision_mask = { layers = {} }
intake_pump.hidden         = true
intake_pump.flags          = { "not-on-map", "placeable-off-grid", "not-blueprintable", "not-deconstructable" }
intake_pump.fluid_box.pipe_connections = {
    { direction = defines.direction.west, position = { -0.5, 0 }, flow_direction = "input" },
    { direction = defines.direction.east, position = { 0.5, 0 },  flow_direction = "output" },
}

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

    data:extend({ subtank })
end
