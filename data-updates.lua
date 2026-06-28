-- data-updates.lua: modify other mods' prototypes after all data.lua files have run.

-- Add dilithium-science-pack to any lab that already accepts electromagnetic-science-pack.
-- This covers the vanilla lab and any modded labs at the same tier.
-- A dedicated Dilithium Research Lab can be added later if desired.

for _, lab in pairs(data.raw["lab"]) do
    if lab.inputs then
        for _, input in ipairs(lab.inputs) do
            if input == "electromagnetic-science-pack" then
                table.insert(lab.inputs, "dilithium-science-pack")
                break
            end
        end
    end
end
