local asteroid_util = require("__space-age__.prototypes.planet.asteroid-spawn-definitions")

-- Route from Fulgora to The Reef.
-- Uses the full fulgora_aquilo asteroid table (no second arg = full route curves).
-- Length is tunable; 10000 puts it roughly equal to the Fulgora-Aquilo leg.

data:extend({
  {
    type     = "space-connection",
    name     = "fulgora-the-reef",
    subgroup = "planet-connections",
    from     = "fulgora",
    to       = "the-reef",
    order    = "d[fulgora]-e[the-reef]",
    length   = 10000,
    -- Approach corridor: vanilla fulgora_aquilo mix plus scrap chunks that increase
    -- toward The Reef end. Spawn point distance = 0.8 means they appear in the
    -- last 20% of the route (closer to The Reef), transitioning from rock to scrap.
    asteroid_spawn_definitions = (function()
      local spawns = asteroid_util.spawn_definitions(asteroid_util.fulgora_aquilo)
      table.insert(spawns, {
        asteroid = "starship-scrap-chunk",
        type     = "asteroid-chunk",
        spawn_points = {
          { distance = 0.1, probability = 0.000, speed = asteroid_util.standard_speed, angle_when_stopped = 1 },
          { distance = 0.6, probability = 0.010, speed = asteroid_util.standard_speed, angle_when_stopped = 1 },
          { distance = 1.0, probability = 0.050, speed = asteroid_util.standard_speed, angle_when_stopped = 1 },
        },
      })
      return spawns
    end)(),
  },
})
