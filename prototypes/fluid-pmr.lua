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
-- 4. fluid-pmr-crafter — hidden assembling-machine (chemical-plant style:
--    fluid_boxes_off_when_no_fluid_recipe = false), sole user of the
--    "fluid-pmr" crafting category. All fluid boxes are sealed (no
--    pipe_connections) and script-fed from the sub-tanks; it otherwise
--    crafts exactly like a normal assembling machine — vanilla game logic
--    handles multi-batch consumption/production once fluid is staged and a
--    recipe is set. See scripts/fluid-pmr.lua for the selection/feed logic.

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

-- ─── 4. Crafting category + hidden crafter ──────────────────────────────────
-- "fluid-pmr" is strictly one-to-one: fluid-pmr-crafter is the only entity
-- with this crafting category, and every recipe in this category has no
-- other category. Nothing else in the game can craft these recipes, and
-- this crafter can't be assigned anything else.

data:extend({
    { type = "recipe-category", name = "fluid-pmr" },
})

-- Chemical-plant-style base: fluid_boxes_off_when_no_fluid_recipe = false
-- keeps the (invisible, irrelevant) fluid boxes from toggling visibility.
-- All graphics/animation fields are stripped since the entity is hidden and
-- never selectable/rendered — mirrors how the pump and sub-tanks clear their
-- own render fields above. Power draw matches chemical-plant exactly
-- (confirmed from base/prototypes/entity/entities.lua): 210kW electric,
-- secondary-input, 4 pollution/minute.
local crafter = table.deepcopy(data.raw["assembling-machine"]["chemical-plant"])
crafter.name           = "fluid-pmr-crafter"
crafter.minable        = nil
crafter.collision_mask = { layers = {} }
crafter.collision_box  = {{ -1, -1 }, { 1, 1 }}
crafter.hidden         = true
crafter.flags          = { "not-on-map", "placeable-off-grid", "not-blueprintable", "not-deconstructable" }
crafter.selectable_in_game = false
crafter.circuit_connector  = nil
crafter.crafting_categories = { "fluid-pmr" }
crafter.fluid_boxes_off_when_no_fluid_recipe = false
crafter.energy_source = {
    type               = "electric",
    usage_priority     = "secondary-input",
    emissions_per_minute = { pollution = 4 },
}
crafter.energy_usage = "210kW"

-- Three sealed input fluid boxes, matching the test recipe's three fluid
-- ingredients (fluidbox_index 1/2/3 in prototypes/recipes.lua). No
-- pipe_connections — script-fed only, same pattern as the sub-tanks.
crafter.fluid_boxes = {
    { production_type = "input", volume = 25000, pipe_connections = {} },
    { production_type = "input", volume = 25000, pipe_connections = {} },
    { production_type = "input", volume = 25000, pipe_connections = {} },
}

crafter.graphics_set          = nil
crafter.graphics_set_flipped  = nil
crafter.working_visualisations = nil
crafter.water_reflection      = nil
crafter.animation             = nil
crafter.status_colors         = nil

data:extend({ crafter })
