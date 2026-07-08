local asteroid_util = require("__space-age__.prototypes.planet.asteroid-spawn-definitions")
local inner_reef_route = {
  probability_on_range_small = {
  {position = 0.001,   probability = 0.025, angle_when_stopped = asteroid_util.small_angle},
  {position = 0.199, probability = 0.05, angle_when_stopped = asteroid_util.small_angle},
  {position = 0.2,   probability = 0.075,             angle_when_stopped = asteroid_util.small_angle},
},
  type_ratios = {
    -- Metallic, Carbonic, Oxide, Prometheum, in that order.
    {position = 0.001, ratios ={3, 3, 3, 0}},
    {position = 0.2, ratios ={4, 5, 6, 0}}
  }

}


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
          { distance = 0.1, probability = 0.001, speed = asteroid_util.standard_speed, angle_when_stopped = 1 },
          { distance = 0.6, probability = 0.010, speed = asteroid_util.standard_speed, angle_when_stopped = 1 },
          { distance = 1.0, probability = 0.050, speed = asteroid_util.standard_speed, angle_when_stopped = 1 },
        },
      })
      return spawns
    end)(),
  },
})



-- Route from the Reef to the Inner Reef. This is a long route with lots of different asteroids depending on how deep you go.
-- Also features Strange Matter Particles, which are a rare spawn that can be collected and used in the Strange Matter Net.
data:extend({
  {
    type     = "space-connection",
    name     = "the-reef-inner-reef",
    subgroup = "planet-connections",
    from     = "the-reef",
    to       = "the-inner-reef",
    order    = "e[the-reef]-b[inner]",
    length   = 10000,
    -- Approach: Small and chunks in the first 1/5. Each 1/5 you go adds the next size. Particles start at halfway.
    asteroid_spawn_definitions = (function()
      local spawns = asteroid_util.spawn_definitions(inner_reef_route)
      return spawns
    end)(),
  },
})