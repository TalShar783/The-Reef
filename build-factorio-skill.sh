#!/usr/bin/env bash
# build-factorio-skill.sh
#
# Run this from the the-reef repo root with Claude Code.
# Clones reference sources, feeds them to Claude, and writes four docs:
#   docs/prototype-cheatsheet.md
#   docs/space-age-api.md
#   docs/common-errors.md
#   docs/runtime-discipline.md   (mined from the top-downloaded open-source mods)
#
# Usage:
#   bash build-factorio-skill.sh
#
# Requirements: git, curl, node (for npx), internet access.

set -euo pipefail

REPO_ROOT="$(pwd)"
SCRATCH="$REPO_ROOT/.skill-scratch"
OUT="$REPO_ROOT/docs"

mkdir -p "$SCRATCH" "$OUT"

echo "=== Step 1: Clone reference sources ==="

# Wube's official base + Space Age data (authoritative prototype definitions)
if [ ! -d "$SCRATCH/factorio-data" ]; then
  git clone --depth=1 https://github.com/wube/factorio-data.git "$SCRATCH/factorio-data"
else
  echo "factorio-data already cloned, skipping."
fi

# Maraxsis — gold-standard Space Age planet mod
if [ ! -d "$SCRATCH/maraxsis" ]; then
  git clone --depth=1 https://github.com/notnotmelon/maraxsis.git "$SCRATCH/maraxsis"
else
  echo "maraxsis already cloned, skipping."
fi

# Cerys — space-location mod, closest structural analog to The Reef
if [ ! -d "$SCRATCH/cerys" ]; then
  git clone --depth=1 https://github.com/danielmartin0/Cerys-Moon-of-Fulgora.git "$SCRATCH/cerys"
else
  echo "cerys already cloned, skipping."
fi

echo "=== Step 1b: Clone top-downloaded open-source mods (runtime-discipline sources) ==="

# Top-downloaded mods with public repos, mined for runtime-scripting lessons
# (source comments, changelogs, and commit history). Full clones — we need git log.
#
# LICENSES (checked 2026-07; re-verify on refresh):
#   MIT:      AutoDeconstruct (softmix), Bottleneck (troelsbjerre), Factorissimo2
#             (MagmaMcFry) + notnotmelon fork, YARM (narc0tiq), flib (raiguard),
#             helmod (Helfima)
#   GPL-3.0:  Rampant (veden), Squeak-Through (Supercheese)
#   LGPL-3.0: Krastorio2
#   CUSTOM:   Logistic-Train-Network (Optera) — no derived-code distribution
#             without written permission
#   NONE:     FNEI (npo6ka), even-distribution (321freddy) — all rights reserved
#
# The generated docs must therefore contain NO copied code from any of these —
# facts, patterns, and short attributed quotes only. The generation prompt below
# enforces this; keep it that way. (Space Exploration and Earendel's AAI mods are
# top-rated but closed-source: nothing to clone.)
TOP_MODS="
https://github.com/softmix/AutoDeconstruct
https://github.com/troelsbjerre/Bottleneck
https://github.com/321freddy/even-distribution
https://github.com/npo6ka/FNEI
https://github.com/MagmaMcFry/Factorissimo2
https://github.com/notnotmelon/factorissimo-2-notnotmelon
https://github.com/Helfima/helmod
https://github.com/raiguard/Krastorio2
https://github.com/Yousei9/Logistic-Train-Network
https://github.com/veden/Rampant
https://github.com/Suprcheese/Squeak-Through
https://github.com/narc0tiq/YARM
https://github.com/factoriolib/flib
"
# NOTE: factoriolib/flib was archived on GitHub in June 2025; raiguard's projects
# moved to Codeberg. Swap in the Codeberg URL if the mirror goes stale.

MODS_DIR="$SCRATCH/topmods"
mkdir -p "$MODS_DIR"
for url in $TOP_MODS; do
  name="$(basename "$url")"
  if [ ! -d "$MODS_DIR/$name" ]; then
    git clone --quiet "$url.git" "$MODS_DIR/$name" || echo "WARNING: could not clone $url"
  else
    echo "$name already cloned, skipping."
  fi
done

echo "=== Step 2: Gather key files ==="

# -- Wube data: planet/space-location prototypes --
WUBE_PLANETS="$SCRATCH/factorio-data/space-age/prototypes/planet"
WUBE_ENTITIES="$SCRATCH/factorio-data/space-age/prototypes/entity"
WUBE_ITEMS="$SCRATCH/factorio-data/base/prototypes/item"
WUBE_TECH="$SCRATCH/factorio-data/space-age/prototypes/technology"

# Concatenate the highest-signal Wube files into one context blob
WUBE_CONTEXT="$SCRATCH/wube-context.lua"
echo "-- WUBE OFFICIAL DATA: Planets and Space-Locations --" > "$WUBE_CONTEXT"
cat "$WUBE_PLANETS"/*.lua >> "$WUBE_CONTEXT" 2>/dev/null || true
echo "" >> "$WUBE_CONTEXT"
echo "-- WUBE OFFICIAL DATA: Thruster entity prototype --" >> "$WUBE_CONTEXT"
cat "$WUBE_ENTITIES"/thruster*.lua >> "$WUBE_CONTEXT" 2>/dev/null || true
echo "" >> "$WUBE_CONTEXT"
echo "-- WUBE OFFICIAL DATA: Asteroid entity prototypes --" >> "$WUBE_CONTEXT"
cat "$WUBE_ENTITIES"/asteroid*.lua >> "$WUBE_CONTEXT" 2>/dev/null || true
echo "" >> "$WUBE_CONTEXT"
echo "-- WUBE OFFICIAL DATA: Generator prototype --" >> "$WUBE_CONTEXT"
cat "$WUBE_ENTITIES"/generator*.lua >> "$WUBE_CONTEXT" 2>/dev/null || true
cat "$WUBE_ENTITIES"/fusion*.lua >> "$WUBE_CONTEXT" 2>/dev/null || true

# -- Cerys planet prototype (direct analog to The Reef) --
CERYS_CONTEXT="$SCRATCH/cerys-context.lua"
echo "-- CERYS: Planet/space-location prototype --" > "$CERYS_CONTEXT"
find "$SCRATCH/cerys/prototypes/planet" -name "*.lua" -exec cat {} \; >> "$CERYS_CONTEXT" 2>/dev/null || true
echo "" >> "$CERYS_CONTEXT"
echo "-- CERYS: data.lua (top-level require structure) --" >> "$CERYS_CONTEXT"
cat "$SCRATCH/cerys/data.lua" >> "$CERYS_CONTEXT" 2>/dev/null || true
echo "" >> "$CERYS_CONTEXT"
echo "-- CERYS: control.lua (runtime event handler structure) --" >> "$CERYS_CONTEXT"
cat "$SCRATCH/cerys/control.lua" >> "$CERYS_CONTEXT" 2>/dev/null || true
echo "" >> "$CERYS_CONTEXT"
echo "-- CERYS: info.json (dependency declaration pattern) --" >> "$CERYS_CONTEXT"
cat "$SCRATCH/cerys/info.json" >> "$CERYS_CONTEXT" 2>/dev/null || true

# -- Maraxsis planet prototype and key mechanics --
MARAXSIS_CONTEXT="$SCRATCH/maraxsis-context.lua"
echo "-- MARAXSIS: Planet prototype --" > "$MARAXSIS_CONTEXT"
find "$SCRATCH/maraxsis/prototypes/planet" -name "*.lua" -exec cat {} \; >> "$MARAXSIS_CONTEXT" 2>/dev/null || true
find "$SCRATCH/maraxsis/prototypes" -name "planet*.lua" -exec cat {} \; >> "$MARAXSIS_CONTEXT" 2>/dev/null || true
echo "" >> "$MARAXSIS_CONTEXT"
echo "-- MARAXSIS: data.lua (top-level require structure) --" >> "$MARAXSIS_CONTEXT"
cat "$SCRATCH/maraxsis/data.lua" >> "$MARAXSIS_CONTEXT" 2>/dev/null || true
echo "" >> "$MARAXSIS_CONTEXT"
echo "-- MARAXSIS: control.lua (runtime event handler structure) --" >> "$MARAXSIS_CONTEXT"
cat "$SCRATCH/maraxsis/control.lua" >> "$MARAXSIS_CONTEXT" 2>/dev/null || true
echo "" >> "$MARAXSIS_CONTEXT"
echo "-- MARAXSIS: Generator/power entity prototypes --" >> "$MARAXSIS_CONTEXT"
find "$SCRATCH/maraxsis/prototypes/entity" -name "*generator*" -o -name "*power*" -o -name "*thruster*" 2>/dev/null | head -10 | xargs cat >> "$MARAXSIS_CONTEXT" 2>/dev/null || true

echo "=== Step 3: Fetch lua-api.factorio.com key pages ==="

API_CONTEXT="$SCRATCH/factorio-api.txt"
echo "" > "$API_CONTEXT"

# The API docs are JSON-driven; fetch the runtime-api.json for the latest version.
# This is the same source FMTK uses for type definitions.
RUNTIME_API_URL="https://lua-api.factorio.com/latest/runtime-api.json"
PROTOTYPE_API_URL="https://lua-api.factorio.com/latest/prototype-api.json"

echo "Fetching runtime-api.json..."
curl -s "$RUNTIME_API_URL" -o "$SCRATCH/runtime-api.json" || echo "WARNING: could not fetch runtime-api.json"

echo "Fetching prototype-api.json..."
curl -s "$PROTOTYPE_API_URL" -o "$SCRATCH/prototype-api.json" || echo "WARNING: could not fetch prototype-api.json"

# Extract the most relevant sections using jq (events, key classes)
if command -v jq &>/dev/null && [ -f "$SCRATCH/runtime-api.json" ]; then
  echo "-- RUNTIME API: All event names and brief descriptions --" >> "$API_CONTEXT"
  jq -r '.events[] | "EVENT: \(.name)\n  \(.description // "")\n  Parameters: \([.data // [] | .[] | "\(.name): \(.type)"] | join(", "))\n"' \
    "$SCRATCH/runtime-api.json" >> "$API_CONTEXT" 2>/dev/null || true

  echo "" >> "$API_CONTEXT"
  echo "-- RUNTIME API: LuaSurface methods (relevant to platform scripting) --" >> "$API_CONTEXT"
  jq -r '.classes[] | select(.name == "LuaSurface") | .methods[] | "METHOD: LuaSurface.\(.name)\n  \(.description // "" | split("\n")[0])\n"' \
    "$SCRATCH/runtime-api.json" >> "$API_CONTEXT" 2>/dev/null || true

  echo "" >> "$API_CONTEXT"
  echo "-- RUNTIME API: LuaSpacePlatform methods --" >> "$API_CONTEXT"
  jq -r '.classes[] | select(.name == "LuaSpacePlatform") | .methods[] | "METHOD: LuaSpacePlatform.\(.name)\n  \(.description // "" | split("\n")[0])\n"' \
    "$SCRATCH/runtime-api.json" >> "$API_CONTEXT" 2>/dev/null || true
else
  echo "WARNING: jq not found or runtime-api.json missing. Skipping structured API extraction." >> "$API_CONTEXT"
  echo "Install jq (brew install jq) and re-run for better results." >> "$API_CONTEXT"
fi

if command -v jq &>/dev/null && [ -f "$SCRATCH/prototype-api.json" ]; then
  echo "" >> "$API_CONTEXT"
  echo "-- PROTOTYPE API: SpaceLocation prototype fields --" >> "$API_CONTEXT"
  jq -r '.types[] | select(.name == "SpaceLocationPrototype" or .name == "PlanetPrototype" or .name == "AsteroidPrototype" or .name == "ThrusterPrototype" or .name == "GeneratorPrototype") | "PROTOTYPE: \(.name)\nFields:\n\([.properties // [] | .[] | "  \(.name) (\(.optional // false | if . then "optional" else "required" end)): \(.type)\n    \(.description // "" | split("\n")[0])"] | join("\n"))\n"' \
    "$SCRATCH/prototype-api.json" >> "$API_CONTEXT" 2>/dev/null || true
fi

echo "=== Step 3b: Mine top mods for runtime-discipline signals ==="

MODS_CONTEXT="$SCRATCH/topmods-context.txt"
: > "$MODS_CONTEXT"

{
  echo "-- LICENSES: first lines of each mod's license file (verify before ever copying code) --"
  for d in "$MODS_DIR"/*/; do
    name="$(basename "$d")"
    lic="$(find "$d" -maxdepth 1 \( -iname "license*" -o -iname "copying*" \) | head -1)"
    if [ -n "$lic" ]; then
      echo "MOD: $name"
      head -3 "$lic" | tr -s '\n' ' '
      echo ""
    else
      echo "MOD: $name — NO LICENSE FILE (all rights reserved by default)"
    fi
  done

  echo ""
  echo "-- SOURCE COMMENTS: workaround / quirk / desync markers --"
  grep -rniE "desync|workaround|for some reason|failsafe|0-indexed|blocks saving|faster to just|multiplayer drop" \
    --include="*.lua" "$MODS_DIR" 2>/dev/null | grep -vi "luaunit" | head -60

  echo ""
  echo "-- CHANGELOGS: crash / desync / multiplayer fix entries --"
  grep -hiE "desync|crash|multiplayer" "$MODS_DIR"/*/changelog.txt 2>/dev/null | sort -u | head -120

  echo ""
  echo "-- COMMIT HISTORY: fix-pattern commit subjects per mod --"
  for d in "$MODS_DIR"/*/; do
    name="$(basename "$d")"
    echo "MOD: $name"
    git -C "$d" log --oneline --no-decorate 2>/dev/null \
      | grep -iE "fix|desync|crash|migrat|invalid|on_load|storage|global|quality" | head -25
    echo ""
  done

  echo ""
  echo "-- KEY PATTERN FILES (event registration, schedulers, caches, migrations) --"
  for f in \
    "Logistic-Train-Network/script/init.lua" \
    "factorissimo-2-notnotmelon/lib/events.lua" \
    "AutoDeconstruct/control.lua" \
    "YARM/libs/ore_tracker.lua" \
    "flib/on-tick-n.lua" \
    "flib/migration.lua" \
    "Bottleneck/control.lua" \
    ; do
    if [ -f "$MODS_DIR/$f" ]; then
      echo "FILE: $f"
      head -c 8000 "$MODS_DIR/$f"
      echo ""
    fi
  done
} >> "$MODS_CONTEXT"

echo "Mod-analysis context assembled: $(wc -c < "$MODS_CONTEXT") bytes"

echo "=== Step 4: Feed to Claude and generate reference docs ==="

# Check Claude Code CLI is available
if ! command -v claude &>/dev/null; then
  echo "ERROR: 'claude' CLI not found. Run this script from within a Claude Code session"
  echo "or install Claude Code CLI and try again."
  exit 1
fi

# Build the combined context (truncate very large files to avoid context overflow)
COMBINED="$SCRATCH/combined-context.txt"
{
  echo "You are generating reference documentation for a Factorio Space Age mod called The Reef."
  echo "The Reef is a space-location (non-landable, like Shattered Planet), with asteroid/scrap mechanics."
  echo "It targets Factorio 2.x / Space Age, uses flib and PlanetsLib as dependencies."
  echo ""
  echo "Below is raw source material from authoritative sources. Analyze it carefully."
  echo "Do NOT rely on training data for field names, event names, or API methods — use only what appears in the source material below."
  echo ""
  echo "=== SOURCE: WUBE OFFICIAL FACTORIO DATA ==="
  head -c 60000 "$WUBE_CONTEXT"
  echo ""
  echo "=== SOURCE: CERYS MOD (space-location analog to The Reef) ==="
  head -c 40000 "$CERYS_CONTEXT"
  echo ""
  echo "=== SOURCE: MARAXSIS MOD (gold-standard Space Age planet mod) ==="
  head -c 40000 "$MARAXSIS_CONTEXT"
  echo ""
  echo "=== SOURCE: FACTORIO LUA API (runtime + prototype) ==="
  head -c 60000 "$API_CONTEXT"
} > "$COMBINED"

echo "Context assembled: $(wc -c < "$COMBINED") bytes"

# --- Generate prototype-cheatsheet.md ---
echo ""
echo "Generating prototype-cheatsheet.md..."
cat "$COMBINED" | claude --print --disallowedTools Write --model claude-sonnet-4-6 "$(cat <<'PROMPT'
Using ONLY the source material provided (do not supplement with training data), generate a Markdown reference file called prototype-cheatsheet.md.

This file is a quick-lookup reference for a Factorio Space Age mod developer. It should cover exactly the prototype types used in The Reef mod:
- space-location (the destination itself)
- asteroid (scrap chunk entities)
- item (Starship Scrap, Dilithium Crystal)
- recipe
- technology
- generator (for the Dilithium Generator)
- thruster (for the Ion Thruster)
- container/inventory scripting hooks

For each prototype type, provide:
1. The exact type string used in data:extend({})
2. All required fields with their correct 2.x field names and value types
3. Common optional fields relevant to this mod
4. Any fields that changed between 1.x and 2.x / Space Age (flag these clearly)
5. One minimal working example drawn from the source material

Format as clean Markdown with a ## heading per prototype type. Be concise — this is a cheatsheet, not a tutorial. If a field name is uncertain from the source material, say so explicitly rather than guessing.

Output ONLY the raw Markdown content — no preamble, no commentary, no file write operations. The output will be captured by shell redirection.
PROMPT
)" > "$OUT/prototype-cheatsheet.md"

echo "prototype-cheatsheet.md done."

# --- Generate space-age-api.md ---
echo ""
echo "Generating space-age-api.md..."
cat "$COMBINED" | claude --print --disallowedTools Write --model claude-sonnet-4-6 "$(cat <<'PROMPT'
Using ONLY the source material provided (do not supplement with training data), generate a Markdown reference file called space-age-api.md.

This file covers Space Age-specific runtime API areas a developer of The Reef mod will use. Focus on:

1. Space platform events — list every on_space_platform_* event found in the source, with its parameter names and types
2. LuaSpacePlatform — all methods and attributes found in the source
3. Asteroid spawning — how asteroid_spawn_definitions work at runtime; any hooks for modifying spawns
4. Cross-surface item transfer — the pattern used by Cerys or Maraxsis for sending items between surfaces/platforms
5. LuaSurface inventory APIs — methods for inserting/removing items from platform inventories
6. on_entity_damaged — signature and use for shield-style scripting
7. Common on_tick patterns seen in the reference mods

For each area: exact method/event name, parameters, return values if shown, and a one-sentence description of what it does. If something is NOT in the source material, note that explicitly — do not fill gaps with training data.

Format as clean Markdown with ## headings per area.

Output ONLY the raw Markdown content — no preamble, no commentary, no file write operations. The output will be captured by shell redirection.
PROMPT
)" > "$OUT/space-age-api.md"

echo "space-age-api.md done."

# --- Generate common-errors.md (starter, to be grown over time) ---
echo ""
echo "Generating common-errors.md..."
cat "$COMBINED" | claude --print --disallowedTools Write --model claude-sonnet-4-6 "$(cat <<'PROMPT'
Using ONLY the source material provided (do not supplement with training data), generate a Markdown reference file called common-errors.md.

This file documents API mistakes that an LLM (Claude) is likely to make when writing Factorio 2.x / Space Age mod code, based on evidence in the source material. Look for:

1. Fields that exist in 1.x but were renamed or removed in 2.x
2. Field names that look plausible but are wrong (misspellings, wrong nesting)
3. Patterns in the reference mods that differ from what a naive implementation might guess
4. Any explicit comments in the source code warning about common mistakes
5. Differences between the planet prototype and the space-location prototype that a developer might confuse

Format each entry as:
### [Short description of the error]
**Wrong:** `field_name_or_pattern`
**Correct:** `actual_field_name_or_pattern`
**Source:** [which file/mod this was derived from]
**Note:** [one sentence explaining why this is easy to get wrong]

If the source material doesn't give enough evidence to confirm an error pattern, omit it — do not speculate.

End with a section: ## Still Uncertain
List any field names or API calls that appear in the source but whose exact signature couldn't be confirmed from the material provided. These should be manually verified against lua-api.factorio.com.

Output ONLY the raw Markdown content — no preamble, no commentary, no file write operations. The output will be captured by shell redirection.
PROMPT
)" > "$OUT/common-errors.md"

echo "common-errors.md done."

# --- Generate runtime-discipline.md (control-stage lessons from top mods) ---
echo ""
echo "Generating runtime-discipline.md..."
cat "$MODS_CONTEXT" | claude --print --disallowedTools Write --model claude-sonnet-4-6 "$(cat <<'PROMPT'
You are given mined signals (license headers, source comments, changelog fix entries, commit subjects, and key pattern files) from the most-downloaded open-source Factorio mods. Using ONLY this material (do not supplement with training data), generate a Markdown reference file called runtime-discipline.md: control-stage (runtime scripting) lessons for a Factorio 2.x / Space Age mod.

Organize into sections along these lines, keeping only what the material supports:
1. Entity/object validity discipline (.valid, valid_for_read, surface deletion)
2. `storage` rules (what breaks saves/causes desyncs; on_load restrictions; local caches)
3. The full event-completeness matrix for tracking built/removed entities
4. Conditional event handler re-registration in on_load (multiplayer joins)
5. Event dispatcher patterns (one handler per event limit)
6. UPS patterns (per-tick budgets, resumable iteration, caching entity reads, scheduling without on_tick)
7. Migrations
8. Localised string and translation constraints
9. Cross-mod compatibility (data stage and runtime)
10. Confirmed engine quirks

STRICT RULES:
- Cite the mod (and file where known) for every claim.
- Do NOT reproduce code from the mods. Write original one-line illustrations only. Verbatim material is limited to short quoted comments/changelog lines, clearly attributed.
- End with two sections: (a) "Sources, licenses, and attribution" — a table of every mod with author and license exactly as given in the LICENSES block, plus a warning to never copy code from LTN, FNEI, or Even Distribution (restrictive/no license) and to treat GPL/LGPL mods as re-implement-only; (b) "Credit for distinctive techniques" — attribute any technique that appears to be a single author's invention (rather than a convergent pattern) to that author by name.
- If a claim cannot be confirmed from the provided material, omit it.

Output ONLY the raw Markdown content — no preamble, no commentary, no file write operations. The output will be captured by shell redirection.
PROMPT
)" > "$OUT/runtime-discipline.md"

echo "runtime-discipline.md done."

echo ""
echo "=== Done ==="
echo "Reference files written to $OUT:"
ls -lh "$OUT/"*.md
echo ""
echo "Next steps:"
echo "  1. Review each file — correct any obvious errors before trusting them."
echo "  2. Add a reference to all four files in CLAUDE.md."
echo "  3. Re-run this script after major Factorio updates to refresh."
echo "  4. Append to common-errors.md whenever Claude makes a Factorio-specific mistake."
echo "  5. Re-verify each top mod's license after refreshing (see Step 1b table)."
echo ""
echo "Scratch data is in $SCRATCH — safe to delete once you've reviewed the output."
