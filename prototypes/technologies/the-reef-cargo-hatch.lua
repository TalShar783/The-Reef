-- Cargo Hatch technology and repeatable capacity upgrade.

data:extend({
  {
    type      = "technology",
    name      = "the-reef-cargo-hatch",
    icon      = "__base__/graphics/icons/iron-chest.png",
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

  -- Repeatable upgrade: each level allows one additional Cargo Hatch per platform.
  -- Handled entirely by script (on_research_finished increments the per-force limit).
  -- Cost scales with level: 250 * L packs per level.
  {
    type          = "technology",
    name          = "the-reef-cargo-hatch-capacity",
    icon          = "__base__/graphics/icons/iron-chest.png",
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
})
