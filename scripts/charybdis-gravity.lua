-- Charybdis gravity well: a scripted, depth-scaled pull toward Charybdis
-- along the "ithaca-charybdis" connection. Weak thrust operates freely in
-- the outer route but stalls and is dragged in past a depth-dependent point
-- of no return; a platform that reaches Charybdis (arrival or drag) is
-- destroyed, and anyone aboard is evacuated to Nauvis first.
--
-- Ported from the gravity-well-test prototype mod (Nauvis <-> a throwaway
-- test destination) after extensive in-game verification. Engine facts this
-- relies on (verified 2.1.9):
--   * platform.speed is a progress rate toward the platform's *scheduled*
--     stop, not a signed velocity -- direction must come from the schedule
--     (travel_target), not from the sign of speed or distance deltas.
--   * Positive speed writes persist (decaying under the engine's own drag);
--     negative writes are floored to 0 under thrust. So gravity can slow and
--     stall an escaping platform via subtraction, but backward motion has to
--     be expressed as a direct distance write (the vfall mechanism below).
--   * destroy() is silently refused while a character is on the platform
--     surface (no error; scheduled_for_deletion stays 0) -- evacuate every
--     character off first.
--   * player.teleport() while a player is in remote view moves only the
--     view; teleport the character entity directly.
--
-- Only on_tick is self-registered here (no other module in this mod claims
-- it). on_init/on_configuration_changed are exported for control.lua's
-- shared dispatcher, since it already owns those events centrally.

local M = {}

local DANGER_CONNECTION = "ithaca-charybdis"
local DESTINATION       = "charybdis"
local ARRIVAL_D         = 0.995
local G_MAX             = 0.17    -- pull (speed/tick) at the destination end; terminal fall at d=1 ~ 800 km/s displayed
local G_EXPONENT        = 5       -- curve steepness: outer route nearly free, wall concentrated near the destination
local K_FALL_DRAG       = 9e-4    -- quadratic drag on the backward fall; caps its terminal velocity
local SPEED_TO_KMS      = 58      -- API speed unit -> km/s readout, calibrated in-game (for the hub status display)
-- distance/tick per unit of fall speed; scales with 1/(connection length).
-- Calibrated at length 15000, scaled to this connection's 45000. A
-- proportional estimate, not independently re-measured at this length.
local DIST_PER_SPEED    = 1.103e-5

-- ── Gravity ─────────────────────────────────────────────────────────────────

local function in_well(platform)
    if platform.state ~= defines.space_platform_state.on_the_path then return false end
    local conn = platform.space_connection
    return conn ~= nil and conn.name == DANGER_CONNECTION
end

-- Name of the space location the platform is currently scheduled to reach.
-- (platform.speed is a progress rate toward this target, not a signed
-- velocity, so direction must be read from the schedule, not from speed.)
local function travel_target(platform)
    local sched = platform.schedule
    if not (sched and sched.records and sched.current) then return nil end
    local rec = sched.records[sched.current]
    return rec and rec.station or nil
end

-- Evacuate every character aboard the platform's surface to Nauvis.
-- player.teleport() while in remote view moves only the view -- teleport the
-- character entity directly, which works cross-surface unconditionally.
local function evacuate(platform, force)
    local surface = platform.surface
    if not (surface and surface.valid) then return end
    local nauvis = game.surfaces["nauvis"]
    local spawn = force.get_spawn_position(nauvis)
    for _, player in pairs(game.players) do
        if player.valid then
            local ch = player.character
            local aboard = (player.physical_surface == surface)
                or (ch and ch.valid and ch.surface == surface)
                or (player.vehicle and player.vehicle.valid and player.vehicle.surface == surface)
            if aboard then
                if player.vehicle and player.vehicle.valid then
                    player.driving = false
                end
                local ok = ch and ch.valid and ch.teleport(spawn, nauvis)
                if not ok and ch and ch.valid then
                    -- Fallback in case direct character teleport is ever refused.
                    player.set_controller({ type = defines.controllers.character, character = ch })
                    player.teleport(spawn, nauvis)
                end
                player.print("[the-reef] Charybdis's pull claimed your platform -- evacuated to Nauvis")
            end
        end
    end
end

local function clear_platform_state(idx)
    storage.charybdis_vfall[idx] = nil
    storage.charybdis_fall_status[idx] = nil
end

local function consume(platform, why)
    storage.charybdis_doomed[platform.index] = true
    clear_platform_state(platform.index)
    game.print(("[the-reef] %s %s -- consumed by Charybdis"):format(platform.name, why))
    evacuate(platform, platform.force)
    platform.destroy(60)
end

-- Shows the virtual fall speed in the hub's status row while a platform is
-- being dragged in. The native speed readout stays at 0 during the fall
-- (speed writes are floored under thrust), which would otherwise look broken.
local function update_fall_status(platform, idx, vfall)
    local hub = platform.hub
    if not (hub and hub.valid) then return end
    if vfall and vfall > 0 then
        hub.custom_status = {
            diode = defines.entity_status_diode.red,
            label = ("Dragged toward Charybdis: %d km/s"):format(vfall * SPEED_TO_KMS),
        }
        storage.charybdis_fall_status[idx] = true
    elseif storage.charybdis_fall_status[idx] then
        hub.custom_status = nil
        storage.charybdis_fall_status[idx] = nil
    end
end

local function handle(platform)
    if not (platform and platform.valid) then return end
    if (platform.scheduled_for_deletion or 0) > 0 then return end
    local idx = platform.index
    if storage.charybdis_doomed[idx] then return end

    local loc = platform.space_location
    if loc and loc.name == DESTINATION then
        consume(platform, "parked at the destination")
        return
    end

    if not in_well(platform) then
        update_fall_status(platform, idx, nil)
        clear_platform_state(idx)
        return
    end

    local d = platform.distance or 0
    if d >= ARRIVAL_D then
        consume(platform, ("fell in (%.3f)"):format(d))
        return
    end

    local pre    = platform.speed
    local target = travel_target(platform)
    -- Steep curve: the outer route is nearly free; the pull concentrates hard
    -- near Charybdis. A ship's point of no return sits where its thrust
    -- acceleration T satisfies G_MAX * d^G_EXPONENT = T.
    local g = G_MAX * d ^ G_EXPONENT

    if target == DESTINATION then
        -- Willingly flying into the well: gravity deepens the fall.
        platform.speed = pre + g
        storage.charybdis_vfall[idx] = nil
    else
        -- Escaping (or aimless): gravity opposes progress.
        local net = pre - g
        if net > 0 then
            platform.speed = net
            storage.charybdis_vfall[idx] = nil
        else
            -- Stalled at the engine's 0-floor: accumulate a virtual backward
            -- fall. `pre` is the speed the engine regenerated from thrust
            -- this tick, so thrust drains the fall and gravity feeds it;
            -- quadratic drag caps it at a terminal velocity instead of
            -- growing without bound.
            platform.speed = 0
            local v0 = storage.charybdis_vfall[idx] or 0
            local vfall = v0 + (g - pre) - K_FALL_DRAG * v0 * v0
            if vfall <= 0 then
                storage.charybdis_vfall[idx] = nil
            else
                storage.charybdis_vfall[idx] = vfall
                local new_d = math.min(d + vfall * DIST_PER_SPEED, 1)
                platform.distance = new_d
                if new_d >= ARRIVAL_D then
                    consume(platform, ("dragged in (%.3f)"):format(new_d))
                    return
                end
            end
        end
    end

    update_fall_status(platform, idx, storage.charybdis_vfall[idx])
end

-- ── Registration ────────────────────────────────────────────────────────────

-- Exported for control.lua's shared on_init/on_configuration_changed
-- dispatcher (matching cargo_hatch/pmr/fluid_pmr's convention) -- those
-- events already have a single central handler in control.lua, so this
-- module must not register its own.
function M.on_init()
    storage.charybdis_doomed = storage.charybdis_doomed or {}
    storage.charybdis_vfall = storage.charybdis_vfall or {}
    storage.charybdis_fall_status = storage.charybdis_fall_status or {}
end

M.on_configuration_changed = M.on_init

-- Self-registered: no other module in this mod uses raw on_tick (cargo_hatch/
-- pmr/fluid_pmr use on_nth_tick on their own cadences instead), so there is
-- no one-handler-per-event conflict here.
script.on_event(defines.events.on_tick, function()
    for _, force in pairs(game.forces) do
        local platforms = force.platforms
        if platforms then
            for _, platform in pairs(platforms) do
                handle(platform)
            end
        end
    end
end)

return M
