# Common API Errors: Factorio 2.x / Space Age Mod Development

Errors documented from Wube official data, the requirements of The Reef's direct
dependencies (flib, PlanetsLib), errors hit directly during The Reef's own load testing,
and confirmed Factorio 2.x engine behaviors (verify specifics against
lua-api.factorio.com). Where a third-party mod is named in a Source line, it is cited as
**evidence of a convergent pattern observed during research** — never as code
provenance; all code snippets are original illustrations and nothing is copied from any
third-party mod (see runtime-discipline.md §11). Do not speculate beyond what the
source confirms.

---

### Using internal module name instead of the conventional require alias

**Wrong:** `local asteroid_functions = require("__space-age__.prototypes.planet.asteroid-spawn-definitions")`
**Correct:** `local asteroid_util = require("__space-age__.prototypes.planet.asteroid-spawn-definitions")`
**Source:** Wube `asteroid-spawn-definitions.lua` (the module's internal table name) vs the ecosystem-wide require alias
**Note:** The module internally names its table `asteroid_functions`, but the established convention is to require it under the alias `asteroid_util`; using the internal name is technically valid Lua but diverges from convention and will break copy-pasted examples.

---

### Calling `spawn_definitions` without a position argument on a planet prototype

**Wrong:** `asteroid_spawn_definitions = asteroid_util.spawn_definitions(asteroid_util.gleba_fulgora)`
**Correct:** `asteroid_spawn_definitions = asteroid_util.spawn_definitions(asteroid_util.gleba_fulgora, 0.9)`
**Source:** Wube `asteroid-spawn-definitions.lua` (`spawn_definitions` second parameter)
**Note:** The second argument is the route position (0–1 float) representing where along the route this body sits; omitting it produces route-wide spawn tables (correct for `space-connection`) but wrong for a `planet`/`space-location` prototype's own `asteroid_spawn_definitions`.

---

### Using `data:extend` instead of `PlanetsLib:extend` for planet prototypes

**Wrong:** `data:extend({ { type = "planet", name = "the-reef", ... } })`
**Correct:** `PlanetsLib:extend({ { type = "planet", name = "the-reef", ... } })`
**Source:** PlanetsLib usage requirements (PlanetsLib is a Reef dependency)
**Note:** PlanetsLib is declared as a hard dependency and wraps `data:extend` with additional registration logic; bypassing it causes the location to be invisible to PlanetsLib-aware mods.

---

### Wrong key name for tile autoplace settings

**Wrong:** `autoplace_settings = { ["tiles"] = { ... } }`
**Correct:** `autoplace_settings = { ["tile"] = { ... } }`
**Source:** Factorio `MapGenSettings.autoplace_settings` schema — verify at lua-api.factorio.com; the singular key observed in Cerys and Maraxsis map-gen (evidence)
**Note:** The key is the singular `"tile"`, matching the prototype category name; `"tiles"` silently produces no tile placement.

---

### Misspelling `procession_graphic_catalogue`

**Wrong:** `procession_graphics_catalogue = my_planet_catalogue`
**Correct:** `procession_graphic_catalogue = my_planet_catalogue`
**Source:** Factorio prototype field spelling — verify at lua-api.factorio.com; correct singular spelling observed in Cerys (evidence)
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
**Source:** Lua syntax — hyphenated keys require bracket string notation
**Note:** Hyphenated keys are not valid Lua identifiers and must use bracket string notation; non-hyphenated properties like `gravity`, `pressure`, and `temperature` can use either form.

---

### Wrong `subgroup` value on `space-connection` prototype

**Wrong:** `subgroup = "space-connections"`
**Correct:** `subgroup = "planet-connections"`
**Source:** Vanilla space-connection prototypes (`data.raw["space-connection"]`)
**Note:** Vanilla space-connections use `"planet-connections"` as the subgroup string; other values will break ordering in the starmap GUI.

---

### Placing `is_satellite = true` at the top level instead of inside `orbit`

**Wrong:** `{ type = "planet", name = "my-moon", is_satellite = true, orbit = { ... } }`
**Correct:** `{ type = "planet", name = "my-moon", orbit = { ..., is_satellite = true } }`
**Source:** PlanetsLib orbit schema (verify against PlanetsLib source — a Reef dependency); placement observed in Cerys (evidence)
**Note:** `is_satellite` is a field of the `orbit` sub-table, not of the planet prototype itself.

---

### Omitting `type` and `name` from `orbit.parent`

**Wrong:** `orbit = { parent = "fulgora", distance = 1.39 }`
**Correct:** `orbit = { parent = { type = "planet", name = "fulgora" }, distance = 1.39 }`
**Source:** PlanetsLib orbit schema (verify against PlanetsLib source — a Reef dependency); shape observed in Cerys (evidence)
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
**Source:** PlanetsLib API — colon-call passes the required implicit `self`
**Note:** The colon syntax passes the PlanetsLib object as the implicit `self` argument; dot notation omits it, causing a runtime error inside the library method.

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

### Passing an arbitrary float as the planet position to `spawn_definitions`

**Wrong:** `asteroid_util.spawn_definitions(asteroid_util.fulgora_aquilo, 0.55)`
**Correct:** `asteroid_util.spawn_definitions(asteroid_util.fulgora_aquilo, 0.4)` (or `0.1` / `0.9`)
**Source:** Confirmed from `asteroid-spawn-definitions.lua:333` during The Reef Phase 1 load
**Note:** `spawn_definitions` only emits a spawn point when `planet == significant_position` exactly. Significant positions are the union of all `position` values in `type_ratios` and `probability_on_range_*`. For `fulgora_aquilo` these are `0.1`, `0.4`, `0.9`. Any other float returns an empty table; `[1].probability` on an empty table crashes with "attempt to index field '?' (a nil value)" at line 421.

---

### Using `global` instead of `storage` for script data in 2.x

**Wrong:** `global.my_data = {}`
**Correct:** `storage.my_data = {}`
**Source:** Factorio 2.0 breaking change — see `storage` at lua-api.factorio.com
**Note:** Factorio 2.0 renamed the persistent script data table from `global` to `storage`; every pre-2.0 tutorial and most training data uses the old name.

---

### Storing a function in `storage`

**Wrong:** `storage.sites[i].iter_fn = function(t, k) ... end`
**Correct:** Store a string key and look the function up in a file-local registry at call time
**Source:** Factorio `storage` serialization rules; observed as a shipped bug + cleanup migration in YARM (evidence, not copied code)
**Note:** Functions in `storage` block saving entirely in Factorio 2.0 and caused desyncs in earlier versions; if they ever reach a save, a migration is needed to strip them back out.

---

### Treating `get_contents()` as a name→count map in 2.x

**Wrong:** `for name, count in pairs(inventory.get_contents()) do`
**Correct:** `for _, item in pairs(inventory.get_contents()) do  -- item = {name=, count=, quality=}`
**Source:** Factorio 2.0 `LuaInventory.get_contents` API change (quality); Even Distribution's 2.0 port fixed this exact misuse (evidence)
**Note:** Quality changed the return shape to an array of records; name-keyed iteration silently produces garbage, and name-only item comparisons merge different qualities.

---

### More than 20 parameters in a localised string

**Wrong:** `{"my-locale.key", p1, p2, ..., p21}`
**Correct:** Nest sub-tables — `{"", {"my-locale.part1", p1, ...}, {"my-locale.part2", p11, ...}}` — each nested localised string gets its own 20-parameter budget
**Source:** Engine limit — "Too many parameters for localised string 21 < 20 (limit)" runtime error; Helmod's history shows it hit repeatedly at scale (evidence)
**Note:** The engine hard-caps localised string parameters at 20 and raises a runtime error, which typically only surfaces when data grows large enough to hit it.

---

### Registering conditional event handlers only in `on_init`

**Wrong:** Registering `on_nth_tick`/`on_tick` based on storage state in `on_init` only
**Correct:** Call the same registration function from `on_init`, `on_load`, AND `on_configuration_changed`, deriving registration purely from `storage`
**Source:** Factorio handler lifecycle — handlers are not saved (see `script.on_load`); Auto Deconstruct and LTN converged on the same single-registration-function structure (evidence)
**Note:** A multiplayer client that joins runs `on_load`, and if its handler set differs from the server's, the game desyncs or crashes.

---

### Tracking entity creation without the script-raised and cloned events

**Wrong:** Handling only `on_built_entity` + `on_robot_built_entity`
**Correct:** Also handle `script_raised_built`, `script_raised_revive`, `on_entity_cloned` (and `on_space_platform_built_entity` in 2.x); for removal also `script_raised_destroy` and the surface events (`on_pre_surface_deleted`, `on_surface_cleared`)
**Source:** Factorio event API — see the full matrix in runtime-discipline.md §3
**Note:** Entities created or destroyed by other mods (or by cloning/editor tools) fire none of the player/robot events; tracking silently breaks without the full set.

---

### Confusing `valid` with `valid_for_read` on item stacks

**Wrong:** `if stack.valid then local n = stack.count end`
**Correct:** `if stack.valid_for_read then local n = stack.count end`
**Source:** `LuaItemStack.valid_for_read` at lua-api.factorio.com; checked pervasively in Krastorio 2 (evidence)
**Note:** A `LuaItemStack` can be `valid` (the slot object exists) while empty and unreadable; reading `.count`/`.name` then throws.

---

### Assuming 1-indexing on `ItemInventoryPositions.stack`

**Wrong:** `inventory[locator.stack]`
**Correct:** `inventory[locator.stack + 1]`
**Source:** `ItemInventoryPositions` (item request proxy insert plans) — verify at lua-api.factorio.com; flagged in a Factorissimo 3 source comment (evidence)
**Note:** The Lua API is 1-indexed almost everywhere; this field is a confirmed 0-indexed exception. Verify indexing per field, not per API.

---

### Testing fluid emptiness with `= 0` in wait/circuit conditions

**Wrong:** Wait condition `fluid_count = 0`
**Correct:** Use an "empty"-style condition; fractional residue rounds down to 0 while fluid remains
**Source:** Factorio engine behavior — fluid amounts are fractional internally but round down in conditions; LTN carries an explicit workaround for it (evidence)
**Note:** Fluid amounts display and compare as integers, so conditions "equal to 0" trigger while residue is still present.

---

### Assuming `on_init` always runs before the first `on_tick`

**Wrong:** `storage.tasks[event.tick]` unguarded in a tick handler
**Correct:** Nil-guard: `if not storage.tasks then return end`
**Source:** flib `on-tick-n.lua` ("Failsafe for rare cases where on_tick can fire before on_init") — flib is a Reef dependency
**Note:** On first multiplayer join at tick 0, `on_tick` can fire before `on_init` has populated storage.

---

## Still Uncertain

The following identifiers appear in the source material but their full signatures or constraints could not be confirmed from the provided excerpts alone. Verify against lua-api.factorio.com or the PlanetsLib source before use:

- `asteroid_spawn_influence` — observed as `asteroid_spawn_influence = 1` on the Cerys planet prototype (evidence); unclear whether it is required, what the valid range is, or whether it applies to `space-location` type prototypes at all.
- `treat_missing_as_default` inside `autoplace_settings` sub-tables — observed set to `false` in Cerys map gen (evidence); exact semantics (and whether `true` is the silent default) not confirmed.
- `surface_render_parameters.shadow_opacity` — observed as `0.6` in Cerys (evidence); full list of accepted sub-fields not confirmed.
- `persistent_ambient_sounds` — observed set to `{}` in Cerys (evidence); schema of the non-empty form not confirmed.
- `pollutant_type = nil` vs `pollutant_type = "nil"` (string) — Cerys uses actual `nil`, Maraxsis the string `"nil"` (evidence); which form the engine accepts for "no pollutant" is not confirmed.
- `auto_save_on_first_trip` — observed as `false` on the Maraxsis trench planet (evidence); whether it is a standard engine field or mod-specific is not confirmed.
- `label_orientation` — observed on both Cerys and Maraxsis prototypes (evidence); valid range and effect not confirmed.
