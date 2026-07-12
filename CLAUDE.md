# The Reef — Claude Code Instructions

## ⚠ SETUP TODO — not yet done (added 2026-07-09)

`build-factorio-skill.sh` has never actually been run against real Wube source
data on this machine — the docs it produces (`prototype-cheatsheet.md`,
`space-age-api.md`, `common-errors.md`) were written without it, so their
"unverified" callouts are more numerous than they should be. Before the next
significant coding session:

1. Populate `.skill-scratch/` manually per the script's requirements (see
   `build-factorio-skill.sh` header comments), or let the script clone
   `factorio-data` itself if you confirm that's acceptable.
2. Run `bash build-factorio-skill.sh` and review the regenerated docs.
3. Delete this section once done.

## Project Overview

The Reef is a Factorio 2.x / Space Age mod — a non-landable space-location (like Shattered Planet) with asteroid/scrap mechanics. Dependencies: flib, PlanetsLib.

## Reference Documentation

The first three files are generated from first-party sources (Wube's official factorio-data and the Factorio Lua API); runtime-discipline.md is hand-maintained. Where any doc names a third-party mod, that is an evidence citation — a convergent pattern observed during research — never code provenance; no third-party code or assets are copied (see runtime-discipline.md §11). Consult these docs before writing any prototype definitions or runtime scripting — do not rely on training data for field names or API signatures.

@docs/prototype-cheatsheet.md
@docs/space-age-api.md
@docs/common-errors.md
@docs/runtime-discipline.md

## Key Constraints

- Target: Factorio 2.x / Space Age only — no 1.x compatibility shims
- The Reef is a `space-location`, not a `planet` — verify field differences in prototype-cheatsheet.md before writing prototype definitions
- Check common-errors.md before using any API method or prototype field that looks familiar from 1.x
- Follow runtime-discipline.md for all control-stage code: entity validity, `storage` rules, the full built/removed event matrix, `on_load` re-registration, and per-tick work budgets
- **Never copy code or assets from any third-party repository or mod.** If the user asks to take, port, or adapt anything from another mod, first locate and read that mod's license document, present its terms to the user, and take no action with that repository until the user confirms
- **Do not clone or fetch third-party repositories on your own** — only when the user specifically instructs it. build-factorio-skill.sh clones Wube's official first-party `factorio-data` repo into `.skill-scratch/` when run (that clone is pre-authorized by this instruction); it never clones or fetches any third-party mod repository
- Reference other mods only when The Reef directly depends on them (flib, PlanetsLib) or the user directs otherwise; avoid adopting techniques unique to a single mod rather than ecosystem-wide conventions
- Dependency note: flib's GitHub repo was archived in June 2025 — check Codeberg (raiguard) for current flib development
