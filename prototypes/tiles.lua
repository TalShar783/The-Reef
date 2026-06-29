-- Ithaca Station Floor — visually identical to space-platform-foundation but
-- has no minable field, making it indestructible by players and robots.
-- Nuclear bomb tile-replacement effects skip it (wrong collision mask).
-- Entities (machines, belts, etc.) can still be placed on it normally.
-- Players cannot place other tiles on top of it (allows_being_covered = false,
-- inherited from the deepcopy) — this is intentional: the natural station
-- floor is permanent.

local floor = table.deepcopy(data.raw["tile"]["space-platform-foundation"])
floor.name    = "ithaca-station-floor"
floor.order   = "z[ithaca-station-floor]"
floor.minable = nil   -- indestructible: no mining by player, robot, or tool

data:extend({ floor })
