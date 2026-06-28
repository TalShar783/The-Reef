local asteroid_util = require("__space-age__.prototypes.planet.asteroid-spawn-definitions")

-- Ithaca: a stable artificial station in the outer Reef.
-- Defined as a non-landable space-location for now. Full surface content
-- (Cargo Rocket Launch Facility, Gravity Net) will be added in a later phase
-- when it becomes a proper landable planet type.

PlanetsLib:extend({
  {
    type              = "space-location",
    name              = "ithaca",
    icon              = "__space-age__/graphics/icons/shattered-planet.png",
    icon_size         = 64,
    starmap_icon      = "__space-age__/graphics/icons/shattered-planet.png",
    starmap_icon_size = 64,
    order             = "e[the-reef]-b[ithaca]",
    orbit = {
      parent      = { type = "space-location", name = "star" },
      distance    = 13.5,
      orientation = 0.590,
    },
    draw_orbit               = false,
    magnitude                = 0.2,
    solar_power_in_space     = 75,
    label_orientation        = 0.25,
    asteroid_spawn_influence = 0.2,  -- Station is mostly clear of debris

    -- Minimal asteroid spawns — it's a managed station area.
    asteroid_spawn_definitions = (function()
      local spawns = asteroid_util.spawn_definitions(asteroid_util.fulgora_aquilo, 0.4)
      return spawns
    end)(),
  }
})

-- Short hop from The Reef to Ithaca — they're in the same region of space.
data:extend({
  {
    type     = "space-connection",
    name     = "the-reef-ithaca",
    subgroup = "planet-connections",
    from     = "the-reef",
    to       = "ithaca",
    order    = "e[the-reef]-b[ithaca]",
    length   = 3000,
    -- space-connection needs route format: spawn_definitions with NO second arg,
    -- returning entries with spawn_points arrays (not flat probability fields).
    asteroid_spawn_definitions = (function()
      local spawns = asteroid_util.spawn_definitions(asteroid_util.fulgora_aquilo)
      -- Light scrap chunk presence in the lane — route format requires spawn_points.
      table.insert(spawns, {
        asteroid = "starship-scrap-chunk",
        type     = "asteroid-chunk",
        spawn_points = {
          { distance = 0.0, probability = 0.000, speed = asteroid_util.standard_speed, angle_when_stopped = 1 },
          { distance = 1.0, probability = 0.005, speed = asteroid_util.standard_speed, angle_when_stopped = 1 },
        },
      })
      return spawns
    end)(),
  },
})

-- Ithaca discovery technology: unlocked after researching the Basic PMR.
-- Discovering Ithaca opens up the station as a platform destination.
data:extend({
  {
    type    = "technology",
    name    = "the-reef-ithaca",
    icon    = "__space-age__/graphics/icons/shattered-planet.png",
    icon_size = 64,
    prerequisites = { "the-reef-basic-pmr" },
    unit = {
      count = 500,
      ingredients = {
        { "automation-science-pack",       1 },
        { "logistic-science-pack",         1 },
        { "chemical-science-pack",         1 },
        { "space-science-pack",            1 },
        { "electromagnetic-science-pack",  1 },
      },
      time = 60,
    },
    effects = {
      {
        type           = "unlock-space-location",
        space_location = "ithaca",
      },
    },
    order = "e[the-reef]-b[ithaca]",
  },
})
