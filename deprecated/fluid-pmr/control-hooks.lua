-- Reference only — NOT a requireable module. These are the snippets that were
-- removed from control.lua when Fluid PMR was deprecated. See ../README.md.

-- require line:
-- local fluid_pmr = require("scripts.fluid_pmr")

-- on_init:
-- fluid_pmr.on_init()

-- managed_entity_filter entry:
-- { filter = "name", name = "fluid-pmr" },

-- dispatch_built branch:
-- elseif entity.name == "fluid-pmr" then
--     fluid_pmr.on_built(event)

-- dispatch_removed branch:
-- elseif entity.name == "fluid-pmr" then
--     fluid_pmr.on_removed(event)

-- on_tick dispatcher call:
-- fluid_pmr.on_tick(event)
