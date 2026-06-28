```markdown
# Common API Errors: Factorio 2.x / Space Age Mod Development

Errors documented from Wube official data, Cerys, and Maraxsis source material. Do not speculate beyond what the source confirms.

---

### Using internal module name instead of the conventional require alias

**Wrong:** `local asteroid_functions = require("__space-age__.prototypes.planet.asteroid-spawn-definitions")`
**Correct:** `local asteroid_util = require("__space-age__.prototypes.planet.asteroid-spawn-definitions")`
**Source:** Cerys `prototypes/planet/planet.lua`, Maraxsis planet prototype
**Note:** The module internally names its table `asteroid_functions`, but every reference mod requires it under the alias `asteroid_util`; using the internal name as the variable name is technically valid Lua but diverges from the established convention and will break copy-pasted examples.

---

### Calling `spawn_definitions` without a position argument on a planet prototype

**Wrong:** `asteroid_spawn_definitions = asteroid_util.spawn_definitions(asteroid_util.gleba_fulgora)`
**Correct:** `asteroid_spawn_definitions = asteroid_util.spawn_definitions(asteroid_util.gleba_fulgora, 0.9)`
**Source:** Cerys `prototypes/planet/planet.lua` (planet prototype vs space-connection)
**Note:** The second argument is the route position (0–1 float) representing where along the route this body sits; omitting it produces route-wide spawn tables (correct for `space-connection`) but wrong for a `planet`/`space-location` prototype's own `asteroid_spawn_definitions`.

---

### Using `data:extend` instead of `PlanetsLib:extend` for planet prototypes

**Wrong:** `data:extend({ { type = "planet", name = "the-reef", ... } })`
**Correct:** `PlanetsLib:extend({ { type = "planet", name = "the-reef", ... } })`
**Source:** Cerys `prototypes/planet/planet.lua`
**Note:** PlanetsLib is declared as a hard dependency and wraps `data:extend` with additional registration logic; bypassing it causes the location to be invisible to PlanetsLib-aware mods.

---

### Wrong key name for tile autoplace settings

**Wrong:** `autoplace_settings = { ["tiles"] = { ... } }`
**Correct:** `autoplace_settings = { ["tile"] = { ... } }`
**Source:** Cerys `prototypes/planet/map-gen-settings.lua`, Maraxsis `map-gen.lua`
**Note:** The key is the singular `"tile"`, matching the prototype category name; `"tiles"` silently produces no tile placement.

---

### Misspelling `procession_graphic_catalogue`

**Wrong:** `procession_graphics_catalogue = planet_catalogue_cerys`
**Correct:** `procession_graphic_catalogue = planet_catalogue_cerys`
**Source:** Cerys `prototypes/planet/planet.lua`
**Note:** The field name uses the singular `graphic` with no trailing `s`; the plural spelling is silently ignored.

---

### Missing `type = "asteroid-chunk"` for chunk-size asteroid spawn definitions

**Wrong:** `{ asteroid = "metallic-asteroid-chunk", spawn_points = {...} }`
**Correct:** `{ asteroid = "metallic-asteroid-chunk", type = "asteroid-chunk", spawn_points = {...} }`
**Source:** Wube `asteroid-spawn-definitions.lua` (`spawn_definitions` function, chunk branch)
**Note:** The `spawn_definitions` helper explicitly sets `asteroid_definition.type = "asteroid-chunk"` only for the chunk size; larger sizes omit the `type` field entirely, so hand-written definitions must replicate this asymmetry.

---

### Using dot notation for hyphenated surface property names

**Wrong:** `surface_properties = { day-night-cycle = 3600, magnetic-field = 120 }`
**Correct:** `surface_properties = { ["day-night-cycle"] = 3600, ["magnetic-field"] = 120 }`
**Source:** Cerys `prototypes/planet/planet.lua`
**Note:** Hyphenated keys are not valid Lua identifiers and must use bracket string notation; non-hyphenated properties like `gravity`, `pressure`, and `temperature` can use either form.

---

### Wrong `subgroup` value on `space-connection` prototype

**Wrong:** `subgroup = "space-connections"`
**Correct:** `subgroup = "planet-connections"`
**Source:** Cerys `prototypes/planet/planet.lua`, Maraxsis planet prototype
**Note:** Every space-connection in the source uses `"planet-connections"` as the subgroup string; other values will break ordering in the starmap GUI.

---

### Placing `is_satellite = true` at the top level instead of inside `orbit`

**Wrong:** `{ type = "planet", name = "cerys", is_satellite = true, orbit = { ... } }`
**Correct:** `{ type = "planet", name = "cerys", orbit = { ..., is_satellite = true } }`
**Source:** Cerys `prototypes/planet/planet.lua`
**Note:** `is_satellite` is a field of the `orbit` sub-table, not of the planet prototype itself.

---

### Omitting `type` and `name` from `orbit.parent`

**Wrong:** `orbit = { parent = "fulgora", distance = 1.39 }`
**Correct:** `orbit = { parent = { type = "planet", name = "fulgora" }, distance = 1.39 }`
**Source:** Cerys `prototypes/planet/planet.lua`
**Note:** `parent` is a table with both `type` and `name` keys, not a bare string.

---

### Using `has_promethium_asteroids` on a non-Shattered-Planet route

**Wrong:** Adding `has_promethium_asteroids = true` to a custom route data table
**Correct:** Omit the field (defaults to no promethium)
**Source:** Wube `asteroid-spawn-definitions.lua` — only `shattered_planet_trip` sets this flag
**Note:** Setting this flag causes the `spawn_definitions` helper to add a fourth asteroid type (`"promethium"`) to all spawn calculations; it is only present on the Shattered Planet trip in vanilla data.

---

### Calling `PlanetsLib.extend` with dot notation instead of colon notation

**Wrong:** `PlanetsLib.extend({ ... })`
**Correct:** `PlanetsLib:extend({ ... })`
**Source:** Cerys `prototypes/planet/planet.lua`
**Note:** The colon syntax passes the PlanetsLib object as the implicit `self` argument; dot notation omits it, causing a runtime error inside the library method.

---

### Using a non-existent item-subgroup name on a recipe

**Wrong:** `subgroup = "combat"` (this subgroup does not exist in vanilla)
**Correct:** Omit `subgroup` to inherit from the result item, or verify the subgroup name exists in `data.raw["item-subgroup"]`
**Source:** Factorio loader error during The Reef Phase 3: "item-subgroup with name 'combat' does not exist"
**Note:** Recipe subgroup names must match a defined `item-subgroup` prototype. Vanilla subgroups include `"ammo"`, `"capsule"`, `"intermediate-product"`, `"space-material"` etc. — but NOT `"combat"`. Omitting `subgroup` is always safe and inherits from the result item.

---

### Duplicate section headers in locale files

**Wrong:** Multiple `[item-name]` (or any) sections in the same `.cfg` file
**Correct:** Each section header (`[item-name]`, `[entity-name]`, etc.) must appear exactly once; add all keys for that section under the single header
**Source:** Factorio locale loader error during The Reef Phase 3 load: "Duplicate key in property tree at ROOT"
**Note:** Unlike Lua tables, Factorio's locale parser treats duplicate section headers as a fatal error. Consolidate all keys for a given category under one header per file.

---

### Wrong prerequisite name for Fulgora discovery technology

**Wrong:** `prerequisites = { "fulgora-visitation" }`
**Correct:** `prerequisites = { "planet-discovery-fulgora" }`
**Source:** Space Age `technology.lua:393` — confirmed during The Reef Phase 1 load
**Note:** All planet discovery technologies follow the pattern `planet-discovery-<name>`, not `<name>-visitation` or just `<name>`.

---

### Wrong field name in `unlock-space-location` technology effect

**Wrong:** `{ type = "unlock-space-location", location = "the-reef" }`
**Correct:** `{ type = "unlock-space-location", space_location = "the-reef" }`
**Source:** Factorio prototype loader error during The Reef Phase 1 load
**Note:** The field is `space_location` (underscore, no hyphen), not `location`. The engine error message names the missing key directly: "Key 'space_location' not found".

---

### Omitting `orbit` from a PlanetsLib space-location

**Wrong:** Space-location prototype with no `orbit` field
**Correct:** Always include `orbit = { parent = { type = "space-location", name = "star" }, distance = N, orientation = N }` even for non-satellite primary locations. Do NOT also set `distance`/`orientation` at the top level — PlanetsLib explicitly rejects that pattern.
**Source:** PlanetsLib `lib/planet.lua:54` — `verify_extend_fields` enforces this during The Reef Phase 1 load
**Note:** PlanetsLib:extend() requires `orbit` unconditionally; data:extend() does not. Any mod using PlanetsLib must include it even when the location is not a satellite of another body.

---

### Using planet-format spawn definitions on a space-connection

**Wrong:** `asteroid_util.spawn_definitions(route, 0.4)` (with position arg) in a `space-connection` prototype
**Correct:** `asteroid_util.spawn_definitions(route)` (no second arg) for connections; custom entries must use `spawn_points = [{distance, probability, speed, angle_when_stopped}]`
**Source:** Factorio loader error during The Reef Phase 3: "Key 'spawn_points' not found at space-connection.asteroid_spawn_definitions[0]"
**Note:** `spawn_definitions` returns two different shapes depending on the second argument. No arg → route format with `spawn_points` arrays (required by `space-connection`). With a position float → planet format with flat `probability`/`speed` fields (required by `planet`/`space-location`). Using the wrong format crashes at load.

---

### Passing an arbitrary float as the planet position to `spawn_definitions`

**Wrong:** `asteroid_util.spawn_definitions(asteroid_util.fulgora_aquilo, 0.55)`
**Correct:** `asteroid_util.spawn_definitions(asteroid_util.fulgora_aquilo, 0.4)` (or `0.1` / `0.9`)
**Source:** Confirmed from `asteroid-spawn-definitions.lua:333` during The Reef Phase 1 load
**Note:** `spawn_definitions` only emits a spawn point when `planet == significant_position` exactly. Significant positions are the union of all `position` values in `type_ratios` and `probability_on_range_*`. For `fulgora_aquilo` these are `0.1`, `0.4`, `0.9`. Any other float returns an empty table; `[1].probability` on an empty table crashes with "attempt to index field '?' (a nil value)" at line 421.

---

## Still Uncertain

The following identifiers appear in the source material but their full signatures or constraints could not be confirmed from the provided excerpts alone. Verify against lua-api.factorio.com or the PlanetsLib source before use:

- `asteroid_spawn_influence` — appears as `asteroid_spawn_influence = 1` on the Cerys planet prototype; unclear whether it is required, what the valid range is, or whether it applies to `space-location` type prototypes at all.
- `treat_missing_as_default` inside `autoplace_settings` sub-tables — used as `false` in Cerys map gen; exact semantics (and whether `true` is the silent default) not confirmed from the provided data.
- `surface_render_parameters.shadow_opacity` — appears in Cerys (`shadow_opacity = 0.6`); full list of accepted sub-fields not shown in the source.
- `persistent_ambient_sounds` — set to `{}` in Cerys; schema of the non-empty form not shown.
- `pollutant_type = nil` vs `pollutant_type = "nil"` (string) — Cerys uses actual `nil`; Maraxsis uses the string `"nil"`. Which form the engine accepts for "no pollutant" is not confirmed from the provided source.
- `auto_save_on_first_trip` — appears as `false` on the Maraxsis trench planet; whether this is a standard planet prototype field or Maraxsis-specific is not confirmed.
- `label_orientation` — appears on both Cerys and Maraxsis trench prototypes; valid range and effect not described in the provided source.
```
