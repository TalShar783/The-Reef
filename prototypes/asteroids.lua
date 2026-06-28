-- Starship Scrap Chunk entity — collected by asteroid collectors in space.
-- Full deepcopy of metallic-asteroid-chunk to inherit all required fields.
-- Replace graphics_set with custom scrap art before release.

local scrap_chunk = table.deepcopy(data.raw["asteroid-chunk"]["metallic-asteroid-chunk"])
scrap_chunk.name    = "starship-scrap-chunk"
scrap_chunk.order   = "e[starship-scrap]-a[chunk]"
scrap_chunk.minable = {
    mining_time     = 0.2,
    result          = "starship-scrap-chunk",
    mining_particle = "metallic-asteroid-chunk-particle-medium",
}
data:extend({ scrap_chunk })

-- Ithaca scrap debris — type="asteroid" (not asteroid-chunk) so it can be
-- spawned on Ithaca Station's planet surface. Visually identical to a small
-- metallic asteroid. When destroyed, a script drops starship-scrap-chunk items
-- via spill_item_stack instead of relying on dying_trigger_effect (which would
-- try to create asteroid-chunk entities that can't exist on planet surfaces).

local scrap_debris = table.deepcopy(data.raw.asteroid["small-metallic-asteroid"])
scrap_debris.name  = "ithaca-scrap-debris"
scrap_debris.order = "z[ithaca-scrap-debris]"
-- Strip the create-asteroid-chunk trigger; keep the explosion visual.
-- Script handles item drops via on_entity_died.
if scrap_debris.dying_trigger_effect then
    local cleaned = {}
    for _, effect in ipairs(scrap_debris.dying_trigger_effect) do
        if effect.type ~= "create-asteroid-chunk" then
            cleaned[#cleaned + 1] = effect
        end
    end
    scrap_debris.dying_trigger_effect = cleaned
end
data:extend({ scrap_debris })
