-- settings.lua: mod configuration options
-- Uncomment and extend as features are added.

-- data:extend({
--   {
--     type = "double-setting",
--     name = "the-reef-dilithium-drop-rate",
--     setting_type = "startup",
--     default_value = 0.05,
--     minimum_value = 0.0,
--     maximum_value = 1.0,
--     order = "a",
--   },
-- })

-- Fluid PMR's sub-tank breakdown panel floats at a fixed screen position
-- since it can't be docked to the native storage-tank GUI (no
-- relative_gui_type exists for storage-tank). Let players move it instead.
data:extend({
  {
    type = "string-setting",
    name = "the-reef-fluid-pmr-gui-position",
    setting_type = "runtime-per-user",
    default_value = "top-right",
    allowed_values = { "top-right", "top-left", "bottom-right", "bottom-left" },
  },
})
