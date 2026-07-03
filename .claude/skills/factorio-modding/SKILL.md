---
name: factorio-modding
description: Factorio 2.x / Space Age mod development. Use when writing or debugging Factorio mod code — prototypes (data stage), runtime scripting (control stage), space platforms, fluids, GUIs, or any Factorio API question. Codifies proven architectural patterns and verified engine constraints so agents compose native prototypes instead of improvising ad-hoc script solutions.
---

# Factorio 2.x / Space Age Modding

Scope: Factorio 2.x / Space Age only. No 1.x compatibility. Training-data knowledge of the Factorio API is stale and frequently wrong for 2.x — treat it as a rumor, not a source.

## Core paradigms (hard rules)

1. **Delegate to native prototypes. Never fight a prototype to do something it doesn't support.**
   Factorio ships 279 prototype classes, many of which solve problems you would otherwise script by hand (`proxy-container`, `storage-tank`, `pump`, `lane-splitter`, hidden crafters…). Before designing any new entity or scripted mechanic, read `references/prototype-index.md` and ask: *which native type already does most of this?* If the answer is "none, but I can script it," ask again.

2. **Compose entities; don't overload one.**
   When one visible machine needs several behaviors, build it as a **compound entity**: one visible shell plus hidden, uninteractable helper entities sharing its tile (a pump for the pipe connection, tanks for storage, an assembling machine for crafting). Each member is a native prototype doing exactly what it natively does; script only ferries between them. See `references/patterns.md` § Compound entity.

3. **Native game logic beats script reimplementation.**
   Crafting batches, fluid flow, circuit conditions, recipe icons/signals — the engine already does these correctly and for free. A script that reimplements crafting or polls state every tick when a circuit condition would do is a design smell. Reach for `on_tick` last, and throttle it when you must.

4. **Multiple fluid boxes on one entity, handled by anything other than the game's native crafting logic, is a red flag.**
   Crafting-machine fluid boxes are owned by the recipe system (filtered to and limited by the active recipe's fluid ingredients). If you need free-form fluid storage or routing, use `storage-tank` / `pump` entities and compose. See `references/constraints.md` § Fluids.

5. **Never guess identifiers.** Prototype names, field names, event names, icon paths, defines — all of them. A guessed name usually fails silently or crashes at load with no suggestion. If a name cannot be confirmed from the sources below, stop and ask.

## Verifying names and signatures (source-of-truth order)

1. **Game data on disk** — the Factorio install's `data/` directory (`base/`, `space-age/`), or a clone of `wube/factorio-data`. Authoritative for prototype field usage, entity names, subgroups, icon paths.
2. **API JSONs** — `runtime-api.json` and `prototype-api.json` from `https://lua-api.factorio.com/latest/`. Authoritative for classes, methods, events, defines, prototype schemas.
3. **Reference mod source** (well-maintained Space Age mods) — for patterns, not for field names.
4. **This skill's references** — distilled, verified findings.
5. **Ask the user.**

Querying the API JSONs:
- They ship **minified (single-line)**. Line-based grep is useless on them — pretty-print once (`python -c "import json; json.dump(json.load(open('runtime-api.json')), open('runtime-api.pretty.json','w'), indent=1)"`) and grep that, or query with a Python one-liner.
- **Method parameter order**: the `parameters` arrays are listed alphabetically; the real positional order is each parameter's `"order"` field (0 = first). Reading array position instead of `order` produces wrong-argument crashes (e.g. `insert_at_back(items, size)`, not `(size, items)`).
- `takes_table: false` means positional call, `true` means single named-table argument.

Runtime errors on Factorio's C++ objects (`LuaEntity`, `LuaSpacePlatform`, …) **throw on missing keys** instead of returning nil — an "doesn't contain key X" error means the member does not exist in 2.x, not that the object is empty.

## References (read on demand, not preloaded)

- `references/patterns.md` — proven architectural patterns: compound entities, one-pipe-any-fluid intake, hidden crafter, circuit gating, GUI conventions, output placement. **Read before designing any new machine.**
- `references/constraints.md` — verified engine constraints: fluids & crafting machines, entity placement, planets & space-locations, PlanetsLib, asteroid spawns, locale, assets.
- `references/breaking-changes-2x.md` — confirmed 1.x→2.x/2.1 renames and removals. **Check here first when a familiar-looking field or method errors.**
- `references/space-platforms.md` — platform mechanics, hub inventory access, platform events, runtime asteroid APIs, surface conditions.
- `references/prototype-index.md` — all 279 prototype classes, one line each. Scan before choosing a type for any new entity. Regenerate with `references/regenerate-prototype-index.ps1` if missing or stale.
- `references/graveyard.md` — approaches that are **known to fail**, with the verified reason. Check before attempting anything clever with fluid boxes or entity visibility.

## Maintaining this skill

When a new Factorio-specific error is diagnosed and fixed, file the finding in the same commit as the fix:

1. **Triage it**: a reusable *pattern* → `patterns.md`; a hard engine *constraint* → `constraints.md` (or `space-platforms.md`); a 1.x→2.x *rename/removal* → `breaking-changes-2x.md`; a dead-end *approach* → `graveyard.md`.
2. **Check for supersession**: does the finding contradict or obsolete an existing entry? Update or delete the old entry — never leave two entries that disagree.
3. **Only verified facts.** Every entry must be backed by a loader/runtime error message, confirmed in-game behavior, game data on disk, or the API JSONs. No speculation, and nothing project-specific — this skill must stay portable to any Factorio 2.x mod.
