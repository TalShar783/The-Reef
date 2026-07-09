# Space Age Runtime API Reference — The Reef Mod

Generated from provided source material only. Gaps where the source does not contain the relevant information are called out explicitly rather than filled from training data.

---

## 1. Space Platform Events

All events with the `on_space_platform_` prefix found in the source. Every event includes a `name: defines.events` and `tick: MapTick` parameter; those are omitted from the per-event parameter lists below for brevity.

### `on_space_platform_built_entity`
Called when a space platform builds an entity.

| Parameter | Type | Notes |
|-----------|------|-------|
| `entity` | `LuaEntity` | The entity that was built |
| `platform` | `LuaSpacePlatform` | The platform that built it |
| `stack` | `LuaItemStack` | The item used to build |
| `tags` | `Tags` | Blueprint tags, if any |

### `on_space_platform_built_tile`
Called after a space platform builds tiles.

| Parameter | Type |
|-----------|------|
| `inventory` | `LuaInventory` |
| `item` | `LuaItemPrototype` |
| `platform` | `LuaSpacePlatform` |
| `quality` | `LuaQualityPrototype` |
| `surface_index` | `uint32` |
| `tile` | `LuaTilePrototype` |
| `tiles` | `array[OldTileAndPosition]` |

### `on_space_platform_changed_state`
Called when a space platform changes state (e.g., traveling, waiting at a planet).

| Parameter | Type |
|-----------|------|
| `old_state` | `defines.space_platform_state` |
| `platform` | `LuaSpacePlatform` |

### `on_space_platform_mined_entity`
Called after the results of an entity being mined are collected, just before the entity is destroyed. The buffer inventory is only valid during this event.

| Parameter | Type |
|-----------|------|
| `buffer` | `LuaInventory` |
| `entity` | `LuaEntity` |
| `platform` | `LuaSpacePlatform` |

### `on_space_platform_mined_item`
Called when a platform mines an entity (item-level callback).

| Parameter | Type |
|-----------|------|
| `item_stack` | `ItemWithQualityCount` |
| `platform` | `LuaSpacePlatform` |

### `on_space_platform_mined_tile`
Called after a platform mines tiles.

| Parameter | Type |
|-----------|------|
| `platform` | `LuaSpacePlatform` |
| `surface_index` | `uint32` |
| `tiles` | `array[OldTileAndPosition]` |

### `on_space_platform_pre_mined`
Called before a platform mines an entity.

| Parameter | Type |
|-----------|------|
| `entity` | `LuaEntity` |
| `platform` | `LuaSpacePlatform` |

---

## 2. LuaSpacePlatform

**Not covered in the provided source material.** The source only shows `platform: LuaSpacePlatform` as an event parameter type — no methods, attributes, or full API listing for `LuaSpacePlatform` appear in any of the provided source files. Do not use this section as a method reference; consult the official Factorio Lua API docs directly.

---

## 3. Asteroid Spawning — `asteroid_spawn_definitions`

### Data-stage structure

The authoritative source is `__space-age__/prototypes/planet/asteroid-spawn-definitions.lua` (aliased as `asteroid_util` in mod code).

**Input data table shape** (e.g., `asteroid_util.gleba_fulgora`):

```lua
{
  probability_on_range_chunk  = { {position, probability, angle_when_stopped}, ... },
  probability_on_range_small  = { ... },   -- optional
  probability_on_range_medium = { ... },   -- optional
  probability_on_range_big    = { ... },   -- optional
  probability_on_range_huge   = { ... },   -- optional
  type_ratios = {
    {position, ratios = {metallic, carbonic, oxide [, promethium]}},
    ...
  },
  has_promethium_asteroids = true,  -- optional; enables promethium type
}
```

**`asteroid_util.spawn_definitions(data, planet)`**

Returns `asteroid_spawn_definitions` — an array suitable for assigning to a `space-connection` or `planet` prototype field.

| Parameter | Type | Notes |
|-----------|------|-------|
| `data` | table | Route data table (e.g., `asteroid_util.gleba_fulgora`) |
| `planet` | number or nil | If `nil`, returns full spawn-point curves along the route. If a number (a position value, 0–1), returns a flat list for that fixed orbital position. |

**Return value shape per entry (route mode, `planet == nil`):**
```lua
{
  asteroid       = "<size>-<type>-asteroid" or "<type>-asteroid-chunk",
  type           = "asteroid-chunk",   -- only for chunk-size entries
  spawn_points   = {
    { distance, probability, speed, angle_when_stopped },
    ...
  }
}
```

**Return value shape per entry (planet mode, `planet ~= nil`):**
```lua
{
  asteroid          = "<size>-<type>-asteroid",
  probability       = <float>,
  speed             = <float>,
  angle_when_stopped = <float>,
  type              = "asteroid-chunk",   -- only for chunks
}
```

**Known pre-built route tables in the source:**
- `asteroid_util.nauvis_vulcanus`
- `asteroid_util.nauvis_gleba`
- `asteroid_util.nauvis_fulgora`
- `asteroid_util.vulcanus_gleba`
- `asteroid_util.gleba_fulgora`
- `asteroid_util.gleba_aquilo`
- `asteroid_util.fulgora_aquilo`
- `asteroid_util.aquilo_solar_system_edge`
- `asteroid_util.shattered_planet_trip` (includes `has_promethium_asteroids = true`)

**Usage on a planet/space-location prototype (fixed orbital position):**
```lua
asteroid_spawn_definitions = asteroid_util.spawn_definitions(asteroid_util.gleba_fulgora, 0.9)
-- planet = 0.9 returns a flat list for a fixed orbital position
```

**Usage on a space-connection (full route):**
```lua
asteroid_spawn_definitions = asteroid_util.spawn_definitions(asteroid_util.gleba_aquilo)
-- planet = nil returns full route curves
```

### Runtime hooks for modifying asteroid spawns

**Not present in the provided source material.** No runtime event or API for intercepting or modifying asteroid spawns mid-flight appears in any of the source files. Spawn definitions are prototype-stage (data-phase) only based on what is shown.

---

## 4. Cross-Surface Item Transfer

### Cargo pod events (from Factorio runtime API source)

The mechanism visible in the source for surface-to-platform item movement is the cargo pod event set:

| Event | Key Parameters | Description |
|-------|----------------|-------------|
| `on_cargo_pod_started_ascending` | `cargo_pod: LuaEntity`, `player_index: uint32` | Pod departs from a space platform hub or similar. |
| `on_cargo_pod_finished_ascending` | `cargo_pod: LuaEntity`, `launched_by_rocket: boolean`, `player_index: uint32` | Pod departs a surface. |
| `on_cargo_pod_finished_descending` | `cargo_pod: LuaEntity`, `launched_by_rocket: boolean`, `player_index: uint32` | Pod lands on a surface, at a station or on the ground. |
| `on_cargo_pod_delivered_cargo` | `cargo_pod: LuaEntity`, `spawned_container: LuaEntity` | Fired after the pod has delivered its cargo. |

### Script-driven transfer patterns

**No script-driven inter-surface transfer implementation is documented here.** The cargo
pod events above are the engine-level mechanism visible in the source. For anything
beyond them (teleporter-style transfers), design from the Factorio runtime API docs
directly.

---

## 5. LuaSurface Inventory APIs

The provided source lists LuaSurface method names but the listing is truncated and **does not include inventory insert/remove methods**. The methods shown are:

`add_script_area`, `add_script_position`, `build_checkerboard`, `build_enemy_base`, `calculate_tile_properties`, `can_fast_replace`, `can_place_entity`, `cancel_deconstruct_area`, `cancel_upgrade_area`, `clear`, `clear_hidden_tiles`, `clear_pollution`, `clear_territory_for_chunks`, `clone_area`, `clone_brush`, `clone_entities`, `count_entities_filtered` (list truncated in source).

**No `insert_item`, `remove_item`, or equivalent methods appear in the provided LuaSurface source.** Platform inventory access is exercised through `LuaInventory` objects surfaced via events (e.g., the `buffer` parameter in `on_space_platform_mined_entity`, or the `inventory` parameter in `on_space_platform_built_tile`). `LuaInventory` methods are **not listed in the provided source**.

---

## 6. `on_entity_damaged`

Called when an entity is damaged. **Not called when an entity's health is set directly by another mod.**

| Parameter | Type | Notes |
|-----------|------|-------|
| `entity` | `LuaEntity` | The entity that was damaged |
| `cause` | `LuaEntity` | Entity that caused the damage (e.g., projectile, enemy) |
| `source` | `LuaEntity` | Source entity (e.g., the turret that fired) |
| `force` | `LuaForce` | Force that dealt the damage |
| `damage_type` | `LuaDamagePrototype` | Type of damage dealt |
| `original_damage_amount` | `float` | Damage before armor/resistances |
| `final_damage_amount` | `float` | Damage after armor/resistances |
| `final_health` | `float` | Entity health after the damage is applied |
| `name` | `defines.events` | |
| `tick` | `MapTick` | |

**Shield-style scripting use:** listen for `on_entity_damaged`, inspect `final_health` and `final_damage_amount`, then heal or destroy the entity or redirect damage as needed. The `entity` field is the target; `cause` and `source` identify the attacker chain.

---

## 7. Common `on_tick` Patterns

### `on_tick` event signature

| Parameter | Type |
|-----------|------|
| `name` | `defines.events` |
| `tick` | `MapTick` |

The source notes: *"It is fired once every tick. Since this event is fired every tick, its handler shouldn't include performance heavy code."*

### Patterns

The only pattern that can be stated from source is the standard registration form used by all Factorio mods:

```lua
script.on_event(defines.events.on_tick, function(event)
    -- event.tick is the current game tick
end)
```

For throttling patterns (per-tick budgets, resumable cursors, `on_nth_tick`, flib's
`on-tick-n`), see runtime-discipline.md §6.
