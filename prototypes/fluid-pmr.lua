-- Fluid PMR: 3x3 building that accepts up to 5 different fluids through a
-- single external pipe connection, routing each fluid to its own isolated
-- internal storage. See PMR_handoff.md (repo root, one level up) for the
-- full design rationale.
--
-- Three entities share one tile position (the shell's), created together by
-- scripts/fluid-pmr.lua on_built:
--   1. fluid-pmr — visible 3x3 shell. This IS the intake tank: a real
--      storage-tank with NO pipe_connections (sealed, fed by script from the
--      intake pump's fluidbox rather than a real engine link), a working
--      circuit_connector (for pump gating and the sub-tank read-contents
--      wire), and a custom GUI (see scripts/fluid-pmr.lua) replacing the
--      default storage-tank window. Visible/selectable/minable — the one
--      entity the player actually sees, clicks, mines, and wires up.
--      (Originally split into a cosmetic shell + a separate hidden intake
--      tank; merged after discovering simple-entity-with-owner supports
--      neither fluid_box nor circuit_connector, so it couldn't be made
--      clickable/wireable while staying a distinct visual-only entity.)
--   2. fluid-pmr-intake-pump — hidden pump, sits one tile west of the shell
--      center. Its single west port is the assembly's only real, externally-
--      reachable pipe connection. No internal engine connection to the
--      shell's fluidbox — script moves fluid from the pump's own fluidbox
--      into the shell. Circuit-gated (enabled only while the shell's
--      fluidbox is empty) so the external network can never push a second
--      fluid in before the first has been fully drained to a sub-tank.
--   3. fluid-pmr-subtank-<fluid> (x5) — hidden storage-tanks with NO pipe
--      connections at all, one per supported fluid. Never touch the fluid
--      network; only ever written to via entity.add_fluid() from script.
--
local FLUID_PMR_FLUIDS = require("constants.fluid-pmr")

-- ─── 1. Shell / intake tank ──────────────────────────────────────────────────
-- See header comment above — this single entity plays both roles.

local shell = table.deepcopy(data.raw["storage-tank"]["storage-tank"])
shell.name          = "fluid-pmr"
shell.icon          = "__space-age__/graphics/icons/shattered-planet.png"
shell.icon_size     = 64
shell.hidden        = false
shell.subgroup      = "the-reef-machines"
shell.order         = "a[pmr]-c"
shell.minable       = { mining_time = 1, result = "fluid-pmr" }
shell.collision_box = {{ -1.4, -1.4 }, { 1.4, 1.4 }}
shell.selection_box = {{ -1.5, -1.5 }, { 1.5, 1.5 }}
shell.fast_replaceable_group = nil  -- prevent fast-replace with vanilla storage tanks
shell.fluid_box.pipe_connections = {}

data:extend({ shell })

-- ─── 2. Intake pump ──────────────────────────────────────────────────────────
-- Placed one tile west of the shell's center by the control-stage script.
-- Its single west port (world position = shell_position + {-1.5, 0}, the
-- west edge of the 3x3 footprint) is the assembly's only real, externally-
-- reachable pipe connection. There is no second (internal) engine connection
-- to the shell's fluidbox — the pump's own fluidbox just accumulates fluid
-- from the network up to its own capacity, and scripts/fluid-pmr.lua reads
-- it out via get_fluid/remove_fluid straight into the shell, the same way it
-- already moves fluid from the shell into a sub-tank.
-- collision_box is widened (harmless — collision_mask is empty, so it never
-- actually collides with anything) so the west connection point sits inside
-- the prototype's declared bounding box.
-- circuit_connector is inherited from the pump deepcopy; scripts/fluid-pmr.lua
-- wires it to the shell's circuit_connector and sets a circuit_condition of
-- signal-everything == 0 so the pump only runs while the shell is empty.

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

-- ─── 3. Hidden sub-tanks ─────────────────────────────────────────────────────
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
