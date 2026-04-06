-- ============================================================
-- sv_trigger.lua — shiva-boot
-- This is the entire resource. It fires the boot pipeline in
-- shiva-core once all module resources are already started.
--
-- Placement in server.cfg:
--   ensure shiva-core
--   ensure [shiva-modules]
--   ensure [shiva-overrides]   (optional)
--   ensure shiva-boot          ← must be last
-- ============================================================

exports['shiva-core']:startBoot()
