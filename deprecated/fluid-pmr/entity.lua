-- Extracted from prototypes/entities.lua — see ../README.md
-- Depends on `pmr` deepcopy pattern established alongside basic-pmr in that
-- file; not requireable standalone without the recipe-category extend above it.

-- Fluid PMR (Probabilistic Matter Recombinator — Fluid Variant)
-- 3×3 machine. Accepts one fluid input on the west face; outputs items (mining-
-- drill style) onto the east-adjacent tile. All fluid voiding, virtual-tank
-- accumulation, and item production driven by scripts/fluid_pmr.lua.
--
-- Entity base: storage-tank. Storage tanks accept any fluid regardless of
-- recipe (they have no recipe system), which is required for the design —
-- assembling-machine fluid boxes filter to the recipe ingredient fluid type,
-- making "one pipe that accepts multiple fluid types" impossible on that base.
-- Script reads from the tank's fluid box, removes the fluid (voiding it into
-- script-storage virtual tanks), and the real tank refills naturally from the
-- pipe network. When a virtual tank is full, the script stops voiding → the
-- real tank fills → the pipe network backs up (natural backpressure).
--
-- Placeholder graphics: storage-tank sprites. Replace with custom art before release.

local fluid_pmr = table.deepcopy(data.raw["storage-tank"]["storage-tank"])
fluid_pmr.name              = "fluid-pmr"
fluid_pmr.icon              = "__space-age__/graphics/icons/shattered-planet.png"
fluid_pmr.icon_size         = 64
fluid_pmr.minable           = { mining_time = 1, result = "fluid-pmr" }
fluid_pmr.next_upgrade      = nil
fluid_pmr.fast_replaceable_group = nil  -- prevent fast-replace with vanilla storage tanks
fluid_pmr.two_direction_only = false    -- allow all 4 rotations (script currently assumes west=input)

-- Single fluid input on the west face (center row of the 3×3 footprint).
-- Script voids fluid via remove_fluid(1, amount) and accumulates it in
-- data.fluids virtual tanks. The real tank only ever holds what hasn't been
-- voided yet; its capacity acts as the inbound buffer.
fluid_pmr.fluid_box = {
    volume           = 1000,
    pipe_covers      = pipecoverspictures(),
    pipe_connections = {
        {
            direction = defines.direction.west,
            position  = { -1, 0 },
        },
    },
}

data:extend({ fluid_pmr })
