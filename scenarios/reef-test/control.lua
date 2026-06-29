-- The Reef — Developer Test Scenario
--
-- Uses on_player_joined_game instead of on_init so player and force
-- are guaranteed to exist. Platform creation is wrapped in pcall so
-- a failure (e.g. if create_space_platform is unavailable outside
-- simulation context) degrades gracefully — research + items still work.

local function give(player, name, count)
    if prototypes.item[name] then
        player.insert{ name = name, count = count }
    end
end

local function give_items(player)
    -- Reef items
    give(player, "cargo-hatch",                  10)
    give(player, "basic-pmr",                     5)
    give(player, "dilithium-reactor-1",           5)
    give(player, "dilithium-fuel-cell",          50)
    give(player, "dilithium-crystal",           200)
    give(player, "dilithium-science-pack",      100)
    give(player, "starship-scrap-chunk",         50)
    give(player, "starship-scrap",              200)

    -- Platform essentials
    give(player, "space-platform-foundation",   500)
    give(player, "asteroid-collector",           10)
    give(player, "gun-turret",                   10)
    give(player, "laser-turret",                 10)
    give(player, "inserter",                    100)
    give(player, "fast-inserter",               100)
    give(player, "transport-belt",              200)
    give(player, "accumulator",                  20)
    give(player, "solar-panel",                  20)
    give(player, "thruster",                     10)

    -- General materials
    give(player, "iron-plate",                 1000)
    give(player, "copper-plate",               1000)
    give(player, "steel-plate",                 500)
    give(player, "electronic-circuit",          500)
    give(player, "advanced-circuit",            200)
    give(player, "processing-unit",             100)
    give(player, "low-density-structure",       100)
    give(player, "firearm-magazine",            500)
    give(player, "piercing-rounds-magazine",    200)

    -- Bots
    give(player, "logistic-robot",              100)
    give(player, "construction-robot",          100)
end

local function equip_armor(player)
    local armor_inv = player.get_inventory(defines.inventory.character_armor)
    if not armor_inv then return end
    armor_inv.insert{ name = "mech-armor", quality = "legendary", count = 1 }
    local stack = armor_inv[1]
    if stack and stack.valid_for_read and stack.grid then
        local g = stack.grid
        g.put{ name = "fusion-reactor-equipment",        quality = "legendary" }
        g.put{ name = "exoskeleton-equipment",           quality = "legendary" }
        g.put{ name = "exoskeleton-equipment",           quality = "legendary" }
        g.put{ name = "personal-roboport-mk2-equipment", quality = "legendary" }
        g.put{ name = "personal-roboport-mk2-equipment", quality = "legendary" }
    end
end

local function try_create_platform(player)
    local force   = player.force
    local platform = force.create_space_platform({
        name         = "Test Platform",
        planet       = "nauvis",
        starter_pack = "space-platform-starter-pack",
    })
    local hub     = platform.apply_starter_pack()
    local surface = platform.surface

    -- Foundation pad
    local tiles = {}
    for x = -5, 5 do
        for y = -5, 5 do
            tiles[#tiles + 1] = { name = "space-platform-foundation", position = { x, y } }
        end
    end
    surface.set_tiles(tiles)

    -- Stock hub
    if hub and hub.valid then
        hub.insert{ name = "iron-plate",         count = 200 }
        hub.insert{ name = "copper-plate",       count = 200 }
        hub.insert{ name = "steel-plate",        count = 100 }
        hub.insert{ name = "electronic-circuit", count = 100 }
        hub.insert{ name = "firearm-magazine",   count = 200 }
        hub.insert{ name = "starship-scrap",     count = 100 }
        hub.insert{ name = "dilithium-crystal",  count = 50  }
    end

    -- Pre-place cargo hatch + inserter
    surface.create_entity{
        name = "cargo-hatch", position = { 3, 0 }, force = force,
        create_build_effect_smoke = false,
    }
    surface.create_entity{
        name = "fast-inserter", position = { 5, 0 },
        direction = defines.direction.west, force = force,
        create_build_effect_smoke = false,
    }

    player.teleport({ 0, 3 }, surface)
    player.print("[The Reef Test] Platform created. Hub stocked. Cargo hatch at (3,0).")
end

local function setup(player)
    -- Research first — safest operation
    player.force.research_all_technologies()
    player.cheat_mode = true

    give_items(player)
    equip_armor(player)

    -- Platform creation: wrapped so a failure doesn't break everything else
    local ok, err = pcall(try_create_platform, player)
    if not ok then
        player.print("[The Reef Test] Platform creation failed: " .. tostring(err))
        player.print("[The Reef Test] Launch a platform manually — hub is in your inventory.")
        give(player, "space-platform-starter-pack", 1)
    end

    player.print("[The Reef Test] Research done. Cheat mode on. Use /editor for free placement.")
end

script.on_init(function()
    storage.setup_done = false
end)

script.on_player_joined_game(function(event)
    -- Only run once per game, not on every reload
    if storage.setup_done then return end
    storage.setup_done = true
    setup(game.players[event.player_index])
end)
