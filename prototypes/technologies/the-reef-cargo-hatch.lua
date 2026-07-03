-- Cargo Hatch technology and repeatable upgrades.
--
-- Throughput model: the hatch is engine-native hub access (proxy-container)
-- throttled by script to a per-second item budget. Research raises the
-- budget; the final level removes the throttle entirely. See
-- scripts/cargo-hatch.lua for the enforcement.

data:extend({
  {
    type      = "technology",
    name      = "the-reef-cargo-hatch",
    icon      = "__base__/graphics/icons/steel-chest.png",
    icon_size = 64,
    prerequisites = { "the-reef-dilithium-science" },
    unit = {
      count = 200,
      ingredients = {
        { "automation-science-pack",       1 },
        { "logistic-science-pack",         1 },
        { "chemical-science-pack",         1 },
        { "space-science-pack",            1 },
        { "electromagnetic-science-pack",  1 },
        { "dilithium-science-pack",        1 },
      },
      time = 60,
    },
    effects = {
      { type = "unlock-recipe", recipe = "cargo-hatch" },
    },
  },

  -- Repeatable upgrade: each level raises the hatch throughput budget by
  -- 4 items/sec (base 4/sec). Level 10 removes the throttle entirely.
  -- Handled entirely by script (on_research_finished tracks the level).
  -- Cost doubles per level, standard infinite-research escalation.
  {
    type          = "technology",
    name          = "the-reef-cargo-hatch-throughput",
    icon          = "__base__/graphics/icons/steel-chest.png",
    icon_size     = 64,
    upgrade       = true,
    max_level     = 10,
    prerequisites = { "the-reef-cargo-hatch" },
    unit = {
      count_formula = "100*2^(L-1)",
      ingredients = {
        { "automation-science-pack",       1 },
        { "logistic-science-pack",         1 },
        { "chemical-science-pack",         1 },
        { "space-science-pack",            1 },
        { "electromagnetic-science-pack",  1 },
        { "dilithium-science-pack",        1 },
      },
      time = 60,
    },
    -- No data-stage effects; the throttle is tracked and enforced by script.
  },

  -- Repeatable upgrade: each level allows one additional Cargo Hatch per platform.
  -- Handled entirely by script (on_research_finished increments the per-force limit).
  -- Cost scales with level: 250 * L packs per level.
  {
    type          = "technology",
    name          = "the-reef-cargo-hatch-capacity",
    icon          = "__base__/graphics/icons/steel-chest.png",
    icon_size     = 64,
    upgrade       = true,
    max_level     = "infinite",
    prerequisites = { "the-reef-cargo-hatch" },
    unit = {
      count_formula = "250*L",
      ingredients = {
        { "automation-science-pack",       1 },
        { "logistic-science-pack",         1 },
        { "chemical-science-pack",         1 },
        { "space-science-pack",            1 },
        { "electromagnetic-science-pack",  1 },
        { "dilithium-science-pack",        1 },
      },
      time = 60,
    },
    -- No data-stage effects; the limit is tracked and enforced by script.
  },

  -- Repeatable upgrade: each level extends the maximum placement distance from the
  -- platform hub by RANGE_PER_LEVEL tiles. Enforced by script at placement time.
  -- Cost scales with level: 300 * L packs per level.
  {
    type          = "technology",
    name          = "the-reef-cargo-hatch-range",
    icon          = "__base__/graphics/icons/steel-chest.png",
    icon_size     = 64,
    upgrade       = true,
    max_level     = "infinite",
    prerequisites = { "the-reef-cargo-hatch" },
    unit = {
      count_formula = "300*L",
      ingredients = {
        { "automation-science-pack",       1 },
        { "logistic-science-pack",         1 },
        { "chemical-science-pack",         1 },
        { "space-science-pack",            1 },
        { "electromagnetic-science-pack",  1 },
        { "dilithium-science-pack",        1 },
      },
      time = 60,
    },
    -- No data-stage effects; range is tracked and enforced by script.
  },
})
