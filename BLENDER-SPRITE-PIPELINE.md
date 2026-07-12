# Blender → Factorio Asteroid Sprite Pipeline

Reference for turning a finished Blender mesh into a working Factorio `AsteroidVariation`
(`color_texture` + `normal_map` + `roughness_map`). Picks up **after** modeling is done.

This is specifically for **asteroids** (and anything else using `AsteroidGraphicsSet`'s
`rotation_speed` + normal-map relighting trick) — a flat, single-angle sprite that the
*engine* spins and relights in real time. This is NOT the same technique as the classic
"rotate object, render N angles into a spritesheet" method used for buildings/vehicles —
asteroids only need one fixed-angle capture. Don't confuse the two.

## Why camera-render, not UV-bake

First attempt used Smart UV Project + Cycles bake (mesh's own UVs). **Wrong technique** —
that produces a texture-atlas of the mesh's true surface (correct for a real 3D-rendered
object), not a coherent single-viewpoint image. Looked like a jumbled patchwork in-game.

Correct technique: an actual camera **render** from one fixed angle, matching the
[Making Spritesheets with Blender forum guide](https://forums.factorio.com/viewtopic.php?t=5336)'s
camera setup — just one static frame instead of a full rotation spritesheet.

## Procedure

### 1. Camera
- Orthographic lens. Position `X:5 Y:-5 Z:0`, Rotation `X:45 Y:0 Z:45` (matches the forum
  guide's "looks like it belongs in the game" angle).
- Frame the object (`Numpad 0`, adjust Orthographic Scale), leaving a little padding —
  don't crop the silhouette right at the image edge.
- **Output Resolution X/Y directly reshapes the camera's frustum/aspect ratio** — it is not
  a post-render crop/resample. Changing resolution changes what's actually visible;
  re-check framing after any resolution change, especially non-square ↔ square switches.

### 2. Lighting — deliberately flat
- `Render Properties → Film → Transparent` on.
- Light via **World Background** color+strength (flat ambient from all directions), *not*
  a directional lamp.
- **Why flat matters**: `AsteroidGraphicsSet` (`lights`, `brightness`, `specular_strength`,
  `ambient_light`) is a *runtime* relighting model the game applies using the normal map.
  Baking strong directional shadows into the color texture fights the engine's own
  real-time relighting — inconsistent, frozen-shadow look as it spins in-game.

### 3. Color pass
- `Color Management → View Transform = Standard` (not AgX — AgX bakes contrast/desaturation
  into the saved texture, wrong for a game asset).
- Render (`F12`), Image Editor → pass = `Combined`, Save As.

### 4. Normal map — the hard part
Blender's built-in Normal render pass is **world-space only**. Factorio needs the normal
map in a space that rotates *with* the flat sprite (`rotation_speed` spins it in 2D) — so
it needs to be **camera-space**, not world-space. World-space produced zero shading
variation in-game (confirmed symptom: asteroid never changed brightness as it rotated).

`Vector Transform` node does the World→Camera conversion, but **does not exist in the
Compositor** — only in the Shader Editor / Geometry Nodes. Build it as a custom AOV
instead of a Compositor chain:

1. Shader Editor, on the object's material: `Geometry` node → its `Normal` output
   (world-space).
2. `Vector Transform`: Type = `Normal`, Convert From = `World`, Convert To = `Camera`.
3. `Vector Math` (`Multiply Add`): Multiplier `(0.5,0.5,0.5)`, Addend `(0.5,0.5,0.5)`.
   **Required remap** — raw normal components range `-1..1`; a Color output clips negative
   values to 0 (black). This is the same `(n*0.5)+0.5` trick every tangent-space normal
   map uses to stay displayable.
4. `AOV Output` node, name it (e.g. `camera_normal`). Wire the remap's output into its
   **Color** input.
5. Register it: `View Layer Properties → Passes → AOVs → +`, name matching exactly,
   **Type = Color**.

Then: render, Image Editor pass dropdown → your AOV name, **View Transform = Raw** (not
Standard — Standard/AgX apply a display transform to *any* saved pass, corrupting raw
directional data; confirmed via a known Blender bug report on this), Save As.

**Multi-material objects** (e.g. rivets given their own unlinked material for a different
color): the entire AOV node chain must be rebuilt on every separate material — unlinking
via "Make Single User" gives each object independent node data, nothing shares
automatically after that point.

### 5. Roughness map
Same AOV pattern, simpler (no space conversion needed — it's a scalar 0–1, not a vector):

1. `Value` node (e.g. `0.5` — flat/uniform roughness is a fine placeholder; for actual
   variation you'd need a real texture or multiple Value nodes per material instead).
2. Wire it into **both** the Principled BSDF's `Roughness` input *and* a second
   `AOV Output` node's **Value** input (not Color).
3. Register in View Layer AOVs with **Type = Value** (must match the socket you wired —
   see gotcha below).
4. Render, pass = your AOV name, `View Transform = Raw`, Save As.

### 6. Save conventions used here
- `graphics/entity/starship-scrap/asteroid-starship-small-{color,normal,roughness}-1.png`
- Format PNG (Factorio only accepts PNG for sprites — no EXR in the final files, even
  though EXR is the more "correct" format for preserving raw AOV data).

### 7. Lua wiring (`prototypes/asteroids.lua`)
```lua
scrap_chunk.graphics_set.variations =
{
    {
        color_texture = {
            filename = "__the-reef__/graphics/entity/starship-scrap/asteroid-starship-small-color-1.png",
            size = 1024,
            scale = 0.0244,
        },
        normal_map = {
            filename = "__the-reef__/graphics/entity/starship-scrap/asteroid-starship-small-normal-1.png",
            size = 1024,
            scale = 0.0244,
            premul_alpha = false,
        },
        roughness_map = {
            filename = "__the-reef__/graphics/entity/starship-scrap/asteroid-starship-small-roughness-1.png",
            size = 1024,
            scale = 0.0244,
            premul_alpha = false,
        }
    }
}
```
- `size` must exactly match the real PNG pixel dimensions (single number if square,
  `{width, height}` otherwise).
- `scale` is a **display multiplier**, independent of resolution — not something to copy
  verbatim from vanilla if your source resolution differs from theirs. Vanilla's chunk-size
  reference: `50px × scale 0.5 = 25` effective units. Solve for your own resolution:
  `scale = 25 / your_resolution`. (E.g. 1024px → `~0.0244`; 128px → `~0.195`.)
- `premul_alpha = false` on `normal_map`/`roughness_map` (raw data, not display color —
  premultiplication would corrupt the encoded values). Leave `color_texture` at its
  default (`true`) — vanilla's own convention, confirmed by reading `asteroid.lua` directly.
- Path prefix is the mod's `info.json` **`name`** field (lowercase, e.g. `the-reef`), not
  the folder name on disk — wrapped in double underscores: `__the-reef__/...`.
- Chunk-size asteroids get `collision_box = nil` in vanilla — sprite `size`/`scale` is
  **pure appearance**, not a gameplay hitbox, for this entity.

## Gotchas worth remembering

- **AOV Output has two separate input sockets, Color and Value.** Blender only reads
  whichever one matches the AOV's registered Type in View Layer Passes. A wire physically
  present but plugged into the wrong socket is silently ignored — produces solid black,
  no error. Always double check the registered Type matches the socket you actually wired.
- **A wire that "looks" connected isn't proof it is** — when a socket has real value data
  showing (a color swatch, a number field) instead of being blank, that usually means
  nothing is feeding it. Screenshot the node graph and check directly rather than assume.
- View Transform: `Standard` for the color/Combined pass, `Raw` for any data pass (Normal,
  custom AOVs) — every time, on every save.
- Untested/unconfirmed by official docs: whether Factorio's `normal_map` truly expects
  Camera space specifically (vs. some other convention). Camera space is what produced a
  correct, working, dynamically-relighting result in-game — that's the empirical
  confirmation this is based on, not a documented guarantee.

---

## Notes for an agent picking this up cold

- The actual `.blend` file(s) live outside this repo, in the user's local
  `C:\Users\nacus\OneDrive\Documents\Blender\` folder — not tracked in this git repo.
- This document assumes shaping/modeling is already done. For the modeling side (Boolean/
  Bevel hard-surface workflow, UV unwrapping, rivets via snapping), there's no separate
  written doc — that was covered live in a Training Mode session; check the user's
  Training Mode `progress.json` (`~/.claude/skills/training-mode/progress.json`) under the
  "Blender 3D Modeling" skill for what's already been taught/verified before re-explaining
  fundamentals.
- Session was run under Training Mode: the user does the actual Blender/Lua work
  themselves with coaching, not code/scenes produced on their behalf. If continuing this
  work, keep that mode active unless told otherwise.
- `prototypes/asteroids.lua` currently only has `starship-scrap-chunk` wired up (one
  `AsteroidVariation`, 1024px). Other asteroid-collector-related entities in this mod
  (Strange Matter Net, Strange Matter Particles — see project memory /
  `project_the_reef_strange_matter_bombardment.md`) have not had any graphics work done.
- If asked to add more visual variations (vanilla ships multiple `AsteroidVariation`
  entries per size for visual variety) or extend this to non-chunk asteroid sizes, this
  same pipeline applies, but chunk-size specifically has `collision_box = nil` — larger
  sizes pull from a separate `collision_radius` table unrelated to sprite scale, worth
  checking against vanilla's `asteroid.lua` again before assuming the same numbers apply.
