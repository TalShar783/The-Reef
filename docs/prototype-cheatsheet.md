API Error: Response stalled mid-stream. The response above may be incomplete.
ace-location

**Type string:** `"space-location"` — **uncertain from source.** The provided source shows `type = "planet"` for Cerys and Maraxsis. Maraxsis requires a `prototypes/planet/space-location` file but its contents are not in the source material. `"space-location"` is likely correct for non-landable destinations (per prompt context) but cannot be confirmed from source examples.

**Via PlanetsLib** (used by Cerys; recommended for compat):
```lua
PlanetsLib:extend({ { ... } })
```

**Fields observed in Cerys / Maraxsis source:**

| Field | Type | Notes |
|---|---|---|
| `type` | string | `"space-location"` — **unverified** |
| `name` | string | Unique prototype name |
| `icon` | string | Asset path |
| `icon_size` | uint | Pixels |
| `starmap_icon` | string | Asset path |
| `starmap_icon_size` | uint | Pixels |
| `order` | string | Sort string |
| `distance` | float | **Inside `orbit` only** — PlanetsLib rejects top-level |
| `orientation` | float | **Inside `orbit` only** — PlanetsLib rejects top-level |
| `draw_orbit` | bool | `false` in both mods |
| `magnitude` | float | Starmap visual size; `0.5` in Cerys |
| `solar_power_in_space` | float | Platform solar power in orbit |
| `label_orientation` | float | Label angle around orbit ring |
| `pollutant_type` | string/nil | `nil` disables pollution |
| `asteroid_spawn_influence` | float | Multiplier; `1` in Cerys |
| `asteroid_spawn_definitions` | table | See §asteroid-spawn-definitions |
| `surface_properties` | table | See below — **planet-only?** uncertain for space-location |
| `hidden` | bool | Hides from starmap; used for Maraxsis trench |
| `orbit` | table | Parent/satellite relationship (Cerys satellite pattern) |

**`surface_properties` keys from Cerys source** (whether applicable to non-landable space-locations is uncertain):
```lua
surface_properties = {
  ["day-night-cycle"] = 72000,   -- ticks
  ["magnetic-field"]  = 120,
  ["solar-power"]     = 120,
  pressure            = 5,
  gravity             = 0.15,    -- Cerys note: 0.1 is minimum for chests
  temperature         = 251,
}
```

> **2.x change:** `surface_properties`, `asteroid_spawn_definitions`, `asteroid_spawn_influence`, `solar_power_in_space` are all Space Age additions. None exist in 1.x planet prototypes.

**Minimal working example (non-landable, adapted from Cerys pattern):**
```lua
local asteroid_util = require("__space-age__.prototypes.planet.asteroid-spawn-definitions")

PlanetsLib:extend({
  {
    type = "space-location",          -- verify this type string
    name = "the-reef",
    icon = "__the-reef__/graphics/icons/the-reef.png",
    icon_size = 256,
    starmap_icon = "__the-reef__/graphics/icons/starmap-the-reef.png",
    starmap_icon_size = 500,
    distance = 12,
    orientation = 0.55,
    order = "e[the-reef]",
    draw_orbit = true,
    magnitude = 0.4,
    solar_power_in_space = 100,
    asteroid_spawn_definitions = asteroid_util.spawn_definitions(asteroid_util.fulgora_aquilo),
  }
})
```

---

## space-connection

**Type string:** `"space-connection"` — confirmed from both Cerys and Maraxsis source.

| Field | Type | Required | Notes |
|---|---|---|---|
| `type` | string | yes | `"space-connection"` |
| `name` | string | yes | |
| `subgroup` | string | yes | `"planet-connections"` in both mods |
| `from` | string | yes | Planet/location name |
| `to` | string | yes | Planet/location name |
| `order` | string | yes | |
| `length` | uint | yes | Route length; `800` (Cerys), `20000` (Maraxsis) |
| `asteroid_spawn_definitions` | table | yes | Route spawns (no second arg = full route) |

**Minimal example (from Cerys source):**
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

> **Source note:** The `asteroid-spawn-definitions.lua` source is comprehensive. It defines how asteroids are *spawned*, not the entity prototype itself. The entity prototype fields for `type = "asteroid"` or `type = "asteroid-chunk"` are **not in the source material** — only their names and spawn structures are shown.

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

### Entity naming convention (from source)

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

### Usage patterns (from source)
```lua
-- Full route (use on space-connection):
asteroid_util.spawn_definitions(asteroid_util.fulgora_aquilo)

-- At a specific location (position 0–1 along route, use on planet/space-location):
asteroid_util.spawn_definitions(asteroid_util.fulgora_aquilo, 0.9)
```

> **2.x change:** This entire asteroid spawn system is new in Space Age. No equivalent in 1.x.

---

## item

**Type string:** `"item"` — referenced in source only within minable result tables:
```lua
{ type = "item", name = "stone", amount_min = 11, amount_max = 15 }
```

> **Source limitation:** No complete `type = "item"` prototype definition appears in the provided source material. The table below lists only what the source confirms; remaining field names and requirements are **unverified from source**.

| Field | Source status |
|---|---|
| `type = "item"` | Confirmed (minable results pattern) |
| `name` | Confirmed (minable results pattern) |
| `icon`, `icon_size` | **Unverified** — not shown in source |
| `stack_size` | **Unverified** — not shown in source |
| `subgroup`, `order` | **Unverified** — not shown in source |

**Do not use this section as authoritative.** Cross-reference against base game item prototypes directly.

---

## recipe

**Type string:** `"recipe"` — referenced by file structure only (`require("prototypes.recipe.recipe")` in Cerys; `require "prototypes.recipe.nuclear"` etc. in Cerys).

> **Source limitation:** No `type = "recipe"` prototype definition body appears in the source material. Field names cannot be confirmed.

### Collision box sizing for custom entities

Factorio uses closed interval collision detection — two entities whose boxes share an exact boundary cannot be placed adjacent to each other. The standard convention is to inset the collision box by 0.1 tiles relative to the full tile footprint:

| Entity footprint | Correct collision_box | Wrong (flush) |
|---|---|---|
| 1×1 | `{{-0.4, -0.4}, {0.4, 0.4}}` | `{{-0.5, -0.5}, {0.5, 0.5}}` |
| 2×2 | `{{-0.9, -0.9}, {0.9, 0.9}}` | `{{-1, -1}, {1, 1}}` |
| 3×3 | `{{-1.4, -1.4}, {1.4, 1.4}}` | `{{-1.5, -1.5}, {1.5, 1.5}}` |

The `selection_box` (what the player clicks) can be flush — only `collision_box` needs the inset.

---

### Subgroup guidance (confirmed from live testing)

The `subgroup` field on a recipe must match a defined `item-subgroup` prototype. **Prefer omitting it** — Factorio then inherits the subgroup from the primary result item, which is always valid.

If you must specify one, use only confirmed vanilla subgroups:

| Subgroup | Contents |
|---|---|
| `"intermediate-product"` | Circuits, plates, gears, etc. |
| `"ammo"` | Ammunition magazines |
| `"capsule"` | Grenades, combat items |
| `"space-material"` | Asteroid chunks, Reef materials |
| `"space-crushing"` | Crusher and recycler recipes |
| `"production-machine"` | Assembling machines, furnaces |
| `"planet-connections"` | Space-connection prototypes |

**Do NOT use** `"combat"` — it does not exist and will crash at load.

---

## assembling-machine (crafting machine with fluid boxes)

**Type string:** `"assembling-machine"` — this is also the type for chemical plants. Chemical plant is NOT a separate prototype type; it is an `assembling-machine` with `fluid_boxes_off_when_no_fluid_recipe = false`.

### 2.x fluid box rules (all apply to every `assembling-machine` entity)

| Constraint | Detail |
|---|---|
| `pipe_connections` required | Must be present on **every** fluid box, including internal-only tanks. Use `pipe_connections = {}` for boxes with no external pipe access. Omitting the key entirely is a hard loader error. |
| `production_type` must be `"input"` or `"output"` | `"none"` does not exist in 2.x and is a hard loader error. |
| `fluid_boxes_off_when_no_fluid_recipe` | Default `true` — hides fluid boxes when no fluid recipe is active. Set to `false` to keep boxes always visible/active (like chemical plant behavior). |
| `filter` | Optional per-box fluid restriction. `filter = "molten-iron"` prevents other fluids from entering that box. |

### Internal tank pattern (sealed from pipes, script-only access)

```lua
{
  production_type  = "input",
  filter           = "molten-iron",  -- restrict to one fluid
  volume           = 500,
  pipe_connections = {},             -- required; empty = no external pipe access
}
```

### Void-fluid blocker pattern (prevent native crafting, keep scripted production)

When using `production_type = "input"` but needing native crafting to never fire, add a permanently-unobtainable hidden fluid as an ingredient in every display recipe:

```lua
-- 1. Define an unobtainable hidden fluid (data stage):
{ type = "fluid", name = "pmr-void-fluid", hidden = true, auto_barrel = false,
  default_temperature = 15, base_color = {0,0,0}, flow_color = {0,0,0},
  icon = "__base__/graphics/icons/fluid/crude-oil.png", icon_size = 64 }

-- 2. Include it as an ingredient in the recipe:
ingredients = {
  { type = "fluid", name = "molten-iron",    amount = 10 },
  { type = "fluid", name = "molten-copper",  amount = 10 },
  { type = "fluid", name = "pmr-void-fluid", amount = 1  }, -- never satisfiable
}
-- Script owns all production; native crafter can never fire.
```

Since `pmr-void-fluid` has no production recipe, the crafter can never satisfy all ingredients — native crafting never fires. Script calls `entity.set_recipe()` to swap between display recipes; the active recipe sets the ghost icon and outputs a circuit signal for free (use "output current recipe as circuit signal" mode).

### Fluid box count is limited to the active recipe's fluid ingredient count (2.x runtime constraint)

**Problem:** Even if the prototype defines N fluid boxes, only the first M are accessible at runtime, where M = the number of fluid-type ingredients in the currently active recipe. Accessing index M+1 throws "Fluid index N is out of bounds. Valid indexes are from 1 up to M."

**Implication for multi-tank scripted machines:** Every display recipe must list ALL internal tank fluids as ingredients, even fluids that recipe doesn't "use," to keep all boxes accessible. For a 3-box machine (staging + 2 tanks), every display recipe needs 3 fluid ingredients. Swapping between two recipes with the same fluid ingredient list does not destroy box contents.

**Scaling cost:** Adding a 4th fluid tank requires adding a 4th fluid ingredient to every display recipe. This works mechanically but adds recipe-book clutter. If recipe-book noise becomes a problem at scale, collapse to a single universal recipe with all possible fluids listed.

### Space Age built-in molten fluids

Defined in `space-age/prototypes/fluid.lua` — do not redefine:
- `molten-iron` — `default_temperature = 1500`
- `molten-copper` — `default_temperature = 1100`

---

## technology

**Type string:** `"technology"` — referenced by file structure only (`require("prototypes.technology")` in Cerys; multiple technology files in Maraxsis).

> **Source limitation:** No `type = "technology"` prototype definition body appears in the source material. Field names cannot be confirmed.

---

## generator (Dilithium Generator)

**Type string:** `"generator"` — **uncertain.** Maraxsis references `require "prototypes.entity.oversized-steam-turbine"` and `require "prototypes.entity.salt-reactor"` but neither file's contents appear in the source material.

> **Source limitation:** No generator prototype definition appears in the source material. Type string and all field names are **unverified from source.**

---

## thruster (Ion Thruster)

**Type string:** `"thruster"` — **uncertain.** No thruster prototype or reference to one appears anywhere in the provided source material.

> **Source limitation:** Type string and all field names are **unverified from source.**

---

## container / inventory scripting hooks

Based on the runtime API event list in source. Event handler registration uses `script.on_event(defines.events.<name>, handler)`.

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

### Script registration pattern (from Cerys/Maraxsis control.lua structure)
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
