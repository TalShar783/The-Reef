# Runtime Scripting Discipline — Factorio 2.x Control Stage

Control-stage (runtime) rules for The Reef. These are ecosystem-wide conventions and
engine behaviors, stated generically; verify any specific API signature against
lua-api.factorio.com before relying on it. The other docs in this folder cover the
data stage.

---

## 1. Entity validity — the #1 crash class

- Any `LuaEntity`, `LuaPlayer`, `LuaSurface`, or `LuaGuiElement` held in `storage` across
  ticks can be invalidated by anything — other mods, biters, surface deletion. Check
  `.valid` **at point of use, every time**. A small `destroy_if_valid()`-style helper
  keeps teardown code honest.
- Item stacks have a **separate** predicate: `stack.valid_for_read`. A stack can be
  `.valid` (the slot exists) but not readable (empty); reading `.count`/`.name` then
  throws. Check both when inspecting inventories.
- Surfaces get deleted out from under you. Subscribe to `on_pre_surface_deleted`,
  `on_surface_cleared`, and `on_chunk_deleted` and purge the corresponding entries from
  `storage`. Space platforms are surfaces that players delete routinely — The Reef must
  handle this.
- Once bad references have been **saved**, fixing the code is not enough: ship a
  migration that scrubs already-corrupt `storage` in existing saves.

## 2. `storage` discipline (desyncs and save-breakage)

- **Never store functions in `storage`.** Functions in `storage` block saving in
  Factorio 2.0 and caused desyncs in earlier versions. If behavior must be scheduled or
  dispatched, store a plain string key and look the function up in a file-local registry
  at call time.
- Metatables on stored tables do not survive save/load. Re-attach them in `on_load`.
- `script.on_load` may **not** touch `game`. It is only for (a) rebuilding local
  caches/metatables from `storage` and (b) re-registering conditional event handlers
  (see §4).
- File-local (upvalue) caches of game-derived data are a desync minefield. A local cache
  must be a pure, deterministically rebuilt function of game state — identical on every
  client; anything else belongs in `storage`.
- Deterministic RNG: for anything that must replay identically, create a dedicated
  generator with `game.create_random_generator(seed)` rather than relying on shared
  `math.random` state.

## 3. The event-completeness matrix

Entity tracking silently breaks unless you subscribe to the full set:

| Lifecycle | Events |
|---|---|
| Built | `on_built_entity`, `on_robot_built_entity`, `script_raised_built`, `script_raised_revive`, `on_entity_cloned`, and in 2.0 `on_space_platform_built_entity` |
| Removed | `on_pre_player_mined_item` (or `on_player_mined_entity`), `on_robot_pre_mined`, `on_entity_died`, `script_raised_destroy`, and in 2.0 `on_space_platform_mined_entity` |
| Surface | `on_pre_surface_deleted`, `on_surface_cleared`, `on_chunk_deleted` |

- Use **event filters** for UPS on the player/robot events (e.g.
  `{{filter="type", type="container"}}`); script-raised events do not support the same
  filtering and are registered unfiltered.
- Entities created by trigger effects (projectiles, spawning effects) fire none of the
  above reliably; `on_script_trigger_effect` is the hook for those. Tile changes by
  script arrive via `script_raised_set_tiles`.
- Be a good citizen in reverse: pass `raise_built = true` when script-creating
  *gameplay* entities so other mods see them; pass `raise_built = false` for
  internal/invisible helper entities, and give helper entities distinctive prefixed
  names so other mods can recognize and exclude them.
- Compound entities need explicit teardown of every hidden part, or the leftovers keep
  acting (and crash other code that finds them).
- 2.0's `on_object_destroyed` fires only for objects you first registered via
  `script.register_on_object_destroyed(obj)`; map the returned `registration_number` in
  `storage` at registration time.

## 4. Conditional event handlers must be re-registered identically in `on_load`

Handler registration state must be a **pure function of `storage`**, or joining
multiplayer clients diverge from the server (desyncs or crashes). Put registration in
one function and call it from `on_init`, `on_load`, `on_configuration_changed`, and every
event that changes whether work is pending — including *de*-registering `on_nth_tick`
when the work queue empties.

Related engine quirk: **`on_tick` can fire before `on_init`** on the first tick of a
multiplayer join (flib's `on-tick-n` module carries an explicit failsafe for this).
Nil-guard the storage tables your tick handler touches.

## 5. One handler per event → use a dispatcher

`script.on_event` **replaces** any previously registered handler for that event. Once a
mod has more than one script module, collect handler lists per event, compose them into
one function, and register that composite once. Route `on_init` and
`on_configuration_changed` to the same idempotent initializer. Adopt this before the mod
grows multiple script modules, not after.

GUI events fire for **all mods' elements**: check `event.element and event.element.valid`
first, then match `element.name` against your own prefix before acting.

## 6. UPS patterns

- **Per-tick work budgets, exposed as settings** ("entities per tick"-style): bounded
  work per tick plus a resumable cursor in `storage`.
- flib's `table.for_n_of` (flib is a Reef dependency) is the canonical resumable
  iterator: pass `storage.from_k` back each tick. Note its defensive detail — it
  verifies the saved cursor key still exists (the table may have mutated between ticks)
  and restarts if not.
- **Cache entity reads in Lua tables.** Reading data off an entity crosses the Lua/C++
  boundary and is several times slower than reading a Lua table. Poll entities on a
  budget in one place; have everything else read the cache.
- Scheduling without `on_tick`: flib's `on-tick-n` (task table keyed by target tick).
- Prefer blind writes over read-compare-write across the API boundary: setting a
  property unconditionally is often cheaper than reading it first to check.
- Expensive work inside GUI event handlers runs in lockstep on **every** client in
  multiplayer. Budget or defer it.

## 7. Migrations

- Use the standard layout: a `migrations/` directory — JSON files for prototype renames,
  Lua files plus `on_configuration_changed` for storage surgery.
- flib's `migration` module implements the standard version dance: zero-pad version
  strings (`"%02d"` per segment) so plain string comparison orders them, then run an
  ordered `version → function` table.
- If a save is too old to migrate safely, **refuse** with a clear player-facing message
  instead of corrupting state.

## 8. Localised strings and translations

- **Localised strings are capped at 20 parameters**; exceeding it is a runtime error
  that typically only surfaces when data grows large. Nest parameters in sub-tables —
  each nested localised string gets its own budget of 20.
- Runtime translation (`request_translation`) is asynchronous and per-player: you need a
  *connected* player per locale to act as translator; requests can be lost and need
  re-requesting after a timeout; results arrive over many ticks and must be batched; and
  unthrottled translation floods can drop slow multiplayer clients. flib's `dictionary`
  module (already a dependency) handles all of this — use it rather than hand-rolling.

## 9. Cross-mod compatibility

- **Data stage:** never assume another mod's prototype exists. Check
  `data.raw[type][name]` before touching it, gate optional tweaks on the prototype's
  existence, and `error()` with a clear message when a hard assumption fails.
- **Runtime:** gate on `script.active_mods["mod-name"]`, and probe
  `remote.interfaces["x"] and remote.interfaces["x"]["fn"]` before calling.
- Other mods will want to interact with The Reef the same way: design a small, stable
  `remote.add_interface` early.

## 10. Engine quirks confirmed in the wild

- Fluid amounts round **down to 0** in circuit/wait conditions while fractional residue
  remains: an `= 0` fluid condition must be expressed as an "empty"-style condition
  instead.
- `ItemInventoryPositions.stack` (item request proxy insert plans) is **0-indexed** in
  an otherwise 1-indexed API. Verify indexing per field, not per API.
- Factorio 2.0 quality changed inventory API shapes: `LuaInventory.get_contents()` now
  returns an array of `{name, count, quality}` records, not a `name → count` map;
  logistic filters carry a `quality` field. Name-only comparisons silently merge
  qualities.
- `on_entity_damaged` is extremely high-frequency; always register it with event
  filters.

## 11. Third-party mod code policy

- **Never copy code or assets from any third-party repository or mod**, regardless of
  its license. Re-implement behavior from the Factorio API documentation.
- Reference other mods in code, docs, or comments only when The Reef directly depends on
  them (currently flib and PlanetsLib) or when the user explicitly directs otherwise.
  Avoid adopting techniques that are unique inventions of a single mod rather than
  ecosystem-wide conventions.
- **Do not clone or fetch third-party repositories on your own.** That is as-needed
  behavior, executed only when the user specifically instructs it.
- If the user asks to take, port, or adapt anything from another mod: first locate and
  read that mod's license document, present its terms to the user, and take no action
  with that repository until the user confirms.

## Maintenance note

flib's GitHub repository (factoriolib/flib) was archived in June 2025; raiguard's
projects migrated to Codeberg. When checking flib behavior or updates for The Reef,
check Codeberg for current development rather than the archived GitHub mirror.
