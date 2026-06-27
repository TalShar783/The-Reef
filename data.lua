-- data.lua: prototype definitions entry point
-- Load order: data.lua -> data-updates.lua -> data-final-fixes.lua

-- Phase 1: space-location prototype
require("prototypes.space-location")
require("prototypes.space-connection")
require("prototypes.technologies.the-reef-discovery")

-- Phase 2: items, asteroids, recipes
require("prototypes.items")
require("prototypes.asteroids")
require("prototypes.recipes")

-- Phase 3: additional technologies
-- require("prototypes.technologies")

-- Phase 4+: structures
-- require("prototypes.entities")
