# Runtime Scripting Discipline — Factorio 2.x Control Stage

Control-stage (runtime) rules for The Reef, identified by studying the most-downloaded
open-source Factorio mods as **research evidence of convergent, ecosystem-wide
patterns** — behaviors that many independent codebases arrived at separately because the
engine demands them.

**Citation convention:** where a third-party mod is named below, it is cited as
*evidence* — a place where a pattern was observed during research — never as code
provenance. **No code or assets from any third-party mod are included in The Reef or in
these docs**; every snippet is an original illustration. See §11 for the third-party
code policy and the end of this file for the evidence bibliography. Verify any specific
API signature against lua-api.factorio.com before relying on it.

---

## 1. Entity validity — the #1 crash class

"Fixed a crash when X was invalid" is the single most common changelog entry across
every mod studied.

- Any `LuaEntity`, `LuaPlayer`, `LuaSurface`, or `LuaGuiElement` held in `storage` across
  ticks can be invalidated by anything — other mods, biters, surface deletion. Check
  `.valid` **at point of use, every time** (Krastorio 2's tesla-coil script has ~20 such
  checks in one file). A small `destroy_if_valid()`-style helper keeps teardown honest.
- Item stacks have a **separate** predicate: `stack.valid_for_read`. A stack can be
  `.valid` (the slot exists) but not readable (empty); reading `.count`/`.name` then
  throws. Check both when inspecting inventories (observed in Krastorio 2's armor-slot
  handling).
- Surfaces get deleted out from under you (YARM shipped a fix for exactly this crash).
  Subscribe to `on_pre_surface_deleted`, `on_surface_cleared`, and `on_chunk_deleted`
  and purge the corresponding entries from `storage` — LTN and Rampant both converged
  on this. Space platforms are surfaces that players delete routinely — The Reef must
  handle this.
- Once bad references have been **saved**, fixing the code is not enough: ship a
  migration that scrubs already-corrupt `storage` in existing saves (Factorissimo 3
  ships such migrations alongside its fixes).

## 2. `storage` discipline (desyncs and save-breakage)

- **Never store functions in `storage`.** Functions in `storage` block saving in
  Factorio 2.0 and caused desyncs in earlier versions (YARM documents this in a source
  comment and ships a migration to strip them from old saves). If behavior must be
  scheduled or dispatched, store a plain string key and look the function up in a
  file-local registry at call time.
- Metatables on stored tables do not survive save/load. Re-attach them in `on_load`
  (Rampant's `on_load` exists almost entirely for this).
- `script.on_load` may **not** touch `game`. It is only for (a) rebuilding local
  caches/metatables from `storage` and (b) re-registering conditional event handlers
  (see §4).
- File-local (upvalue) caches of game-derived data are a desync minefield — Helmod's
  commit history contains at least seven separate multiplayer-desync fixes, mostly
  around a file-local tooltip cache diverging between clients. A local cache must be a
  pure, deterministically rebuilt function of game state — identical on every client;
  anything else belongs in `storage`.
- Deterministic RNG: for anything that must replay identically, create a dedicated
  generator with `game.create_random_generator(seed)` rather than relying on shared
  `math.random` state (Rampant does this mod-wide with a constant seed).

## 3. The event-completeness matrix

Entity tracking silently breaks unless you subscribe to the full set. LTN, Bottleneck,
and Krastorio 2 all converged on this matrix:

| Lifecycle | Events |
|---|---|
| Built | `on_built_entity`, `on_robot_built_entity`, `script_raised_built`, `script_raised_revive`, `on_entity_cloned`, and in 2.0 `on_space_platform_built_entity` |
| Removed | `on_pre_player_mined_item` (or `on_player_mined_entity`), `on_robot_pre_mined`, `on_entity_died`, `script_raised_destroy`, and in 2.0 `on_space_platform_mined_entity` |
| Surface | `on_pre_surface_deleted`, `on_surface_cleared`, `on_chunk_deleted` |

- Use **event filters** for UPS on the player/robot events (e.g.
  `{{filter="type", type="container"}}`, as LTN does for train stops); script-raised
  events do not support the same filtering and are registered unfiltered.
- Entities created by trigger effects (projectiles, spawning effects) fire none of the
  above reliably; `on_script_trigger_effect` is the hook for those (observed in
  Rampant). Tile changes by script arrive via `script_raised_set_tiles`.
- Be a good citizen in reverse: pass `raise_built = true` when script-creating
  *gameplay* entities so other mods see them (Krastorio 2 does); pass
  `raise_built = false` for internal/invisible helper entities (Factorissimo does), and
  give helper entities distinctive prefixed names so other mods can recognize and
  exclude them (Bottleneck maintains a blacklist for exactly such leaked helpers).
- Compound entities need explicit teardown of every hidden part, or the leftovers keep
  acting — a Krastorio 2 issue reported a removed tesla coil's hidden turret staying
  active and crashing the server.
- 2.0's `on_object_destroyed` fires only for objects you first registered via
  `script.register_on_object_destroyed(obj)`; map the returned `registration_number` in
  `storage` at registration time.

## 4. Conditional event handlers must be re-registered identically in `on_load`

Handler registration state must be a **pure function of `storage`**, or joining
multiplayer clients diverge from the server (desyncs or crashes). Put registration in
one function and call it from `on_init`, `on_load`, `on_configuration_changed`, and every
event that changes whether work is pending — including *de*-registering `on_nth_tick`
when the work queue empties. Auto Deconstruct and LTN both converged on this exact
single-registration-function structure, and Factorissimo's changelog records the
multiplayer bug that results from getting it wrong.

Related engine quirk: **`on_tick` can fire before `on_init`** on the first tick of a
multiplayer join (flib's `on-tick-n` module carries an explicit failsafe for this, and
Auto Deconstruct's changelog records the corresponding server crash). Nil-guard the
storage tables your tick handler touches.

## 5. One handler per event → use a dispatcher

`script.on_event` **replaces** any previously registered handler for that event. FNEI,
Helmod, Even Distribution, and Factorissimo each independently built a multi-handler
event bus: collect handler lists per event, compose them into one function, and register
that composite once. Route `on_init` and `on_configuration_changed` to the same
idempotent initializer. Adopt this before the mod grows multiple script modules, not
after.

GUI events fire for **all mods' elements**: check `event.element and event.element.valid`
first, then match `element.name` against your own prefix before acting.

## 6. UPS patterns

- **Per-tick work budgets, exposed as settings** ("entities per tick"-style, as in
  Bottleneck and YARM): bounded work per tick plus a resumable cursor in `storage`.
- flib's `table.for_n_of` (flib is a Reef dependency) is the canonical resumable
  iterator: pass `storage.from_k` back each tick. Note its defensive detail — it
  verifies the saved cursor key still exists (the table may have mutated between ticks)
  and restarts if not.
- **Cache entity reads in Lua tables.** Reading data off an entity crosses the Lua/C++
  boundary; YARM's source records a measurement of roughly 4× slower than reading a Lua
  table (Factorio 2.0.20). Poll entities on a budget in one place; have everything else
  read the cache.
- Scheduling without `on_tick`: flib's `on-tick-n` (task table keyed by target tick).
- Prefer blind writes over read-compare-write across the API boundary: setting a
  property unconditionally is often cheaper than reading it first to check (Bottleneck
  notes this for its indicator updates).
- Expensive work inside GUI event handlers runs in lockstep on **every** client in
  multiplayer — a Helmod issue reports one player's recipe selection freezing all other
  clients. Budget or defer it.

## 7. Migrations

- Use the standard layout: a `migrations/` directory — JSON files for prototype renames,
  Lua files plus `on_configuration_changed` for storage surgery. Five of the twelve
  mods studied ship one.
- flib's `migration` module implements the standard version dance: zero-pad version
  strings (`"%02d"` per segment) so plain string comparison orders them, then run an
  ordered `version → function` table.
- If a save is too old to migrate safely, **refuse** with a clear player-facing message
  instead of corrupting state (LTN's approach).

## 8. Localised strings and translations

- **Localised strings are capped at 20 parameters**; exceeding it is a runtime error
  that typically only surfaces when data grows large (Helmod hit it at least three
  times). Nest parameters in sub-tables — each nested localised string gets its own
  budget of 20.
- Runtime translation (`request_translation`) is asynchronous and per-player: you need a
  *connected* player per locale to act as translator; requests can be lost and need
  re-requesting after a timeout; results arrive over many ticks and must be batched; and
  unthrottled translation floods can drop slow multiplayer clients (FNEI added a
  throttle setting for exactly this). flib's `dictionary` module (already a dependency)
  handles all of this — use it rather than hand-rolling.

## 9. Cross-mod compatibility

- **Data stage:** never assume another mod's prototype exists. Check
  `data.raw[type][name]` before touching it, gate optional tweaks on the prototype's
  existence (Squeak Through guards every tweak this way), and `error()` with a clear
  message when a hard assumption fails.
- **Runtime:** gate on `script.active_mods["mod-name"]`, and probe
  `remote.interfaces["x"] and remote.interfaces["x"]["fn"]` before calling (LTN does
  both before every cross-mod call).
- Other mods will want to interact with The Reef the same way: design a small, stable
  `remote.add_interface` early.

## 10. Engine quirks confirmed in the wild

- Fluid amounts round **down to 0** in circuit/wait conditions while fractional residue
  remains: an `= 0` fluid condition must be expressed as an "empty"-style condition
  instead (LTN carries an explicit workaround comment for this).
- `ItemInventoryPositions.stack` (item request proxy insert plans) is **0-indexed** in
  an otherwise 1-indexed API (Factorissimo 3 flags this in a comment). Verify indexing
  per field, not per API.
- Factorio 2.0 quality changed inventory API shapes: `LuaInventory.get_contents()` now
  returns an array of `{name, count, quality}` records, not a `name → count` map;
  logistic filters carry a `quality` field. Name-only comparisons silently merge
  qualities (Even Distribution's 2.0 port had to fix exactly this).
- `on_entity_damaged` is extremely high-frequency; always register it with event
  filters.

## 11. Third-party mod code policy

- **Never copy code or assets from any third-party repository or mod**, regardless of
  its license. Re-implement behavior from the Factorio API documentation.
- Reference other mods in code, docs, or comments only when The Reef directly depends on
  them (currently flib and PlanetsLib), as evidence citations per the convention at the
  top of this file, or when the user explicitly directs otherwise. Avoid adopting
  techniques that are unique inventions of a single mod rather than ecosystem-wide
  conventions.
- **Do not clone or fetch third-party repositories on your own.** That is as-needed
  behavior, executed only when the user specifically instructs it.
- If the user asks to take, port, or adapt anything from another mod: first locate and
  read that mod's license document, present its terms to the user, and take no action
  with that repository until the user confirms.

## Evidence bibliography

Mods studied (2026-07) as evidence of convergent patterns — **observed, never copied**.
Licenses noted both for the record and as a reminder of why copying is off the table:

| Mod | Author(s) | License |
|---|---|---|
| Auto Deconstruct | softmix (portal: mindmix) | MIT |
| Bottleneck | troelsbjerre (portal: trold) | MIT |
| Even Distribution | 321freddy | none published — all rights reserved |
| FNEI | npo6ka | none published — all rights reserved |
| Factorissimo2 / Factorissimo 3 | MagmaMcFry; fork by notnotmelon | MIT |
| Helmod | Helfima | MIT |
| Krastorio 2 | Krastor & Linver; 2.0 port by raiguard | LGPL-3.0 |
| Logistic Train Network (LTN) | Optera | custom — no derived-code distribution without permission |
| Rampant | veden | GPL-3.0 |
| Squeak Through | Supercheese | GPL-3.0 |
| YARM | Octav "narc" Sandulescu (narc0tiq) | MIT |
| flib (Reef dependency) | raiguard | MIT |

## Maintenance note

flib's GitHub repository (factoriolib/flib) was archived in June 2025; raiguard's
projects migrated to Codeberg. When checking flib behavior or updates for The Reef,
check Codeberg for current development rather than the archived GitHub mirror.
