# The Reef — Claude Code Instructions

## Project Overview

The Reef is a Factorio 2.x / Space Age mod — a non-landable space-location (like Shattered Planet) with asteroid/scrap mechanics. Dependencies: flib, PlanetsLib.

## Reference Documentation

These files are generated from authoritative sources (Wube official data, Cerys, Maraxsis, Factorio Lua API). Consult them before writing any prototype definitions or runtime scripting — do not rely on training data for field names or API signatures.

@docs/prototype-cheatsheet.md
@docs/space-age-api.md
@docs/common-errors.md

## Key Constraints

- Target: Factorio 2.x / Space Age only — no 1.x compatibility shims
- The Reef is a `space-location`, not a `planet` — verify field differences in prototype-cheatsheet.md before writing prototype definitions
- Check common-errors.md before using any API method or prototype field that looks familiar from 1.x
