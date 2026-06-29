# The Reef — Claude Code Instructions

## Project Overview

The Reef is a Factorio 2.x / Space Age mod — a non-landable space-location (like Shattered Planet) with asteroid/scrap mechanics. Dependencies: flib, PlanetsLib.

## How to Use This Skill

**Do not preload the docs/ files.** Read them on demand when an error or unknown arises. Tool call results (Grep, Read, Bash) fade naturally via compaction; permanent @-loading costs tokens every session regardless of relevance.

**Workflow:**
1. Start work normally
2. When an error, unknown field name, or API question comes up → grep local game files or read the relevant doc section
3. Solve it, confirm the finding, add to `docs/common-errors.md` if reusable
4. Move on — the lookup fades, the finding stays

**When to start a new chat:**
- At the start of a new day/work session (CLAUDE.md reloads key context quickly)
- After a major phase is complete and direction changes significantly
- When you notice repeated mistakes or loss of earlier decisions (compaction has gone too far)
- When the session has been very long and responses feel less contextually aware

**When to stay in the same session:**
- Actively debugging a specific bug (context of the bug is valuable)
- Mid-feature where I have file contents and architecture in mind
- Rapid iteration cycles (error → fix → test → error)

## Reference Documentation

Available on demand in `docs/` — read these when specifically needed:
- `docs/prototype-cheatsheet.md` — confirmed prototype field names, subgroups, collision box sizing, recipe subgroups
- `docs/space-age-api.md` — Space Age runtime events, LuaSpacePlatform, asteroid spawning API
- `docs/common-errors.md` — confirmed error patterns from live development; check this before using any field or method that looks familiar from 1.x or training data

**When to read them:** when hitting an error that might be a known pattern, or when starting work on a prototype type covered in the cheatsheet.

## Source of Truth — Always Prefer Local Files

**Never guess field names, item names, entity names, event names, or API methods from training data.** Training data is stale and Factorio changes between versions.

Priority order for any unknown:
1. **Game files on disk:** `C:\Program Files (x86)\Steam\steamapps\common\Factorio\data\`
2. **Locally cached API JSON:** `.skill-scratch/runtime-api.json`, `.skill-scratch/prototype-api.json`
3. **Reference mod source:** `.skill-scratch/cerys/`, `.skill-scratch/maraxsis/` (these are local-only, not committed — for inspiration and pattern reference during The Reef development only)
4. **Skill docs:** `docs/common-errors.md`, `docs/prototype-cheatsheet.md`
5. **Ask the user** if nothing else confirms it

If a name cannot be confirmed from any of the above: say so and ask rather than guessing.

## Testing

Use the **reef-test scenario** (`scenarios/reef-test/`) instead of playing through the game. Launch from Factorio's main menu → Scenarios. It starts with all tech researched, legendary mech armor, and the player on a pre-built space platform with a stocked hub.

Update `scenarios/reef-test/control.lua` when adding new testable features.

**Setting up scenario world state visually:**
1. Start any save → `/editor` for free entity placement
2. Set up entities, tiles, and surfaces as desired
3. **File → Save As Scenario** saves the world state as the scenario base
4. `control.lua` handles quality items, research, inventory, and space platform creation (must be scripted via `force.create_space_platform`)

**Real-time log monitoring:** At the start of each session, ask the user whether to start the Factorio log monitor. If yes:
```
tail -f "C:/Users/nacus/AppData/Roaming/Factorio/factorio-current.log" | grep --line-buffered -E "Error|Script @__the-reef__|Received [0-9]|the-reef.*caused|non-recoverable"
```
Use `persistent = true`. This catches errors the moment they happen without needing the user to paste them.

## Key Constraints

- Target: Factorio 2.x / Space Age only — no 1.x compatibility shims
- The Reef is a `space-location` (outer areas) and `planet` (Ithaca) — verify type differences before writing prototypes
- Reference mods (Cerys, Maraxsis, Metal & Stars) are for local development inspiration only — their source code is not committed to this repo and must not be reproduced verbatim
- Check `docs/common-errors.md` before using any API method or prototype field that looks familiar from 1.x or training data

## Git

- Branch: `BUILD-1` (all commits go here, not main)
- Commit before starting any task; commit after completing it
- Push after each commit
