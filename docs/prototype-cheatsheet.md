# Prototype Cheatsheet — The Reef (Factorio 2.x / Space Age)

Quick-lookup reference for the prototype types The Reef uses. Derived from Wube's
official base + Space Age data and the Factorio prototype API, plus facts confirmed
directly during The Reef's own load testing. Where a field is marked **unverified**,
check lua-api.factorio.com or `data.raw` before relying on it.

---

## space-location

**Type string:** `"space-location"` — confirmed working during The Reef Phase 1 load
(non-landable destinations like Shattered Planet use this type; landable planets use
`type = "planet"`).

**Via PlanetsLib** (a Reef dependency; recommended for cross-mod compatibility):
```lua
PlanetsLib:extend({ { ... } })
```

**Fields:**

| Field | Type | Notes |
|---|---|---|
| `type` | string | `"space-location"` |
| `name` | string | Unique prototype name |
| `icon` | string | Asset path |
| `icon_size` | uint | Pixels |
| `starmap_icon` | string | Asset path |
| `starmap_icon_size` | uint | Pixels |
| `order` | string | Sort string |
| `distance` | float | **Inside `orbit` only** — PlanetsLib rejects top-level |
| `orientation` | float | **Inside `orbit` only** — PlanetsLib rejects top-level |
| `draw_orbit` | bool | Draw the orbit ring on the starmap |
| `magnitude` | float | Starmap visual size (vanilla planets ≈ 1.0) |
| `solar_power_in_space` | float | Platform solar power in orbit |
| `label_orientation` | float | Label angle around orbit ring |
| `pollutant_type` | string/nil | `nil` disables pollution |
| `asteroid_spawn_influence` | float | Multiplier on asteroid spawns |
| `asteroid_spawn_definitions` | table | See §asteroid-spawn-definitions |
| `surface_properties` | table | See below — relevance to non-landable locations **unverified** |
| `hidden` | bool | Hides the location from the starmap |
| `orbit` | table | Parent/satellite relationship — **required by PlanetsLib** (see common-errors.md) |

**`surface_properties` keys** (values below observed working in Cerys — evidence of a
loadable configuration, not copied code; set your own values. Whether these apply to
non-landable space-locations is **unverified**):
```lua
surface_properties = {
  ["day-night-cycle"] = 72000,   -- ticks
  ["magnetic-field"]  = 120,
  ["solar-power"]     = 120,
  pressure            = 5,
  gravity             = 0.15,    -- reportedly 0.1 is the minimum for chests; verify
  temperature         = 251,
}
```

> **2.x change:** `surface_properties`, `asteroid_spawn_definitions`,
> `asteroid_spawn_influence`, `solar_power_in_space` are all Space Age additions. None
> exist in 1.x planet prototypes.

**Minimal working example (non-landable):**
```lua
local asteroid_util = require("__space-age__.prototypes.planet.asteroid-spawn-definitions")

PlanetsLib:extend({
  {
    type = "space-location",
    name = "the-reef",
    icon = "__the-reef__/graphics/icons/the-reef.png",
    icon_size = 256,
    starmap_icon = "__the-reef__/graphics/icons/starmap-the-reef.png",
    starmap_icon_size = 500,
    order = "e[the-reef]",
    draw_orbit = true,
    magnitude = 0.4,
    solar_power_in_space = 100,
    asteroid_spawn_definitions = asteroid_util.spawn_definitions(asteroid_util.fulgora_aquilo, 0.9),
    orbit = {
      parent = { type = "space-location", name = "star" },
      distance = 12,
      orientation = 0.55,
    },
  }
})
```

---

## space-connection

**Type string:** `"space-connection"`

| Field | Type | Required | Notes |
|---|---|---|---|
| `type` | string | yes | `"space-connection"` |
| `name` | string | yes | |
| `subgroup` | string | yes | `"planet-connections"` (see common-errors.md) |
| `from` | string | yes | Planet/location name |
| `to` | string | yes | Planet/location name |
| `order` | string | yes | |
| `length` | uint | yes | Route length — compare vanilla routes in `data.raw["space-connection"]` for scale |
| `asteroid_spawn_definitions` | table | yes | Route spawns (no second arg = full route) |

**Minimal example:**
```lua
data:extend({
  {
    type = "space-connection",
    name = "fulgora-the-reef",
    subgroup = "planet-connections",
    from = "fulgora",
    to = "the-reef",
    order = "d",
    length = 10000,
    asteroid_spawn_definitions = asteroid_util.spawn_definitions(asteroid_util.fulgora_aquilo),
  }
})
```

---

## asteroid (spawn definitions and naming)

> **Source note:** Wube's `asteroid-spawn-definitions.lua` defines how asteroids are
> *spawned*, not the entity prototype itself. For the entity prototype fields of
> `type = "asteroid"` / `type = "asteroid-chunk"`, consult
> `__space-age__/prototypes/entity/` directly.

**Source:** `__space-age__/prototypes/planet/asteroid-spawn-definitions.lua`

### Predefined route tables
```lua
local asteroid_util = require("__space-age__.prototypes.planet.asteroid-spawn-definitions")
```
Available routes: `nauvis_vulcanus`, `nauvis_gleba`, `nauvis_fulgora`, `vulcanus_gleba`, `gleba_fulgora`, `gleba_aquilo`, `fulgora_aquilo`, `aquilo_solar_system_edge`, `shattered_planet_trip`

### Route table structure
```lua
{
  probability_on_range_chunk  = { {position=0.1, probability=0.0025, angle_when_stopped=1}, ... },
  probability_on_range_small  = { ... },   -- optional
  probability_on_range_medium = { ... },   -- optional
  probability_on_range_big    = { ... },   -- optional
  probability_on_range_huge   = { ... },   -- optional
  type_ratios = {
    {position = 0.1, ratios = {metallic, carbonic, oxide, promethium}},
    {position = 0.9, ratios = {4, 3, 1, 0}},
  },
  has_promethium_asteroids = true,  -- only in shattered_planet_trip; omit otherwise
}
```

### Entity naming convention (from Wube source)

| Size | Name pattern | Example |
|---|---|---|
| chunk | `{type}-asteroid-chunk` | `"metallic-asteroid-chunk"` |
| small | `small-{type}-asteroid` | `"small-carbonic-asteroid"` |
| medium | `medium-{type}-asteroid` | `"medium-oxide-asteroid"` |
| big | `big-{type}-asteroid` | `"big-metallic-asteroid"` |
| huge | `huge-{type}-asteroid` | `"huge-metallic-asteroid"` |

Types: `metallic`, `carbonic`, `oxide` (always); `promethium` (only when `has_promethium_asteroids = true`)

### Spawn definition entry structure (generated by `spawn_definitions()`)

Route-based (for space-connection):
```lua
{
  asteroid = "metallic-asteroid-chunk",
  type = "asteroid-chunk",    -- present only for chunk-size entries
  spawn_points = {
    {
      distance = 0.5,          -- position along route (0.0 = origin, 1.0 = destination)
      probability = 0.0025,
      speed = 1/60,            -- standard_speed = 1 meter/second
      angle_when_stopped = 1
    }
  }
}
```

Planet/location-specific (second arg to `spawn_definitions()`):
```lua
{
  asteroid = "metallic-asteroid-chunk",
  type = "asteroid-chunk",
  probability = 0.0025,
  speed = 1/60,
  angle_when_stopped = 1
}
```

### Usage patterns (from Wube source)
```lua
-- Full route (use on space-connection):
asteroid_util.spawn_definitions(asteroid_util.fulgora_aquilo)

-- At a specific location (position 0–1 along route, use on planet/space-location);
-- the position must be one of the route's significant positions — see common-errors.md:
asteroid_util.spawn_definitions(asteroid_util.fulgora_aquilo, 0.9)
```

> **2.x change:** This entire asteroid spawn system is new in Space Age. No equivalent in 1.x.

---

## item

**Type string:** `"item"` — appears in Wube source within minable result tables:
```lua
{ type = "item", name = "stone", amount_min = 11, amount_max = 15 }
```

> **Verification note:** Full `item` prototype field requirements were not captured in
> the gathered source material. Cross-reference against base game item prototypes
> (`data.raw.item`) directly for `icon`/`icon_size`, `stack_size`, `subgroup`, `order`,
> and weight/spoilage fields new in 2.x.

---

## recipe

> **Verification note:** No `recipe` prototype definition body was captured in the
> gathered source material. Check base game recipes in `data.raw.recipe` — note the 2.x
> format change: `ingredients`/`results` entries are `{type=, name=, amount=}` records
> (no shorthand pairs), and `result`/`result_count` were removed in favor of `results`.

---

## technology

> **Verification note:** No `technology` prototype definition body was captured in the
> gathered source material. Check base game technologies in `data.raw.technology`. For
> unlocking The Reef, see common-errors.md: discovery prerequisites follow the
> `planet-discovery-<name>` pattern and the unlock effect field is `space_location`.

---

## generator (Dilithium Generator)

> **Verification note:** Type string and field names unverified from gathered source.
> Check `__base__/prototypes/entity/` generator/burner-generator definitions and the
> prototype API before writing this definition.

---

## thruster (Ion Thruster)

> **Verification note:** Type string and field names unverified from gathered source.
> Check `__space-age__/prototypes/entity/thruster.lua` and the prototype API before
> writing this definition.

---

## container / inventory scripting hooks

Event handler registration uses `script.on_event(defines.events.<name>, handler)`.

### Entity lifecycle (for tracking containers)

| Event | Key parameters | Notes |
|---|---|---|
| `on_built_entity` | `entity: LuaEntity, player_index, tags` | Player places container |
| `on_robot_built_entity` | `entity: LuaEntity, robot, stack` | Robot places container |
| `on_space_platform_built_entity` | `entity, platform: LuaSpacePlatform, stack` | Platform places container |
| `on_entity_died` | `entity, loot: LuaInventory, force` | `loot` valid this tick only |
| `on_player_mined_entity` | `entity, buffer: LuaInventory, player_index` | `buffer` valid this tick only |
| `on_robot_mined_entity` | `entity, buffer: LuaInventory, robot` | `buffer` valid this tick only |
| `on_space_platform_mined_entity` | `entity, buffer: LuaInventory, platform` | `buffer` valid this tick only |

> **2.x change:** `on_space_platform_built_entity` and `on_space_platform_mined_entity` are new in Space Age.
> This table is the minimum for container work — see the full built/removed matrix in runtime-discipline.md §3.

### GUI / inventory interaction

| Event | Key parameters | Notes |
|---|---|---|
| `on_gui_opened` | `entity, inventory: LuaInventory, gui_type, player_index` | Player opens container GUI |
| `on_gui_closed` | `entity, inventory: LuaInventory, gui_type, player_index` | Player closes container GUI |
| `on_player_main_inventory_changed` | `player_index` | Player inventory change |

### Cargo pod / space platform delivery

| Event | Key parameters | Notes |
|---|---|---|
| `on_cargo_pod_delivered_cargo` | `cargo_pod: LuaEntity, spawned_container: LuaEntity` | After pod delivers cargo |
| `on_cargo_pod_finished_descending` | `cargo_pod, player_index, launched_by_rocket` | Pod lands on surface |
| `on_space_platform_changed_state` | `platform: LuaSpacePlatform, old_state` | Platform state change |

> **2.x change:** All `on_cargo_pod_*` and `on_space_platform_*` events are new in Space Age. No equivalent in 1.x.

### Research hooks

| Event | Key parameters | Notes |
|---|---|---|
| `on_research_finished` | `research: LuaTechnology, by_script: bool` | Unlock recipes/content |
| `on_research_reversed` | `research: LuaTechnology, by_script: bool` | Undo unlocks |

### Script registration pattern (standard form)
```lua
-- control.lua
script.on_event(defines.events.on_built_entity, function(event)
  local entity = event.entity
  -- filter by entity.name or entity.type
end)

script.on_event(defines.events.on_entity_died, function(event)
  -- event.loot is a LuaInventory; only valid during this handler
  local loot = event.loot
end)

script.on_event(defines.events.on_research_finished, function(event)
  local tech = event.research  -- LuaTechnology
end)
```
