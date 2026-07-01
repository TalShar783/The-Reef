-- data.lua: prototype definitions entry point
-- Load order: data.lua -> data-updates.lua -> data-final-fixes.lua

-- Phase 1: space-location prototype
require("prototypes.space-location")
require("prototypes.space-connection")
require("prototypes.technologies.the-reef-discovery")

-- Item groups (must load before items so subgroups exist)
require("prototypes.item-groups")

-- Custom tiles
require("prototypes.tiles")

-- Phase 2: items, asteroids, recipes
require("prototypes.items")
require("prototypes.asteroids")
require("prototypes.recipes")

-- Phase 3: PMR entity + tech tree
require("prototypes.entities")
require("prototypes.ithaca")
require("prototypes.technologies.the-reef-basic-pmr")

-- Phase 4: Dilithium Science Pack + Reactor T1 + Cargo Hatch
require("prototypes.technologies.the-reef-dilithium-science")
require("prototypes.technologies.the-reef-dilithium-reactor")
require("prototypes.technologies.the-reef-cargo-hatch")

-- Phase 4+: structures
-- require("prototypes.entities")

-- Fluid PMR
require("prototypes.fluid-pmr")
require("prototypes.technologies.the-reef-fluid-pmr")
