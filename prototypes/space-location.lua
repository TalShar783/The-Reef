local asteroid_util = require("__space-age__.prototypes.planet.asteroid-spawn-definitions")

-- Positioned just outside Nauvis's orbit (distance 15, orientation 0.275),
-- angularly between Nauvis and Maraxsis (orientation 0.515).
-- distance = 16, orientation = 0.40 places it visually between them.
-- Icon paths are placeholders; replace with final art before release.

PlanetsLib:extend({
  {
    type                    = "space-location",
    name                    = "the-reef",
    icon                    = "__space-age__/graphics/icons/shattered-planet.png",
    icon_size               = 64,
    starmap_icon            = "__space-age__/graphics/icons/shattered-planet.png",
    starmap_icon_size       = 64,
    order                   = "e[the-reef]",
    orbit = {
      parent      = { type = "space-location", name = "star" },
      distance    = 16,
      orientation = 0.40,
    },
    draw_orbit              = true,
    magnitude               = 0.4,
    solar_power_in_space    = 80,
    label_orientation       = 0.25,
    asteroid_spawn_influence = 1,

    -- Orbital spawn pool: vanilla fulgora_aquilo mix at position 0.4, plus our
    -- custom scrap chunks at a higher rate (this is The Reef — scrap should dominate).
    -- Second arg must be an exact position in the route table (0.1, 0.4, or 0.9).
    asteroid_spawn_definitions = (function()
      local spawns = asteroid_util.spawn_definitions(asteroid_util.fulgora_aquilo, 0.4)
      table.insert(spawns, {
        asteroid          = "starship-scrap-chunk",
        type              = "asteroid-chunk",
        probability       = 0.05,
        speed             = asteroid_util.standard_speed,
        angle_when_stopped = 1,
      })
      return spawns
    end)(),
  },
  {
    type                    = "space-location",
    name                    = "the-inner-reef",
    icon                    = "__space-age__/graphics/icons/shattered-planet.png",
    icon_size               = 64,
    starmap_icon            = "__space-age__/graphics/icons/shattered-planet.png",
    starmap_icon_size       = 64,
    order                   = "e[the-reef]-b[inner]",
    orbit = {
      parent      = { type = "space-location", name = "the-reef" },
      distance    = 2,
      orientation = 0.65,
    },
    draw_orbit              = false,
    -- fly_condition mimics the Shattered Planet's ability for wait conditions to be evalutated
    -- without landing on the location. auto_save is turned off because you will probably not reach it 
    -- and don't want to auto-save every time you go in.
    fly_condition           = true,
    auto_save_on_first_trip = false,
    magnitude               = 0.4,
    solar_power_in_space    = 40,
    label_orientation       = 0.75,
    asteroid_spawn_influence = 1,
  }
})
