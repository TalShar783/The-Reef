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

### Changing a space-location to a planet while a platform is parked there

**Wrong:** Changing `type = "space-location"` to `type = "planet"` on an existing location while a save has a platform docked there
**Correct:** Start a fresh save after making the type change, or remove the platform from the location before making the change
**Source:** Factorio crash during The Reef development — `SpacePlatform.cpp:1048`: orbital logistics consistency check fails because the save's platform state was serialized against a space-location but is now being validated against a planet
**Note:** Platforms parked at space-locations are managed differently from those in orbit around planets. Changing the type mid-save corrupts the platform's registered state and causes an assert crash on load.

---

### Duplicate section headers in locale files

**Wrong:** Multiple `[item-name]` (or any) sections in the same `.cfg` file
**Correct:** Each section header (`[item-name]`, `[entity-name]`, etc.) must appear exactly once; add all keys for that section under the single header
**Source:** Factorio locale loader error during The Reef Phase 3 load: "Duplicate key in property tree at ROOT"
**Note:** Unlike Lua tables, Factorio's locale parser treats duplicate section headers as a fatal error. Consolidate all keys for a given category under one header per file.

---

### Guessing unknown names, paths, or API fields

**Wrong:** Guessing a prototype field name, entity name, icon path, particle name, inventory define, or any other identifier not confirmed in source material or the skill docs
**Correct:** Stop and ask the user what to do — do not guess
**Source:** Standing instruction from The Reef developer
**Note:** Guessed names produce silent failures (entity not registered, wrong icon path, wrong field silently ignored) that are hard to diagnose. Examples of errors caused by guessing: `promethium-science.png` (correct: `promethium-science-pack.png`), `nuclear-reactor.png` in `__space-age__` (correct: `__base__`), `metallic-asteroid-chunk-particle-medium` assumed to exist (happened to be correct but was a guess). When a name cannot be confirmed from source material, the lua files, or the prototype cheatsheet — ask before writing code.

---

### `flying-text` entity removed in Factorio 2.x

**Wrong:** `surface.create_entity({ name = "flying-text", position = ..., text = ..., color = ... })`
**Correct:** `player.create_local_flying_text({ position = ..., text = ..., color = ..., time_to_live = 120 })`
**Source:** Runtime error during The Reef Cargo Hatch development: "Unknown entity name: flying-text"
**Note:** `flying-text` was a spawnable entity in Factorio 1.x but was removed in 2.x. Use `LuaPlayer.create_local_flying_text` instead — it shows text only to the local player and takes `position`, `text`, `color`, and `time_to_live` (in ticks).

Also: `create_entity` always identifies prototypes by `name`, not `type`. The `type` field is a data-stage prototype schema field only.

---

### game.item_prototypes removed in Factorio 2.x

**Wrong:** `game.item_prototypes[name].stack_size`
**Correct:** `prototypes.item[name].stack_size`
**Source:** Runtime crash during The Reef Cargo Hatch development
**Note:** In Factorio 2.x, `game.item_prototypes` (and similar `game.*_prototypes` tables) were replaced with the `prototypes` global. Same C++ object / throws on missing keys. Use `prototypes.item`, `prototypes.entity`, `prototypes.recipe`, etc.

---

### LuaSpacePlatform.cargo_inventory does not exist

**Wrong:** `surface.platform.cargo_inventory`
**Correct:** `surface.find_entities_filtered({ type = "space-platform-hub" })[1].get_inventory(1)`
**Source:** Runtime crash during The Reef Cargo Hatch development
**Note:** Accessing a non-existent key on a Factorio C++ object (LuaSpacePlatform, LuaEntity, etc.) throws an error rather than returning nil as plain Lua tables do. `LuaSpacePlatform` does not expose a `cargo_inventory` property in Factorio 2.x — use the hub entity's inventory directly.

---

### GUI should match vanilla Factorio conventions

When building entity GUIs, prefer `player.gui.relative` over `player.gui.screen`:
- Anchors the panel beside the entity's own inventory GUI
- X close button appears in the title bar automatically
- E and Esc close both the entity GUI and the relative panel
- No custom close button needed
- The default entity inventory slot stays visible (use it for "current contents")

Setting `player.opened = nil` inside `on_gui_opened` to suppress the default GUI
causes `on_gui_closed` to fire immediately, corrupting `storage` state and breaking
subsequent GUI interactions. Always handle both `on_gui_opened` AND `on_gui_closed`
when using relative GUIs.

---

### Vanilla containers are blocked from space platforms by Space Age data-updates

**Context:** `space-age/base-data-updates.lua` adds `surface_conditions = { { property = "gravity", min = 0.1 } }` to all vanilla containers (wooden-chest, iron-chest, steel-chest, all logistic chests). This is why no vanilla chest can be placed on space platforms (gravity = 0).

**Impact on custom entities:** A `table.deepcopy` of iron-chest performed in `data.lua` does NOT inherit this condition — Space Age's data-updates runs after `data.lua`. The `cargo-hatch` entity therefore needs its `surface_conditions` set explicitly.

**Platform-only condition:** `surface_conditions = { { property = "gravity", min = 0, max = 0 } }` restricts placement to space platforms (gravity = 0) only.

**Planet-only condition:** `surface_conditions = { { property = "gravity", min = 0.1 } }` (no max) matches what Space Age applies to vanilla containers — requires at least 0.1g, blocking space platforms.

---

### Wrong mod prefix on icon paths (__space-age__ vs __base__)

**Wrong:** `"__space-age__/graphics/icons/nuclear-reactor.png"`
**Correct:** `"__base__/graphics/icons/nuclear-reactor.png"`
**Source:** Factorio loader error during The Reef Phase 4
**Note:** `__base__` contains all pre-Space-Age content (nuclear reactor, assembling machines, inserters, vanilla science packs, etc.). `__space-age__` contains only Space Age additions (planets, asteroid chunks, space platform, EM/cryogenic/agricultural science packs, etc.). When guessing an icon path, check which expansion the entity belongs to before choosing the prefix. File-not-found errors are the only feedback — the loader does not suggest the correct path.

---

### `probability` on recipe result products renamed to `independent_probability` (2.1 breaking change)

**Wrong:** `{ type = "item", name = "dilithium-crystal", amount = 1, probability = 0.03 }`
**Correct:** `{ type = "item", name = "dilithium-crystal", amount = 1, independent_probability = 0.03 }`
**Source:** Factorio loader error during The Reef 2.1 migration: "'probability' property on a product prototype was renamed into 'independent_probability'. Please update."
**Note:** Affects all recipe `results` entries that use chance-based output. Straight rename — no semantic change.

---

### `recycling-or-hand-crafting` category removed in 2.1

**Wrong:** `categories = { "recycling-or-hand-crafting" }`
**Correct:** `categories = { "recycling", "hand-crafting" }`
**Source:** Factorio loader error during The Reef 2.1 migration: "recipe-category with name 'recycling-or-hand-crafting' does not exist"
**Note:** The combined category was split into two separate entries in the `categories` array. Confirmed from `space-age/prototypes/recipe.lua:2131` (scrap-recycling recipe).

---

### Using `category` instead of `categories` on recipe prototypes (2.1 breaking change)

**Wrong:** `category = "crushing"`
**Correct:** `categories = { "crushing" }`
**Source:** Factorio loader error during The Reef 2.1 migration: "In RecipePrototype, `category` and `additional_categories` got merged into `categories` table. Please use that instead."
**Note:** In Factorio 2.1, `category` (string) and `additional_categories` (array) on recipe prototypes were merged into a single `categories` array. All recipes must be updated — a single `category` string is now a hard error.

---

### Using `fuel_category` instead of `fuel_categories` on burner energy sources

**Wrong:** `energy_source = { type = "burner", fuel_category = "dilithium-fuel", ... }`
**Correct:** `energy_source = { type = "burner", fuel_categories = { "dilithium-fuel" }, ... }`
**Source:** Factorio loader error during The Reef Phase 4: "'fuel_category' is no longer supported. Please use 'fuel_categories' instead"
**Note:** In Factorio 2.x, `fuel_category` was replaced by `fuel_categories` (an array). The singular form silently worked in 1.x but is a hard error in 2.x.

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

### `entity.fluidbox` removed from LuaEntity in Factorio 2.x

**Wrong:** `entity.fluidbox[N]` to read or write fluid box contents; `entity.fluidbox.get_capacity(N)`
**Correct:** Explicit methods on LuaEntity:
- `entity.get_fluid(index)` → `Fluid?` ({name, amount, temperature} or nil)
- `entity.set_fluid(index, fluid)` → **index first**, fluid table second
- `entity.clear_fluid(index)` → empties box N
- `entity.get_fluid_capacity(index)` → max capacity of box N
- `entity.add_fluid(index, fluid)` → **index first**, fluid table second
- `entity.remove_fluid(index, amount)` → **index first**, amount second
**Source:** Runtime error during The Reef Fluid PMR development (feature since deprecated, see `deprecated/fluid-pmr/`): "LuaEntity doesn't contain key fluidbox." Confirmed via runtime-api.json: LuaEntity has no `fluidbox` attribute in 2.x, only `fluidbox_neighbours` and `fluids_count`. Parameter order confirmed by runtime-api.json parameter `order` field (0 = first positional arg).
**Note:** **Correction (Fluid PMR v2, 2026-07-01):** the previous version of this note claimed `entity.fluidbox` still exists on pipe/pump/fluid-tank entities as a `LuaFluidBox` class — this is **wrong**. `runtime-api.json` has no `LuaFluidBox` class at all in 2.x; `fluidbox` is not an attribute on `LuaEntity` for any entity type. The explicit method API above (`get_fluid`/`set_fluid`/`add_fluid`/`remove_fluid`/`clear_fluid`/`get_fluid_capacity`) is universal across storage-tank, pump, pipe, and crafting-machine entities — there is no type-specific fluidbox object to fall back on. **Index is ALWAYS the first argument** — `add_fluid(index, fluid)`, `remove_fluid(index, amount)`, `set_fluid(index, fluid)`. Passing fluid first causes "'index': real number expected got table" at runtime.

---

### `production_type = "none"` rejected on crafting machine fluid boxes (2.x)

**Wrong:** `{ production_type = "none", pipe_connections = {}, ... }` on any fluid box of an `assembling-machine` entity
**Correct:** All fluid boxes on crafting machines must use `production_type = "input"` or `"output"` — there is no `"none"` option
**Source:** Factorio loader error during The Reef Fluid PMR development (feature since deprecated, see `deprecated/fluid-pmr/`): "Crafting machine fluidboxes must be input or output types."
**Note:** `production_type = "none"` was intended to create internal "tank" boxes that the native crafter ignores, but it is a hard error in 2.x. The workaround is a permanently-unobtainable blocker fluid as an ingredient in all display recipes (see `pmr-void-fluid` pattern in `prototype-cheatsheet.md`). With this pattern all fluid boxes use `production_type = "input"`, and native crafting never fires because it can never satisfy the blocker ingredient.

---

### Omitting `pipe_connections` on internal fluid boxes (2.x required field)

**Wrong:** Fluid box with no `pipe_connections` key at all
**Correct:** `pipe_connections = {}` (empty array) for boxes with no external connections
**Source:** Factorio loader error during The Reef Fluid PMR development (feature since deprecated, see `deprecated/fluid-pmr/`): "Key 'pipe_connections' not found in property tree at ROOT.assembling-machine.fluid-pmr.fluid_boxes[1]" (0-indexed)
**Note:** In Factorio 2.x, `pipe_connections` is required on every fluid box definition, even internal-only tanks that should have no external pipe access. Provide an empty array. The error index is 0-based, so `fluid_boxes[1]` refers to the second box in the Lua array.

---

### `add_fluid` silently discards fluid added to sealed fluid boxes (no pipe connections)

**Wrong:** Using `entity.add_fluid(index, fluid)` to accumulate fluid in a box defined with `pipe_connections = {}`
**Correct:** Track accumulated fluid amounts in script storage (`data.fluids = { iron=0, copper=0 }`); only use `remove_fluid`/`get_fluid` on boxes with real pipe connections
**Source:** Confirmed during The Reef Fluid PMR testing (feature since deprecated, see `deprecated/fluid-pmr/`) — staging fluid was successfully removed via `remove_fluid` but fluid added to the sealed internal boxes via `add_fluid` produced no effect; `get_fluid` on those boxes always returned 0
**Note:** Sealed fluid boxes (pipe_connections = {}) appear to reject or discard script-inserted fluid. The "internal tank" pattern — sealed box accumulates fluid added via script — does not work. If you need script-side fluid accumulation, store amounts as numbers in the storage table. The sealed boxes are still valid for the prototype (no loader error) but are non-functional as storage.

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

### `LuaTransportLine.insert_at_back` parameter order: items first, size second

**Wrong:** `tl.insert_at_back(1, {name="iron-ore", count=1})` → crash "items: table expected, got number"
**Correct:** `tl.insert_at_back({name="iron-ore", count=1}, 1)` — `items` (ItemStackIdentification) is parameter 0 (first), `belt_stack_size` (uint8, optional) is parameter 1 (second).
**Source:** The Reef PMR output crash. The runtime-api.json lists parameters alphabetically in the `parameters` array but the `"order"` field on each entry reveals true positional order. Always check `order` values, not array position, when reading method signatures from the JSON.
**Note:** `takes_table: false` on this method means positional call, not named-table call. The `order` field is the only reliable indicator of argument position.

---

### Assembling-machine fluid boxes filter to the recipe ingredient's fluid type

**Wrong:** Using an `assembling-machine`-based entity (including `chemical-plant` deepcopies) to accept multiple different fluid types through one pipe connection
**Correct:** Use a `storage-tank`-based entity when you need one pipe input to accept whatever fluid arrives
**Source:** Confirmed during The Reef Fluid PMR development (feature since deprecated, see `deprecated/fluid-pmr/`) — even with `production_type = "input"` and a valid pipe connection, the runtime fluid box only accepts the fluid named in the active recipe's ingredient. Any other fluid arriving at the pipe is rejected at the pipe-segment level; no script call can override this.
**Note:** This is a fundamental architectural constraint, not a configuration option. "One staging box that accepts molten-iron OR molten-copper OR any other fluid" is not achievable on any assembling-machine or chemical-plant base entity. `storage-tank` entities have no recipe system and accept any single fluid type that connects to them (standard Factorio one-fluid-per-network rule applies, but the tank itself does not filter by recipe).

---

### `entity.active` does not exist on `storage-tank` entities

**Wrong:** Checking `entity.active` on a storage-tank-based entity to gate script logic
**Correct:** Omit the check entirely — storage tanks have no power consumption and cannot be circuit-disabled; `active` is a crafting-machine property
**Source:** Factorio API — `active` is defined on `LuaEntity` for types `assembling-machine`, `furnace`, `rocket-silo`, etc. Storage tanks have no enabled/disabled state exposed through the API.
**Note:** If you need to allow circuit control of a storage-tank-based machine in the future, add a separate `LuaEntity` flag read or a custom circuit signal check.

---

### `"hidden"` is not a valid `EntityPrototypeFlags` value

**Wrong:** `flags = { "not-on-map", "placeable-off-grid", "hidden", ... }` on any entity prototype
**Correct:** `hidden = true` as a separate top-level field on the prototype; omit "hidden" from `flags` entirely
**Source:** Factorio loader error during Fluid PMR v2 development: `Error while loading entity prototype "fluid-pmr-intake-tank" (storage-tank): Unknown flag "hidden"`
**Note:** `EntityPrototypeFlags` (the `flags` array) has a fixed enum of valid values (`not-rotatable`, `placeable-neutral/player/enemy`, `placeable-off-grid`, `player-creation`, `not-on-map`, `not-blueprintable`, `not-deconstructable`, etc.) and `"hidden"` is not among them — confirmed via `prototype-api.json` type `EntityPrototypeFlags`. Visibility is a distinct top-level `hidden` boolean field on `EntityPrototype`, set alongside `flags`, not inside it. This matches the pattern already used by `advanced-cargo-hatch-proxy` in `prototypes/entities.lua` (`hidden = true` as its own field) — the same convention just wasn't followed here initially.

---

### `get_contents()` now returns an array, not a dictionary, in 2.x

**Wrong:** `for name, count in pairs(inv.get_contents()) do` — `name` is a numeric index, `count` is an `ItemWithQualityCount` table, not a string/number pair. Passing the numeric key as an item name crashes with "Invalid ItemID".
**Correct:** `for _, item in ipairs(inv.get_contents()) do` — each `item` is `{name: string, quality: string, count: uint}`.
**Source:** The Reef PMR on_tick crash — `LuaTransportLine.get_contents()` and `LuaInventory.get_contents()` both changed return type from `{[string]: uint}` to `ItemWithQualityCount[]` in Factorio 2.x.
**Note:** Applies to **both** `LuaInventory.get_contents()` and `LuaTransportLine.get_contents()`. Slot-index iteration (`for i = 1, #inv do local stack = inv[i]`) is unaffected and still preferred for inventory loops. Use `get_contents()` only when you need a summary; always iterate the result with `ipairs`, and access fields via `item.name`, `item.quality`, `item.count`.

---

### `defines.inventory.assembling_machine_input/output` renamed in 2.x

**Wrong:** `entity.get_inventory(defines.inventory.assembling_machine_input)` → returns nil → `get_inventory` crashes with "real number expected got nil"
**Correct:** `entity.get_inventory(defines.inventory.crafter_input)` / `defines.inventory.crafter_output`
**Source:** The Reef PMR on_tick error — `assembling_machine_input` and `assembling_machine_output` do not exist in the Factorio 2.x `defines.inventory` table. The 2.x unification of crafting entities under the generic "crafter" type renamed these defines. Only `assembling_machine_dump` survives from the old naming.
**Note:** Affects all runtime code that accesses assembling-machine inventories by define name. Use `crafter_input`, `crafter_output`, `crafter_modules`, `crafter_trash` for all crafting machines in 2.x.

---

### `next_upgrade` bounding box mismatch after resizing a deepcopied assembling-machine

**Error:** `next_upgrade target (assembling-machine-2) must have the same bounding box`
**Wrong:** Leaving `next_upgrade` inherited from the deepcopy base after changing `collision_box`/`selection_box`
**Correct:** Set `pmr.next_upgrade = nil` (or point it to a same-size custom entity) whenever the bounding box diverges from the base
**Source:** The Reef Phase 5 load error — `basic-pmr` deepcopied from `assembling-machine-1` (3×3 default), then resized to 1×1
**Note:** `assembling-machine-1` has `next_upgrade = "assembling-machine-2"`. Both vanilla machines are 3×3, so the constraint is invisible until you change the box. Factorio enforces identical bounding boxes between a machine and its `next_upgrade` target at data-stage setup — it is a hard error, not a silent mismatch.

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
