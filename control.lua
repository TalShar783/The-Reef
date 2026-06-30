-- control.lua: runtime event handlers entry point

-- Ithaca surface tile generation (self-registers its own events on require)
require("scripts.ithaca-surface")

-- Cargo Hatch
local cargo_hatch = require("scripts.cargo-hatch")

-- Basic PMR
local pmr = require("scripts.pmr")

script.on_init(function()
    cargo_hatch.on_init()
    pmr.on_init()
    storage.ithaca_center_patch_placed = false
end)

script.on_event(defines.events.on_research_finished, cargo_hatch.on_research_finished)

-- Register / unregister hatches + PMR on build and removal.
-- script.on_event only allows ONE handler per event, so cargo-hatch and PMR
-- share a single dispatcher per event rather than each calling on_event
-- separately (a second call would silently replace the first handler).
local managed_entity_filter = {
    { filter = "name", name = "cargo-hatch" },
    { filter = "name", name = "advanced-cargo-hatch" },
    { filter = "name", name = "basic-pmr" },
}

local function dispatch_built(event)
    local entity = event.entity or event.created_entity
    if not entity then return end
    if entity.name == "basic-pmr" then
        pmr.on_built(event)
    else
        cargo_hatch.on_built(event)
    end
end

local function dispatch_removed(event)
    local entity = event.entity
    if not entity then return end
    if entity.name == "basic-pmr" then
        pmr.on_removed(event)
    else
        cargo_hatch.on_removed(event)
    end
end

script.on_event(defines.events.on_pre_build,                   cargo_hatch.on_pre_build)
script.on_event(defines.events.on_built_entity,                dispatch_built, managed_entity_filter)
script.on_event(defines.events.on_robot_built_entity,          dispatch_built, managed_entity_filter)
script.on_event(defines.events.on_space_platform_built_entity, dispatch_built, managed_entity_filter)
script.on_event(defines.events.script_raised_built,            dispatch_built, managed_entity_filter)
script.on_event(defines.events.script_raised_revive,           dispatch_built, managed_entity_filter)

script.on_event(defines.events.on_player_mined_entity,         dispatch_removed, managed_entity_filter)
script.on_event(defines.events.on_robot_mined_entity,          dispatch_removed, managed_entity_filter)
script.on_event(defines.events.on_space_platform_mined_entity, dispatch_removed, managed_entity_filter)
script.on_event(defines.events.on_entity_died,                 dispatch_removed, managed_entity_filter)
script.on_event(defines.events.script_raised_destroy,          dispatch_removed, managed_entity_filter)

-- Sync and GUI
-- on_tick only accepts one handler; both modules share a combined dispatcher.
script.on_event(defines.events.on_tick, function(event)
    cargo_hatch.on_tick(event)
    pmr.on_tick(event)
end)
script.on_event(defines.events.on_gui_opened,       cargo_hatch.on_gui_opened)
script.on_event(defines.events.on_gui_closed,       cargo_hatch.on_gui_closed)
script.on_event(defines.events.on_gui_click,           cargo_hatch.on_gui_click)
script.on_event(defines.events.on_gui_elem_changed,    cargo_hatch.on_gui_elem_changed)

-- Phase 5+: attractor and shield scripting
-- require("scripts.attractor")
-- require("scripts.shield")

-- Phase 6+: railgun cross-surface transfer
-- require("scripts.railgun")
