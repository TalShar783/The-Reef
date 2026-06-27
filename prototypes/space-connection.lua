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
    asteroid_spawn_definitions = asteroid_util.spawn_definitions(
      asteroid_util.fulgora_aquilo
    ),
  },
})
