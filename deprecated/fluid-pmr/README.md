# Fluid PMR — Deprecated

Scrapped 2026-07-01. Superseded by no replacement yet; kept here for reference
only. Not loaded by the mod — `data.lua` and `control.lua` no longer require
any of these files.

## What it was

A 3×3 `storage-tank`-based machine (`fluid-pmr`) that accepted one fluid input
on its west face and produced items on the east-adjacent tile, driven entirely
by script (`scripts/fluid_pmr.lua`) rather than the native crafter. Storage
tanks were used instead of `assembling-machine`/`chemical-plant` because those
entity types filter fluid boxes to the active recipe's ingredient, making
"one pipe that accepts multiple fluid types" impossible — see
`.claude/skills/factorio-modding/references/constraints.md` (§ Fluids) and
`graveyard.md` there for the confirmed API constraints this ran into.

Status at the time of removal: built but untested (see `HANDOFF.md` history —
last push before removal was 407a7bc).

## Files in this bundle

- `entity.lua` — entity prototype block, extracted from `prototypes/entities.lua`
- `item.lua` — item prototype block, extracted from `prototypes/items.lua`
- `recipe.lua` — building + n/a recipe block, extracted from `prototypes/recipes.lua`
- `technology.lua` — full technology prototype, moved from `prototypes/technologies/the-reef-fluid-pmr.lua`
- `fluid_pmr.lua` — full runtime script, moved from `scripts/fluid_pmr.lua`
- `control-hooks.lua` — the `control.lua` snippets that wired the script into events (reference only, not a requirable module)
- `locale.cfg` — the `locale/en/mod.cfg` lines that named `fluid-pmr` entity/item/recipe/technology

## To fully resurrect

1. Re-add the four prototype fragments to their original files (or `require` this folder directly).
2. Re-add `require("prototypes.technologies.the-reef-fluid-pmr")` to `data.lua`.
3. Re-add the `fluid_pmr` require/dispatch lines to `control.lua` (see `control-hooks.lua`).
4. Re-add the locale lines to `locale/en/mod.cfg`.
