# DEV15.2 — approved tools icon

Mats approved the transparent crossed hammer/wrench PNG on 23 September 2026.
Branch: codex/approved-tools-icon-20260923, based on DEV15.1 source a284f4e55b14c4a9e28e854a02e298540b933a35.
Only the HUD Skills/menu button image changes. Its dimensions, touch target and binding are preserved; the flat Skills tab icon remains unchanged. Version labels become 1.0.0-dev.15.2.

Approved asset: assets/ui/skills/icons/tools-premium-v1.png, SHA256 b0ddf462bcd25fca89bffa073f0dd9af2af5c82cf2a9f299224f3fe148f1d64f. Original PNG, 1254×1254 RGBA, copied without pixel changes. Archive: libfile_4d4d8efad7ec8191a546bbc55ff95b7b.

Validation pending: use .github/workflows/hud-dev15-2.yml. Exact candidate, five existing core gates, Skills/save checks, narrowly scoped Mac Metal HUD/menu test at 844×390, 667×375, 900×600, Moss HUD and mining after closing; normal WebKit startup. Inspect actual captures before publication. Preserve the 21 native resource hashes, DEV save namespace, LIVE and retained Worn release.
Known invariant differences remain project.godot, hero_gear.gd, player_controller.gd, player_visual.gd; no new differences. No physical-iPhone claim.
