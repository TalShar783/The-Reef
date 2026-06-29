-- control.lua: runtime event handlers entry point

-- Ithaca surface tile generation (self-registers its own events on require)
require("scripts.ithaca-surface")

-- Cargo Hatch
local cargo_hatch = require("scripts.cargo-hatch")

script.on_init(function()
    cargo_hatch.on_init()
    storage.ithaca_center_patch_placed = false
end)

-- Register / unregister hatches on build and removal.
-- Event filters mean the handler only fires for cargo-hatch entities.
local hatch_filter = {{ filter = "name", name = "cargo-hatch" }}

script.on_event(defines.events.on_built_entity,        cargo_hatch.on_built,   hatch_filter)
script.on_event(defines.events.on_robot_built_entity,  cargo_hatch.on_built,   hatch_filter)
script.on_event(defines.events.script_raised_built,    cargo_hatch.on_built,   hatch_filter)
script.on_event(defines.events.script_raised_revive,   cargo_hatch.on_built,   hatch_filter)

script.on_event(defines.events.on_player_mined_entity, cargo_hatch.on_removed, hatch_filter)
script.on_event(defines.events.on_robot_mined_entity,  cargo_hatch.on_removed, hatch_filter)
script.on_event(defines.events.on_entity_died,         cargo_hatch.on_removed, hatch_filter)
script.on_event(defines.events.script_raised_destroy,  cargo_hatch.on_removed, hatch_filter)

-- Sync and GUI
script.on_event(defines.events.on_tick,                cargo_hatch.on_tick)
script.on_event(defines.events.on_gui_opened,       cargo_hatch.on_gui_opened)
script.on_event(defines.events.on_gui_closed,       cargo_hatch.on_gui_closed)
script.on_event(defines.events.on_gui_click,           cargo_hatch.on_gui_click)
script.on_event(defines.events.on_gui_elem_changed,    cargo_hatch.on_gui_elem_changed)

-- Phase 5+: attractor and shield scripting
-- require("scripts.attractor")
-- require("scripts.shield")

-- Phase 6+: railgun cross-surface transfer
-- require("scripts.railgun")
