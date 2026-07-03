# Proven Patterns — Factorio 2.x / Space Age

Ready-made architectures verified in production mod code. Prefer repeating one of these over inventing an ad-hoc solution. Each entry: when to use it, the recipe, and the failure it prevents.

---

## Compound entity (visible shell + hidden helpers)

**When:** one machine needs behaviors no single prototype supports — e.g. "accepts any fluid through one pipe," "stores five fluids separately," "crafts from script-staged ingredients."

**Recipe:**
- One **visible shell** entity — a real, functional prototype (not a cosmetic one), since the shell must carry whatever the player interacts with: fluid box, circuit connector, GUI, minability. Pick the native type closest to the shell's own job (e.g. `storage-tank` if the shell itself buffers fluid).
- N **hidden helpers** placed at/around the shell's position by the control script on build, each a native prototype doing exactly its native job (a `pump` for the real pipe connection, `storage-tank`s for per-fluid storage, an `assembling-machine` for crafting).
- Helper prototype template:
  ```lua
  helper.hidden         = true   -- top-level field, NOT a flags entry
  helper.minable        = nil
  helper.collision_mask = { layers = {} }   -- never collides
  helper.flags = { "not-on-map", "placeable-off-grid",
                   "not-blueprintable", "not-deconstructable" }
  helper.selectable_in_game = false
  ```
- Control script: create helpers in `on_built_entity` (and robot/platform variants), store the member handles in `storage` keyed by the shell's `unit_number`, destroy them all when the shell is mined/dies.
- Set `shell.fast_replaceable_group = nil` if the shell was deepcopied from a vanilla entity, or players can fast-replace it with the vanilla original.

**Why:** every attempt to force one prototype to host all behaviors hits engine walls (see graveyard: single-crafter fluid PMR, cosmetic-shell attempt). Composition keeps every behavior on an entity type the engine natively supports it on.

---

## One pipe, any fluid (intake pump + sealed buffer)

**When:** a machine must accept *whatever fluid arrives* through a single external pipe connection — impossible on any crafting-machine fluid box (they filter to the active recipe's ingredient).

**Recipe:**
- The assembly's only real pipe connection is a **hidden pump** at the machine's edge, facing outward. Widen its `collision_box` if needed so the connection position sits inside the declared bounding box (harmless when `collision_mask` is empty).
- The pump discharges nowhere: it has no engine link to the rest of the assembly. Its own fluid box just fills from the network; script drains it (`get_fluid`/`remove_fluid`) into a sealed buffer tank (`pipe_connections = {}` on a `storage-tank`), then routes onward (e.g. to per-fluid sub-tanks) via `add_fluid`.
- **Circuit-gate the pump** so a second fluid type can never enter while the buffer still holds the first: wire pump to shell, `circuit_condition` = `signal-everything == 0` against the shell tank's read-contents signal. The gate is native circuit logic — no per-tick script check.
- `flow_direction = "input"` on the pump makes the intake genuinely one-directional; extraction back out needs a separate path.

**Why:** storage-tanks don't filter by recipe, and sealed storage-tank boxes accept script `add_fluid` fine. The pipe segment itself enforces one-fluid-per-network, but the pump+tank pair accepts each arriving fluid in turn, letting script sort fluids by name.

---

## Hidden crafter (script-selected recipes, native crafting)

**When:** a machine should produce real recipe-driven output from script-staged ingredients — skip this pattern and you end up reimplementing batching, crafting speed, and output logic in Lua.

**Recipe:**
- Hidden `assembling-machine` co-located with the shell, chemical-plant style (`fluid_boxes_off_when_no_fluid_recipe = false`). Fluid boxes sealed (`pipe_connections = {}`), script-fed.
- A **dedicated recipe category used by nothing else**, strictly one-to-one: only this crafter has the category, and its recipes have no other category. Recipes stay `hidden = true` (never player-selectable) but `enabled = true` (they're assigned via `entity.set_recipe()`, which requires an enabled recipe).
- Script flow per cycle: pick an affordable recipe from the category → `set_recipe()` → move exactly the needed fluid/items into the crafter's input boxes/inventory (`defines.inventory.crafter_input`) → let vanilla logic craft → drain `defines.inventory.crafter_output`.
- When feeding fluids, derive valid fluid box indices **from the currently assigned recipe's ingredient list** — indices beyond the active recipe's fluid-ingredient count are out of range at runtime, not merely empty.
- Free bonuses from staying native: the active recipe renders as the ghost icon, and the machine can output its current recipe as a circuit signal.

**Why:** verified working end-to-end in production. The alternative (one machine with "internal tank" fluid boxes and blocker-ingredient recipes) is a graveyard entry.

---

## Circuit gating between compound members

**When:** one member of a compound entity must run only while another is in some state (empty, below threshold, etc.).

**Recipe:** wire the members together with a scripted circuit connection at build time and set a `circuit_condition` on the controlled member. The engine evaluates it every tick for free; script never polls.

**Why:** replaces the most common `on_tick` abuse. A condition like "pump enabled only while tank empty" is exactly what the circuit network natively does.

---

## Entity GUIs: use `player.gui.relative`

**When:** any custom panel attached to an entity.

**Recipe:**
- Anchor the panel with `player.gui.relative` beside the entity's own GUI — the title bar close button, E/Esc handling, and positioning all come free, and the default entity GUI stays visible (use it to show current contents).
- Handle **both** `on_gui_opened` and `on_gui_closed`.
- **Never** set `player.opened = nil` inside `on_gui_opened` to suppress the default GUI — it fires `on_gui_closed` immediately and corrupts your GUI state tracking.

---

## Output placement: belts by type, with fallback chain

**When:** script places produced items into the world next to a machine.

**Recipe:**
- Match candidate belts by `entity.type == "transport-belt"` (all tiers share the type), **never** by prototype name (`"transport-belt"` the name is only the base tier).
- Insert onto a belt via `LuaTransportLine.insert_at_back(items, belt_stack_size)` — items table first.
- Fall back in order: belt → adjacent container's inventory → `surface.spill_item_stack` on the ground.

---

## Script storage as the source of truth

**When:** tracking per-entity state, accumulated amounts, or compound-entity membership.

**Recipe:** key everything in `storage` by the visible shell's `unit_number`; store member entity handles at creation instead of re-finding them each tick; validate with `entity.valid` before every use after any time has passed.

---

## Surface-restricted placement (`surface_conditions`)

**When:** an entity should be placeable only on space platforms, or only on planets.

**Recipe:**
- Platform-only: `surface_conditions = { { property = "gravity", min = 0, max = 0 } }`
- Planet-only: `surface_conditions = { { property = "gravity", min = 0.1 } }` (what Space Age itself applies to vanilla containers)
- **Deepcopy timing trap:** Space Age adds its `surface_conditions` to vanilla entities in *data-updates*. A `table.deepcopy` of a vanilla entity made in your `data.lua` runs **before** that and does not inherit the condition — always set `surface_conditions` explicitly on copies.
