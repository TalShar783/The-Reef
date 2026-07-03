# Space Platforms — Verified Mechanics & APIs

Space platforms are not planet surfaces. Do not carry surface assumptions onto them.

## What does NOT exist on platforms

- **No logistic network at all**: no roboports, no construction/logistic robots, no logistic chests.
- **No vanilla chests**: Space Age data-updates adds `surface_conditions = { { property = "gravity", min = 0.1 } }` to every vanilla container. Any custom container meant for platforms must explicitly allow gravity 0 (and copies of vanilla containers made in `data.lua` must set `surface_conditions` themselves — see constraints.md § deepcopy timing).
- **No rockets/cargo pods between two platforms**: pods travel platform ↔ planet surface only.

## How platform inventory works

- The `space-platform-hub` entity holds the platform's shared cargo inventory; inserters push/pull against it directly.
- Machines and inserters with "enable logistic connection" read the hub's contents wirelessly (the hub replaces the logistic network as the readable inventory).
- Script access (both verified):
  - `platform.hub` — `LuaSpacePlatform` attribute returning the hub entity (runtime-api.json).
  - `surface.find_entities_filtered({ type = "space-platform-hub" })[1]` — equivalent, production-tested.
  - Hub inventory: `hub.get_inventory(defines.inventory.hub_main)` (`hub_trash` also exists).
- `LuaSpacePlatform` has **no** `cargo_inventory` attribute — accessing it throws (C++ objects throw on unknown keys).

## Platform-to-platform transfer (2.1)

Platforms in orbit of the same body can request items from each other via the orbital request system. This is the **only** platform-to-platform mechanism — no rockets or pods involved.

## Non-landable space locations

`space-location` prototypes (Shattered Planet style) have no surface: no landing, no building, no cargo rockets. Platforms park there and interact with the location's asteroid/resource mechanics from orbit.

## LuaSpacePlatform (verified member list, 2.1.8)

- Attributes: `damaged_tiles`, `distance`, `ejected_items`, `force`, `hidden`, `hub`, `index`, `last_visited_space_location`, `name`, `paused`, `schedule`, `scheduled_for_deletion`, `space_connection`, `space_location`, `speed`, `starter_pack`, `state`, `surface`, `valid`, `weight`
- Methods: `apply_starter_pack`, `can_leave_current_location`, `cancel_deletion`, `clear_ejected_items`, `create_asteroid_chunks`, `damage_tile`, `destroy`, `destroy_asteroid_chunks`, `eject_item`, `find_asteroid_chunks_filtered`, `get_schedule`, `repair_tile`
- Note the **runtime asteroid-chunk APIs**: `create_asteroid_chunks` / `find_asteroid_chunks_filtered` / `destroy_asteroid_chunks` — asteroid manipulation at runtime does not require data-stage spawn definitions.

## Platform events (verified list, runtime-api.json 2.1.8)

`on_space_platform_built_entity` (entity, platform, stack, tags), `on_space_platform_built_tile`, `on_space_platform_changed_state` (platform, old_state), `on_space_platform_mined_entity` (buffer, entity, platform — buffer valid this tick only), `on_space_platform_mined_item`, `on_space_platform_mined_tile`, `on_space_platform_pre_mined`.

Remember platforms build and mine things **without** a player or robot: any `on_built_entity`/`on_robot_built_entity` handler pair needs the `on_space_platform_built_entity` sibling (and likewise for mining) or platform actions are silently missed.

Cargo pod events for surface ↔ platform transfer: `on_cargo_pod_started_ascending`, `on_cargo_pod_finished_ascending`, `on_cargo_pod_finished_descending`, `on_cargo_pod_delivered_cargo` (spawned_container).
