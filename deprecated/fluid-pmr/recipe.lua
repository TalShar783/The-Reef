-- Extracted from prototypes/recipes.lua — see ../README.md

-- Fluid PMR (building recipe) — crafted in an assembling machine.
{
  type     = "recipe",
  name     = "fluid-pmr",
  icon     = "__space-age__/graphics/icons/shattered-planet.png",
  icon_size = 64,
  categories = { "crafting" },
  subgroup = "the-reef-machines",
  order    = "z[pmr]-b",
  enabled  = false,
  energy_required = 10,
  ingredients = {
    { type = "item", name = "iron-plate",        amount = 30 },
    { type = "item", name = "steel-plate",       amount = 15 },
    { type = "item", name = "electronic-circuit", amount = 10 },
    { type = "item", name = "pipe",              amount = 20 },
  },
  results = {
    { type = "item", name = "fluid-pmr", amount = 1 },
  },
},
