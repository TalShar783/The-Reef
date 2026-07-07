local asteroid_util = require("__space-age__.prototypes.planet.asteroid-spawn-definitions")

-- Charybdis: the gravitational anomaly at the heart of The Reef. Non-landable
-- (plain space-location, not PlanetsLib -- verified working pattern for a
-- non-landable destination; PlanetsLib's nested-orbit-under-another-location
-- form is untested here, so this avoids risking an unverified load crash).
-- Native gravity_pull is 0 -- the pull is entirely scripted (see
-- scripts/charybdis-gravity.lua), which a flat native value cannot express
-- (it needs to grow sharply with proximity, not apply as one constant).
data:extend({
  {
    type              = "space-location",
    name              = "charybdis",
    icon              = "__space-age__/graphics/icons/shattered-planet.png",
    icon_size         = 64,
    starmap_icon      = "__space-age__/graphics/icons/shattered-planet.png",
    starmap_icon_size = 64,
    order             = "e[the-reef]-c[charybdis]",
    distance          = 17.5,
    orientation       = 0.40,
    magnitude         = 1,
    draw_orbit        = true,
    solar_power_in_space = 60,
    label_orientation = 0.25,
    gravity_pull      = 0,
    -- Same field the Shattered Planet uses: wait conditions evaluate and can
    -- act while passing through, without requiring a full dock.
    fly_condition     = true,

    -- Orbital pool: Charybdis's own turbulence is what generates the reef's
    -- scrap in the first place (per the design doc), so it's scrap-dominant.
    asteroid_spawn_influence = 1,
    asteroid_spawn_definitions = {
      {
        asteroid           = "starship-scrap-chunk",
        type               = "asteroid-chunk",
        probability        = 0.075,
        speed              = asteroid_util.standard_speed,
        angle_when_stopped = 1,
      },
    },
  },
})

-- Ithaca -> Charybdis: the danger corridor. length matches the
-- gravity-well-test prototype's tested/tuned value (45000) -- the gravity
-- curve and fall-distance calibration in charybdis-gravity.lua were verified
-- against this exact length; changing it requires re-tuning DIST_PER_SPEED there.
data:extend({
  {
    type     = "space-connection",
    name     = "ithaca-charybdis",
    subgroup = "planet-connections",
    from     = "ithaca",
    to       = "charybdis",
    order    = "e[the-reef]-c[charybdis]",
    length   = 45000,
    -- Approach corridor: vanilla fulgora_aquilo mix, plus scrap chunks that
    -- ramp up sharply approaching Charybdis (consistent with it being the
    -- scrap's actual source).
    asteroid_spawn_definitions = (function()
      local spawns = asteroid_util.spawn_definitions(asteroid_util.fulgora_aquilo)
      table.insert(spawns, {
        asteroid = "starship-scrap-chunk",
        type     = "asteroid-chunk",
        spawn_points = {
          { distance = 0.1, probability = 0.010, speed = asteroid_util.standard_speed, angle_when_stopped = 1 },
          { distance = 0.5, probability = 0.040, speed = asteroid_util.standard_speed, angle_when_stopped = 1 },
          { distance = 0.9, probability = 0.100, speed = asteroid_util.standard_speed, angle_when_stopped = 1 },
        },
      })
      return spawns
    end)(),
  },
})

-- Charybdis discovery technology. Cost/prerequisite mirror the Ithaca
-- discovery tech exactly (placeholder progression -- adjust pacing/cost to
-- taste; this only needs to make Charybdis reachable, not balance the tier).
data:extend({
  {
    type      = "technology",
    name      = "the-reef-charybdis",
    icon      = "__space-age__/graphics/icons/shattered-planet.png",
    icon_size = 64,
    prerequisites = { "the-reef-ithaca" },
    unit = {
      count = 500,
      ingredients = {
        { "automation-science-pack",      1 },
        { "logistic-science-pack",        1 },
        { "chemical-science-pack",        1 },
        { "space-science-pack",           1 },
        { "electromagnetic-science-pack", 1 },
      },
      time = 60,
    },
    effects = {
      {
        type           = "unlock-space-location",
        space_location = "charybdis",
      },
    },
    order = "e[the-reef]-c[charybdis]",
  },
})
