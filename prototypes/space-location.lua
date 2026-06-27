local asteroid_util = require("__space-age__.prototypes.planet.asteroid-spawn-definitions")

-- Positioned between Fulgora and Aquilo, slightly off the main corridor.
-- Distance and orientation are tunable — adjust until starmap placement feels right.
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
    -- PlanetsLib requires distance/orientation inside orbit, not at top level.
    orbit = {
      parent      = { type = "space-location", name = "star" },
      distance    = 13,
      orientation = 0.575,
    },
    draw_orbit              = true,
    magnitude               = 0.4,
    solar_power_in_space    = 80,
    label_orientation       = 0.25,
    asteroid_spawn_influence = 1,

    -- Fixed orbital position: 0.55 along the fulgora→aquilo route.
    -- This gives a mix of metallic/carbonic/oxide chunks appropriate
    -- for the approach corridor. Replace with custom table in Phase 2.
    -- Second arg must be an exact position defined in the route table (0.1, 0.4, or 0.9
    -- for fulgora_aquilo). Arbitrary floats return an empty table and crash at load.
    asteroid_spawn_definitions = asteroid_util.spawn_definitions(
      asteroid_util.fulgora_aquilo, 0.4
    ),
  }
})
