# The Reef — Claude Code Instructions

## Project Overview

The Reef is a Factorio 2.x / Space Age mod — a non-landable space-location (like Shattered Planet) with asteroid/scrap mechanics. Dependencies: flib, PlanetsLib.

## Reference Documentation

These files are generated from authoritative sources (Wube official data, Cerys, Maraxsis, Factorio Lua API). Consult them before writing any prototype definitions or runtime scripting — do not rely on training data for field names or API signatures.

@docs/prototype-cheatsheet.md
@docs/space-age-api.md
@docs/common-errors.md

## Testing

Use the **reef-test scenario** (`scenarios/reef-test/`) instead of playing through the game to test features. Launch it from Factorio's main menu → Scenarios. It starts with all tech researched, legendary mech armor equipped, and the player on a pre-built space platform with a stocked hub.

When adding new testable features, update `scenarios/reef-test/control.lua` to include the relevant items/entities.

**Setting up scenario world state visually:**
1. Start any save → `/editor` to open the map editor (free entity placement, no costs)
2. Arrange entities, tiles, and surfaces as desired
3. **File → Save As Scenario** saves the world state as the scenario base
4. `control.lua` handles anything the editor can't: quality items, research, inventory, scripted entity creation (space platforms must be created via `force.create_space_platform` — they can't be placed in the editor)

## Key Constraints

- Target: Factorio 2.x / Space Age only — no 1.x compatibility shims
- The Reef is a `space-location`, not a `planet` — verify field differences in prototype-cheatsheet.md before writing prototype definitions
- Check common-errors.md before using any API method or prototype field that looks familiar from 1.x
