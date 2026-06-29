-- The Reef — Developer Test Scenario
--
-- On game start:
--   • All technologies researched
--   • Cheat mode enabled (free/instant crafting)
--   • A space platform created and partially set up
--   • Player teleported onto the platform
--   • Reef items + general materials in inventory
--   • Hub stocked with test items for cargo hatch testing

local function give(player, name, count)
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

    -- ── Create a space platform ───────────────────────────────────────────
    local platform = force.create_space_platform({
        name         = "Test Platform",
        planet       = "nauvis",
        starter_pack = "space-platform-starter-pack",
    })
    local hub     = platform.apply_starter_pack()
    local surface = platform.surface

    -- ── Lay a foundation pad around the hub (11×11) ──────────────────────
    local tiles = {}
    for x = -5, 5 do
        for y = -5, 5 do
            tiles[#tiles + 1] = { name = "space-platform-foundation", position = { x, y } }
        end
    end
    surface.set_tiles(tiles)

    -- ── Stock the hub with test items for cargo hatch testing ─────────────
    if hub and hub.valid then
        hub.insert{ name = "iron-plate",        count = 200 }
        hub.insert{ name = "copper-plate",      count = 200 }
        hub.insert{ name = "steel-plate",       count = 100 }
        hub.insert{ name = "electronic-circuit", count = 100 }
        hub.insert{ name = "firearm-magazine",  count = 200 }
        hub.insert{ name = "starship-scrap",    count = 100 }
        hub.insert{ name = "dilithium-crystal", count = 50  }
    end

    -- ── Place a cargo hatch and inserter for immediate testing ────────────
    surface.create_entity{
        name     = "cargo-hatch",
        position = { 3, 0 },
        force    = force,
        create_build_effect_smoke = false,
    }
    surface.create_entity{
        name      = "fast-inserter",
        position  = { 5, 0 },
        direction = defines.direction.west,
        force     = force,
        create_build_effect_smoke = false,
    }

    -- ── Teleport player onto the platform ─────────────────────────────────
    player.teleport({ 0, 3 }, surface)

    -- ── Give items ────────────────────────────────────────────────────────
    give(player, "cargo-hatch",              10)
    give(player, "basic-pmr",                5)
    give(player, "dilithium-reactor-1",      5)
    give(player, "dilithium-fuel-cell",      50)
    give(player, "dilithium-crystal",        200)
    give(player, "dilithium-science-pack",   100)
    give(player, "starship-scrap-chunk",     50)
    give(player, "starship-scrap",           200)

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

    give(player, "iron-plate",               1000)
    give(player, "copper-plate",             1000)
    give(player, "steel-plate",               500)
    give(player, "electronic-circuit",        500)
    give(player, "advanced-circuit",          200)
    give(player, "processing-unit",           100)
    give(player, "low-density-structure",     100)
    give(player, "firearm-magazine",          500)
    give(player, "piercing-rounds-magazine",  200)

    -- ── Legendary Mech Armor + equipment ─────────────────────────────────
    local armor_inv = player.get_inventory(defines.inventory.character_armor)
    armor_inv.insert{ name = "mech-armor", quality = "legendary", count = 1 }
    local armor_stack = armor_inv[1]
    if armor_stack and armor_stack.valid_for_read and armor_stack.grid then
        local grid = armor_stack.grid
        grid.put{ name = "fusion-reactor-equipment",    quality = "legendary" }
        grid.put{ name = "exoskeleton-equipment",       quality = "legendary" }
        grid.put{ name = "exoskeleton-equipment",       quality = "legendary" }
        grid.put{ name = "personal-roboport-mk2-equipment", quality = "legendary" }
        grid.put{ name = "personal-roboport-mk2-equipment", quality = "legendary" }
    end

    -- Two stacks each of logistics and construction bots
    give(player, "logistic-robot",      100)
    give(player, "construction-robot",  100)

    player.print("[The Reef Test] Platform ready. Hub stocked. Cargo hatch placed at (3,0).")
    player.print("[The Reef Test] Use /editor for free entity placement and surface switching.")
end

script.on_init(setup)
