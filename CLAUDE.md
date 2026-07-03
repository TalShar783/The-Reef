# The Reef — Claude Code Instructions

## Project Overview

The Reef is a Factorio 2.x / Space Age mod — a non-landable space-location (like Shattered Planet) with asteroid/scrap mechanics, plus the Ithaca planet. Dependencies: flib, PlanetsLib.

## Factorio Modding Skill

All general Factorio 2.x knowledge lives in `.claude/skills/factorio-modding/` — read `SKILL.md` before writing any mod code, and its `references/` on demand:

- `patterns.md` — read **before designing any new machine or mechanic**
- `breaking-changes-2x.md` — check **first** when a familiar-looking field/method errors
- `constraints.md`, `space-platforms.md` — verified engine facts by domain
- `prototype-index.md` — scan before choosing a prototype type for any new entity
- `graveyard.md` — known-dead approaches; check before anything clever with fluid boxes or entity visibility

When a new Factorio-specific error is diagnosed, file the finding per SKILL.md § Maintaining this skill, **in the same commit as the fix**. Keep the skill project-agnostic — Reef-specific state belongs here or in HANDOFF.md.

## Local Source Material (for the skill's verification workflow)

- **Game files:** `C:\Program Files (x86)\Steam\steamapps\common\Factorio\data\`
- **API JSONs:** `.skill-scratch/runtime-api.json`, `.skill-scratch/prototype-api.json` (minified — do not grep these directly) and pretty-printed greppable copies `.skill-scratch/*.pretty.json`. If the pretty copies are missing, regenerate: `python -c "import json; [json.dump(json.load(open(f'.skill-scratch/{n}.json')), open(f'.skill-scratch/{n}.pretty.json','w'), indent=1) for n in ('runtime-api','prototype-api')]"`
- **Reference mods:** `.skill-scratch/cerys/`, `.skill-scratch/maraxsis/`, etc. — local-only, not committed; for pattern inspiration during The Reef development, never reproduced verbatim.

To repopulate `.skill-scratch/` on a fresh clone:
```bash
git clone --depth=1 https://github.com/wube/factorio-data.git .skill-scratch/factorio-data
git clone --depth=1 https://github.com/notnotmelon/maraxsis.git .skill-scratch/maraxsis
git clone --depth=1 https://github.com/danielmartin0/Cerys-Moon-of-Fulgora.git .skill-scratch/cerys
curl -s https://lua-api.factorio.com/latest/runtime-api.json -o .skill-scratch/runtime-api.json
curl -s https://lua-api.factorio.com/latest/prototype-api.json -o .skill-scratch/prototype-api.json
```
Then generate the pretty-printed copies (command above).

## Session Start (always, automatically, before responding to any task)

1. If `HANDOFF.md` exists in the repo root, read it immediately and silently incorporate its state.
2. Then proceed with whatever the user asks.

## Handoff System

At every natural stopping point (phase complete, end of day, pre-restart), write `HANDOFF.md` in the repo root:

```
# The Reef — Session Handoff
Current phase: [...]
Branch: BUILD-1
Last decisions: [3-5 bullets]
Next immediate step: [single clear action]
Open questions: [anything unresolved]
Recent gotchas: [new skill entries worth highlighting]
```

HANDOFF.md is gitignored and ephemeral; the PreCompact/PostCompact hooks back it up and re-inject it. Delete it when starting a genuinely new phase.

**Suggest a handoff-and-restart** when a feature/phase completes cleanly, the session is long and responses feel less specific, the user is switching to a different area of the mod, or after noisy error-fix cycles. `/compact` = same session, mid-feature; new window = fresh start for phase transitions (read HANDOFF.md explicitly).

## Testing

Use the **reef-test scenario** (`scenarios/reef-test/`) — launched from Factorio's main menu → Scenarios. All tech researched, legendary mech armor, player on a pre-built platform with stocked hub. Update `scenarios/reef-test/control.lua` when adding new testable features.

Scenario world state is set up visually: any save → `/editor` → build → File → Save As Scenario; `control.lua` scripts research/inventory/platform creation (`force.create_space_platform`).

**Do not tail or hold open `factorio-current.log`** — it locks the file and blocks the user from launching Factorio. Ask the user to paste log output, or read the file after the game closes.

**Do not self-test in-game.** Fix load errors, then hand off to the user for manual verification.

## Reef-Specific Design Facts

- The Reef is a `space-location` (outer areas) plus a `planet` (Ithaca).
- **Lethe Point** is a non-landable space-location existing for platform-to-platform exchange via the 2.1 orbital request system — no surface structures, no rockets, no landing pads.

## Scope Discipline

Research broadly; implement narrowly and literally. When told to do something, do it in the most straightforward way that satisfies the literal request — no extra verification scaffolding, workarounds, or scope expansion. If an instruction looks like it will fail, flag the concern once, briefly, then proceed as instructed. No unrequested side-effect actions (launching the game, background monitors) unless explicitly asked. Surface blockers and unknowns immediately instead of silently improvising.

## Git

- Branch: `BUILD-1` (all commits go here, not main)
- **Commit AND push before starting any task. Commit AND push after completing it.**
- One commit per task — never batch; push immediately after every commit, no exceptions.
