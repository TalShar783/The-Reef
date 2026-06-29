# The Reef — Claude Code Instructions

## Project Overview

The Reef is a Factorio 2.x / Space Age mod — a non-landable space-location (like Shattered Planet) with asteroid/scrap mechanics. Dependencies: flib, PlanetsLib.

## How to Use This Skill

**Do not preload the docs/ files.** Read them on demand when an error or unknown arises. Tool call results (Grep, Read, Bash) fade naturally via compaction; permanent @-loading costs tokens every session regardless of relevance.

**Session start (always, automatically, before responding to any task):**
1. Check if `HANDOFF.md` exists in the repo root — if so, read it immediately and silently incorporate its state. Do not wait for the user to mention it.
2. Ask the user if they want the Factorio log monitor started.
3. Then proceed with whatever the user asks.

**Workflow:**
1. Work normally; when an error or unknown arises, grep local game files or read the relevant doc section
2. Solve it, add confirmed findings to `docs/common-errors.md`, move on

**Handoff system:**
At every natural stopping point (phase complete, end of day, pre-restart), write `HANDOFF.md` in the repo root:
```
# The Reef — Session Handoff
Current phase: [e.g. Phase 4 complete, starting Phase 5]
Branch: BUILD-1
Last decisions: [3-5 bullet points of what was just decided/built]
Next immediate step: [single clear next action]
Open questions: [anything unresolved]
Recent gotchas: [any new common-errors.md entries worth highlighting]
```
HANDOFF.md is gitignored and ephemeral. The PreCompact hook backs it up; the PostCompact hook injects it back into context after compaction. Delete it when starting a genuinely new phase.

**Suggest a handoff-and-restart** when:
- A feature or phase just completed cleanly
- The session has been long and responses are feeling less specific
- The user is about to switch to a significantly different area of the mod
- After a series of rapid error-fix cycles that created a lot of noise in context

**Compaction vs new session:**
- `/compact` = same session continues with compressed history. Use mid-feature. HANDOFF.md is injected back automatically via PostCompact hook.
- New conversation window = truly fresh. CLAUDE.md reloads. Better for phase transitions or next-day starts. Read HANDOFF.md explicitly at the start.

**When to stay in the same session:**
- Actively debugging a specific bug
- Mid-feature with file contents and architecture in mind
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

## Space Platform Mechanics — Do Not Apply Surface Rules Here

Space platforms are a fundamentally different environment from planet surfaces. Before designing or reasoning about anything platform-related, apply these rules:

**What does NOT exist on space platforms:**
- Roboports, construction/logistic robots, logistic networks — none of these can be placed on platforms. There is no logistic network on a platform at all.
- Vanilla chests (wooden, iron, steel, all logistic chest variants) — Space Age data-updates adds a gravity > 0.1 condition to all of them, blocking placement on platforms (gravity = 0). Any container placed on a platform must explicitly set `surface_conditions` to allow gravity = 0.
- Cargo rockets and cargo pods — these travel between a platform and a planet surface only. There is no rocket-based transfer between two platforms.

**How platform inventory actually works:**
- The `space-platform-hub` entity holds the platform's shared cargo inventory. Everything on the platform is logistically connected through it.
- Inserters on a platform pull from and push to the hub inventory directly.
- In 2.1, inserters and machines with "enable logistic connection" wirelessly read the hub's contents (analogous to reading a logistic network on a surface, but the hub replaces the network). This is not the same as logistic chests existing on the platform.

**Platform-to-platform transfer (2.1):**
- Platforms can request items from other platforms via the orbital request system when they are in orbit of the same body.
- This is the only mechanism for platform-to-platform item transfer. It does not involve rockets or cargo pods.

**Non-landable space locations (The Reef, Lethe Point, Shattered Planet):**
- These have no surface. Players cannot land there, build there, or send cargo rockets there.
- Platforms orbit there and interact with the location's asteroid/resource mechanics from orbit.
- Lethe Point specifically exists for platform-to-platform exchange using the 2.1 orbital request system. No surface structures, no rockets, no landing pads.

**When designing platform structures for The Reef:**
- Always check `surface_conditions` — any custom entity that should be platform-placeable needs `gravity = 0` (max = 0).
- The hub is the inventory source of truth. Scripts that read platform cargo use `surface.find_entities_filtered({ type = "space-platform-hub" })[1].get_inventory(1)`.
- Do not assume any surface-side logistics mechanic (belts excepted) transfers to platform design.

## Key Constraints

- Target: Factorio 2.x / Space Age only — no 1.x compatibility shims
- The Reef is a `space-location` (outer areas) and `planet` (Ithaca) — verify type differences before writing prototypes
- Reference mods (Cerys, Maraxsis, Metal & Stars) are for local development inspiration only — their source code is not committed to this repo and must not be reproduced verbatim
- Check `docs/common-errors.md` before using any API method or prototype field that looks familiar from 1.x or training data

## Git

- Branch: `BUILD-1` (all commits go here, not main)
- **Commit AND push before starting any task. Commit AND push after completing it.**
- Never batch multiple tasks into one commit — one commit per task, before and after
- Push immediately after every commit, no exceptions
