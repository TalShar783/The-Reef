local asteroid_util = require("__space-age__.prototypes.planet.asteroid-spawn-definitions")
local planet_catalogue_fulgora = require("__space-age__.prototypes.planet.procession-catalogue-fulgora")

-- Ithaca: a stable artificial station in the outer Reef.
-- Surface is a placeholder using Fulgora's map gen — the station will look
-- industrial, which is acceptable until we build a custom Ithaca surface
-- (flat concrete, pre-placed Gravity Net and Cargo Rocket facilities).

PlanetsLib:extend({
  {
    type              = "planet",
    name              = "ithaca",
    icon              = "__space-age__/graphics/icons/shattered-planet.png",
    icon_size         = 64,
    starmap_icon      = "__space-age__/graphics/icons/shattered-planet.png",
    starmap_icon_size = 64,
    order             = "e[the-reef]-b[ithaca]",
    orbit = {
      parent      = { type = "space-location", name = "star" },
      distance    = 16.5,
      orientation = 0.40,
    },
    draw_orbit               = false,
    magnitude                = 0.2,
    solar_power_in_space     = 75,
    label_orientation        = 0.25,
    asteroid_spawn_influence = 0.2,

    -- Minimal map gen — on_chunk_generated in control.lua handles actual tile placement.
    -- empty-space everywhere outside the station radius, space-platform-foundation inside.
    map_gen_settings = {
      default_enable_all_autoplace_controls = false,
      autoplace_controls = {},
      cliff_settings = { cliff_elevation_0 = 1024 },
      property_expression_names = { elevation = "-10" },
    },

    surface_properties = {
      ["day-night-cycle"]  = 0,     -- no day/night — it's a station
      ["magnetic-field"]   = 10,
      ["solar-power"]      = 75,
      pressure             = 0,     -- vacuum
      gravity              = 2,     -- very low gravity
      temperature          = -150,
    },

    -- Reuse Fulgora's procession catalogue for the landing/departure cinematic.
    -- Replace with a custom Ithaca sequence before release.
    procession_graphic_catalogue = planet_catalogue_fulgora,
    platform_procession_set = {
      arrival   = { "planet-to-platform-b" },
      departure = { "platform-to-planet-a" },
    },
    planet_procession_set = {
      arrival   = { "platform-to-planet-b" },
      departure = { "planet-to-platform-a" },
    },

    asteroid_spawn_definitions = (function()
      local spawns = asteroid_util.spawn_definitions(asteroid_util.fulgora_aquilo, 0.4)
      return spawns
    end)(),
  }
})

-- Short hop from The Reef to Ithaca.
data:extend({
  {
    type     = "space-connection",
    name     = "the-reef-ithaca",
    subgroup = "planet-connections",
    from     = "the-reef",
    to       = "ithaca",
    order    = "e[the-reef]-b[ithaca]",
    length   = 3000,
    asteroid_spawn_definitions = (function()
      local spawns = asteroid_util.spawn_definitions(asteroid_util.fulgora_aquilo)
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

-- Ithaca discovery technology.
data:extend({
  {
    type      = "technology",
    name      = "the-reef-ithaca",
    icon      = "__space-age__/graphics/icons/shattered-planet.png",
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
