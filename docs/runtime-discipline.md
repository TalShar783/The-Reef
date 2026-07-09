# Runtime Scripting Discipline — Lessons from the Top Factorio Mods

Extracted from the source code, commit history, and issue trackers of the most-downloaded
open-source Factorio mods: Squeak Through, Even Distribution (321freddy), FNEI, Bottleneck,
Auto Deconstruct, Helmod, LTN, Factorissimo2 + Factorissimo 3 (notnotmelon fork),
Krastorio 2, Rampant, YARM, and flib. Every claim below cites where it was observed.
These are **control-stage** (runtime) lessons; the other docs in this folder cover the
data stage.

---

## 1. Entity validity — the #1 crash class

"Fixed a crash when X was invalid" is the single most common changelog entry across all
twelve mods. Rules:

- Any `LuaEntity`, `LuaPlayer`, `LuaSurface`, or `LuaGuiElement` held in `storage` across
  ticks can be invalidated by anything — other mods, biters, surface deletion. Check
  `.valid` **at point of use, every time**. Krastorio 2's `scripts/tesla-coil.lua` has
  ~20 such checks in one file and wraps teardown in a `destroy_if_valid()` helper.
- Item stacks have a **separate** predicate: `stack.valid_for_read`. A stack can be
  `.valid` (the slot exists) but not readable (empty). K2 checks both when inspecting
  armor slots.
- Surfaces get deleted out from under you. YARM crashed on it (issue #144, "Fix crash
  from surface being deleted"); LTN and Rampant subscribe to `on_pre_surface_deleted`,
  `on_surface_cleared`, and `on_chunk_deleted` to purge their storage. Space platforms
  are surfaces that players delete routinely — The Reef must handle this.
- Once bad references have been **saved**, fixing the code is not enough: Factorissimo 3
  shipped fixes together with migrations that scrub already-corrupt storage ("added a
  migration to remove invalid target data", issue #182).

## 2. `storage` discipline (desyncs and save-breakage)

- **Never store functions in `storage`.** YARM documents the war story in `resmon.lua`:
  keeping an `iter_fn` in a stored site table "blocks saving in Factorio 2.0 and would
  have possibly also led to some mysterious desyncs in previous Factorio versions."
  Factorissimo's delayed-function system stores only *string keys* into a local function
  registry, never function values.
- Metatables on stored tables do not survive save/load. Re-attach them in `on_load`
  (Rampant's `onLoad` exists almost entirely for this).
- `script.on_load` may **not** touch `game`. It is only for (a) rebuilding local
  caches/metatables from `storage` and (b) re-registering conditional event handlers
  (see §4).
- File-local (upvalue) caches of game-derived data are a desync minefield. Helmod's
  history contains at least seven separate multiplayer-desync fixes, mostly around its
  file-local tooltip cache diverging between clients ("Fixed desync (tooltip cache)",
  "Fixed MP desynch when open selector"). Rule: a local cache must be a pure,
  deterministically rebuilt function of game state; anything else belongs in `storage`.
- Deterministic RNG: for anything that must replay identically, Rampant seeds a
  dedicated generator — `game.create_random_generator(CONSTANT_SEED)` (`libs/Upgrade.lua`)
  — rather than relying on shared `math.random` state.

## 3. The event-completeness matrix

Entity tracking silently breaks unless you subscribe to the full set. LTN's
`registerEvents()` (`script/init.lua`) is the canonical form:

| Lifecycle | Events |
|---|---|
| Built | `on_built_entity`, `on_robot_built_entity`, `script_raised_built`, `script_raised_revive`, `on_entity_cloned`, and in 2.0 `on_space_platform_built_entity` |
| Removed | `on_pre_player_mined_item` (or `on_player_mined_entity`), `on_robot_pre_mined`, `on_entity_died`, `script_raised_destroy`, and in 2.0 `on_space_platform_mined_entity` |
| Surface | `on_pre_surface_deleted`, `on_surface_cleared`, `on_chunk_deleted` |

- Use **event filters** for UPS on the player/robot events
  (`{{filter="type", type="train-stop"}}` in LTN); script-raised events are registered
  unfiltered.
- Rampant additionally handles `script_raised_set_tiles`, and uses
  `on_script_trigger_effect` to detect entities created by trigger effects — the only
  reliable hook for projectile/effect-spawned entities.
- Be a good citizen in reverse: pass `raise_built = true` when script-creating
  *gameplay* entities so other mods see them (K2 `scripts/shelter.lua`,
  `planetary-teleporter.lua`); pass `raise_built = false` for internal/invisible helper
  entities (Factorissimo's belt/heat connectors). Give helper entities distinctive
  prefixed names — Bottleneck maintains a name blacklist (`factory-port-marker`) for
  helper entities that leak into its scans anyway.
- Compound entities need explicit teardown of every hidden part. K2 issue: "tesla-coil
  stays active after removal, getting close crashes server."
- 2.0's `on_object_destroyed` fires only for objects you first registered via
  `script.register_on_object_destroyed(obj)`; map the returned `registration_number` in
  `storage` at registration time (Factorissimo `lib/events.lua`).

## 4. Conditional event handlers must be re-registered identically in `on_load`

Handler registration state must be a **pure function of `storage`**, or joining
multiplayer clients diverge from the server. AutoDeconstruct calls one
`update_tick_event()` from `on_init`, `on_load`, `on_configuration_changed`, and every
event that changes whether work is pending; LTN re-registers its `on_nth_tick`
dispatcher in `on_load` based on stored state. Factorissimo changelog: "Actually fix the
multiplayer error this time. (Properly disable on_nth_tick event when queue is empty.)"

Related engine quirk: **`on_tick` can fire before `on_init`** on the first tick of a
multiplayer join (flib `on-tick-n` carries an explicit failsafe; AutoDeconstruct
changelog: "Avoid a server crash on first multiplayer player join (tick 0 on_tick before
on_init)"). Nil-guard the storage tables your tick handler touches.

## 5. One handler per event → use a dispatcher

`script.on_event` **replaces** any previously registered handler for that event. FNEI,
Helmod, Even Distribution, and Factorissimo each independently built a multi-handler
event bus. Factorissimo's `lib/events.lua` is the cleanest: collect handler lists per
event, compose them into one function, register once via `finalize_events()`. Its bus
also routes `on_init` and `on_configuration_changed` to the same idempotent initializer —
a pattern nearly every mod follows. Adopt this before the mod grows multiple script
modules, not after.

GUI events fire for **all mods' elements**: check `event.element and event.element.valid`
first, then match `element.name` against your own prefix before acting (Factorissimo's
GUI router pattern-matches element names).

## 6. UPS patterns

- **Per-tick work budgets, exposed as settings**: Bottleneck's
  `bottleneck-signals-per-tick`, YARM's `YARM-entities-per-tick`, FNEI's translation
  speed setting (added to "avoid multiplayer drops for those with slow internet").
  Bounded work per tick + a resumable cursor in `storage`.
- flib `table.for_n_of` is the canonical resumable iterator: pass `storage.from_k` back
  each tick. Note its defensive detail — it verifies the saved cursor key still exists
  (the table may have mutated between ticks) and restarts if not.
- **Cache entity reads in Lua tables.** YARM's `libs/ore_tracker.lua` header records a
  measurement on Factorio 2.0.20: reading from a Lua table is ~4× faster than reading
  the same data off an entity (Lua/C++ boundary). Their design: one module polls
  entities on a budget; everything else reads the cache.
- Scheduling without `on_tick`: flib `on-tick-n` (task table keyed by target tick), or
  Factorissimo's trick — create an invisible render object with `time_to_live = N`,
  register it with `register_on_object_destroyed`, and treat the resulting
  `on_object_destroyed` as the timer callback.
- Prefer blind writes over read-compare-write across the API boundary: Bottleneck
  changes `graphics_variation` unconditionally — "Faster to just change the color than
  it is to check it first."
- Expensive work inside GUI event handlers runs in lockstep on **every** client: Helmod
  issue "Selecting a recipe freezes other clients in multiplayer." Budget or defer it.

## 7. Migrations

- Five of the twelve mods ship a `migrations/` directory. Pattern: JSON files for
  prototype renames, Lua files + `on_configuration_changed` for storage surgery.
- flib `migration` implements the standard version dance: zero-pad version strings
  (`"%02d"` per segment) so plain string comparison orders them, then run an ordered
  `version → function` table.
- LTN **refuses** migration from too-old versions with a clear player-facing message
  instead of corrupting state ("Oldest supported version: 1.1.1").

## 8. Localised strings and translations

- **Localised strings are capped at 20 parameters.** Helmod hit "Too many parameters for
  localised string 21 < 20 (limit)" at least three times. Fix: nest parameters in
  sub-tables — each nested localised string gets its own budget of 20.
- Runtime translation (`request_translation`) is asynchronous and per-player. flib's
  `dictionary` module encodes the constraints: you need a *connected* player per locale
  to act as translator; requests can be lost (flib re-requests after 5 seconds); results
  arrive over many ticks and must be batched; unthrottled translation floods can drop
  slow multiplayer clients (FNEI added a speed setting for exactly this).

## 9. Cross-mod compatibility

- **Data stage:** never assume another mod's prototype exists. Squeak Through guards
  every exclusion with `apply_when_object_exists`; K2 fixed "crash when another mod
  removes one of the default radioactive items." Check `data.raw[type][name]` before
  touching it, and `error()` with a clear message when a hard assumption fails
  (K2 `data-util.lua`).
- **Runtime:** gate on `script.active_mods["mod-name"]`, and probe
  `remote.interfaces["x"] and remote.interfaces["x"]["fn"]` before calling (LTN does
  this for Creative Mode and Picker Dollies).
- Factorissimo 3 ships a `compat/` directory with one file per neighboring mod —
  including `cerys.lua` and `maraxsis.lua`. When The Reef ships, other mods will
  interact with it the same way: design a small, stable `remote.add_interface` early
  (Factorissimo added one on request, issue #168).

## 10. Engine quirks confirmed in the wild

- Fluid amounts round **down to 0** in circuit/wait conditions: LTN's dispatcher has an
  explicit workaround — an `= 0` fluid condition must be rewritten as an "empty" wait
  condition (`script/dispatcher.lua`).
- `ItemInventoryPositions.stack` (item request proxy insert plans) is **0-indexed** in
  an otherwise 1-indexed API — Factorissimo: "inventory_locator.stack is 0-indexed for
  some reason. adjust." Verify indexing per field, not per API.
- Factorio 2.0 quality changed inventory API shapes: `LuaInventory.get_contents()` now
  returns an array of `{name, count, quality}` records, not a `name → count` map;
  logistic filters carry a `quality` field. Name-only comparisons silently merge
  qualities (Even Distribution's 2.0 port, "Temporary quality fix" commit).
- `on_entity_damaged` is extremely high-frequency; always register it with event
  filters.

## Sources, licenses, and attribution

This document describes facts, bug patterns, and engineering techniques observed in the
mods below. It contains **no copied source code**: every code snippet in these docs is an
original illustration, and the only verbatim material is short, attributed quotations of
code comments, changelog entries, and commit messages, used as citations. Documenting
facts and techniques does not make The Reef a derivative work of these mods. The license
obligations below apply only if actual code is ever copied or adapted into The Reef:

| Mod | Author(s) | License | If code were ever copied |
|---|---|---|---|
| Auto Deconstruct | softmix (portal: mindmix) | MIT | keep copyright + license notice |
| Bottleneck | troelsbjerre (portal: trold) | MIT | keep copyright + license notice |
| Even Distribution | 321freddy | **no license file** — all rights reserved by default | do not copy; ask the author |
| FNEI | npo6ka | **no license file** — all rights reserved by default | do not copy; ask the author |
| Factorissimo2 | MagmaMcFry | MIT | keep copyright + license notice |
| Factorissimo 3 (notnotmelon fork) | notnotmelon (© MagmaMcFry) | MIT | keep copyright + license notice |
| Helmod | Helfima | MIT | keep copyright + license notice |
| Krastorio 2 | Krastor & Linver; 2.0 port maintained by raiguard | LGPL-3.0 | LGPL copyleft terms apply |
| LTN (Logistic Train Network) | Optera | Custom: no distributing modified/derived code without written permission; no commercial use | **never copy**; written permission required |
| Rampant | veden | GPL-3.0 | GPL copyleft terms apply |
| Squeak Through | Supercheese | GPL-3.0 | GPL copyleft terms apply |
| YARM | Octav "narc" Sandulescu (narc0tiq) | MIT | keep copyright + license notice |
| flib | raiguard | MIT | keep copyright + license notice |

In particular: **never copy or adapt LTN, FNEI, or Even Distribution code into The Reef.**
Re-implement any needed behavior from the Factorio API documentation. GPL/LGPL code
(Rampant, Squeak Through, Krastorio 2) may only be adapted if The Reef accepts the
corresponding copyleft obligations — prefer re-implementation here too.

### Credit for distinctive techniques

Most patterns in this document evolved convergently across many mods (validity checking,
the event matrix, per-tick budgets, migrations) and are credited inline where observed.
A few appear to be the invention of a specific author and deserve explicit credit:

- **Render-object TTL timer** (invisible render object with `time_to_live = N` +
  `register_on_object_destroyed` as a tick scheduler) and the **string-keyed delayed
  function registry** — notnotmelon, Factorissimo 3 (`lib/events.lua`).
- **`for_n_of` resumable iterator, `on-tick-n` scheduler, and the `dictionary`
  translation framework** — raiguard, flib.
- **Ore-tracker entity cache** and the published ~4× Lua-table-vs-entity read
  measurement — Octav "narc" Sandulescu, YARM (`libs/ore_tracker.lua`).
- **`apply_when_object_exists` conditional-exclusion config** — Supercheese,
  Squeak Through.
- **The canonical event-registration matrix and the fluid-residue `= 0` workaround** —
  Optera, LTN (described here factually; see license note above).
- **Dedicated deterministic RNG** (`game.create_random_generator` with a constant seed)
  as a mod-wide discipline — veden, Rampant.

## Maintenance note

flib's GitHub repository (factoriolib/flib) was archived in June 2025; raiguard's
projects migrated to Codeberg. When checking flib behavior or updates for The Reef,
check Codeberg for current development rather than the archived GitHub mirror.
