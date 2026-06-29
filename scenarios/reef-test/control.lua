-- The Reef — Developer Test Scenario
--
-- On game start:
--   • All technologies researched
--   • Cheat mode enabled (free/instant crafting, no inventory limit)
--   • Reef items + platform essentials in inventory
--   • Instructions printed to console
--
-- To reach a space platform (required for Cargo Hatch, Reactor testing):
--   1. Use the rocket silo (given in inventory) — build it, it auto-configures
--   2. Or run: /c game.player.teleport({0,0}, game.surfaces["<platform-name>"])
--      after a platform exists.
--   3. Or open /editor and use the surface tool to switch surfaces.

local function give(player, name, count)
    -- Silent insert — skip if item doesn't exist (avoids errors on partial builds)
    if prototypes.item[name] then
        player.insert{ name = name, count = count }
    end
end

local function setup()
    local player = game.players[1]
    if not player then return end

    local force = player.force

    -- Research everything (includes all The Reef techs)
    force.research_all_technologies()

    -- Free crafting + no inventory restrictions
    player.cheat_mode = true

    -- ── The Reef items ────────────────────────────────────────────────────
    give(player, "cargo-hatch",           10)
    give(player, "basic-pmr",              5)
    give(player, "dilithium-reactor-1",    5)
    give(player, "dilithium-fuel-cell",   50)
    give(player, "dilithium-crystal",    200)
    give(player, "dilithium-science-pack", 100)
    give(player, "starship-scrap-chunk",  50)
    give(player, "starship-scrap",        200)

    -- ── Space platform essentials ─────────────────────────────────────────
    give(player, "space-platform-foundation", 500)
    give(player, "asteroid-collector",         10)
    give(player, "gun-turret",                 10)
    give(player, "laser-turret",               10)
    give(player, "inserter",                  100)
    give(player, "fast-inserter",             100)
    give(player, "transport-belt",            200)
    give(player, "accumulator",               20)
    give(player, "solar-panel",               20)
    give(player, "thruster",                  10)

    -- ── Rocket + platform launch items ───────────────────────────────────
    give(player, "rocket-silo",                1)
    give(player, "rocket-fuel",              200)
    give(player, "cargo-landing-pad",          5)

    -- ── General materials ─────────────────────────────────────────────────
    give(player, "iron-plate",              1000)
    give(player, "copper-plate",            1000)
    give(player, "steel-plate",              500)
    give(player, "electronic-circuit",       500)
    give(player, "advanced-circuit",         200)
    give(player, "processing-unit",          100)
    give(player, "low-density-structure",    100)
    give(player, "firearm-magazine",         500)
    give(player, "piercing-rounds-magazine", 200)

    -- ── Instructions ─────────────────────────────────────────────────────
    player.print("[The Reef Test] All technologies researched. Cheat mode on.")
    player.print("[The Reef Test] Build a Rocket Silo (given) and launch a Space Platform to test platform features.")
    player.print("[The Reef Test] Use /editor for free entity placement and surface switching.")
end

script.on_init(setup)
