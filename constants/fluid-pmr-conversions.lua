-- Fluid -> item conversion rules for the Fluid PMR's item output. Shared
-- between scripts/fluid-pmr.lua (control stage) and anywhere else that
-- needs to know what a fluid converts to.
--
-- Only molten-iron -> iron-plate exists right now, as a test case. Fluids
-- with no entry here are stored but never produce an item.

return {
    ["molten-iron"] = { item = "iron-plate", fluid_per_item = 10 },
}
