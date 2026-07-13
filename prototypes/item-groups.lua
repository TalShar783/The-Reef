-- The Reef item group (tab) and subgroups (rows).
-- order "z[the-reef]" places the tab after all vanilla and most mod tabs.
-- Replace the icon with final Reef art before release.

data:extend({
  {
    type      = "item-group",
    name      = "the-reef",
    icon      = "__space-age__/graphics/icons/shattered-planet.png",
    icon_size = 64,
    order     = "z[the-reef]",
  },

  -- Row 1: raw and processed materials, science
  {
    type  = "item-subgroup",
    name  = "the-reef-materials",
    group = "the-reef",
    order = "a",
  },

  -- Row 2: structures and machines
  {
    type  = "item-subgroup",
    name  = "the-reef-machines",
    group = "the-reef",
    order = "b",
  },

  -- Row 3: processing recipes (crusher, recycler) shown in factoriopedia
  {
    type  = "item-subgroup",
    name  = "the-reef-processing",
    group = "the-reef",
    order = "c",
  },
})
