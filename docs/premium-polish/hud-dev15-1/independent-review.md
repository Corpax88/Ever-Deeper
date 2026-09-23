# DEV15.1 independent HUD and tooltip review

Accepted for the scoped DEV15.1 release. No remaining blocker was found in the
larger gameplay controls or stat tooltip behavior. This verdict follows inspection
of all 30 final exported-build images and the corresponding interaction evidence.
It does not certify physical iPhone behavior or the whole game's final quality.

Accepted source: `51e2c58ce8806d11c9fc608c6d6a9e48b74507c8`.
Build/browser run: `35822513557`.
Version: `1.0.0-dev.15.1`.
PCK: 258,740,164 bytes; SHA256
`fa6c452639e54d05df746eb9ef3743459a7b07b7c452aca95643c32861f30ee0`.
The nine-file manifest agrees between build, Chromium and WebKit reports.

## Visual findings

The gameplay mining button, bag, menu, guide, mole and gold icons are visibly
larger. Their production artwork retains its detail. At 844×390 and 667×375,
the controls remain separated and the middle of the play area remains available
for movement and mining. Surface, Mossvein and The Deep captures show the same
approved hero and world artwork. The 900×600 capture also has a clear HUD with
no gold/minimap collision. Its minimap remains in the top band; this image does
not establish execution of the defensive below-goal fallback.

Skills row and navigation sizes remain unchanged, as the user explicitly asked.
The final 844 and 667 Skills images retain the accepted warm cave, miner/mole
portrait, iron and copper framing, serif text and orange progress bars. The
hover and held-touch popups use matching materials, show complete readable
copy, stay inside the viewport and do not cover the held stat. They temporarily
cover part of the decorative portrait while preserving access to the stat row
and navigation.

The existing Inventory, Settings, pause menu and companion journal retain their
styles. The existing DEV TOOLS overlay remains visible on those older screens;
it stays hidden over Skills/Map and returns when those panels close. No redesign
of those older screens is included in this acceptance.

## Interaction and source review

The final Mac Chromium 151.0.7922.34 run uses Apple Metal at DPR3 and reports
59 passing entries with no runtime errors or lost graphics context. Actual input
opens and closes the enlarged guide, bag and mole controls. It also exercises
all five hover descriptions, long press at both phone widths, short taps,
immediate drag cancellation and the delayed cross-row drag regression.

An earlier exported candidate, source
`140876a17a0f3af0d50e3a8a863f83c5dfa2c82b`, failed the delayed drag test:
holding Stamina and then dragging onto Mining reopened Mining's tooltip.
That candidate is rejected. The final source preserves the active touch owner
against emulated mouse/focus entry and timestamps drag events. The unchanged
delayed-drag test now passes at both 844 and 667 widths.

The tooltip numbers match the existing RunState authority: Mining and Running
reduce their matching stamina costs by at most 30%, while Carrying reduces only
the extra carrying cost by at most 50%. Prospecting accurately states that it
has no extra loot bonus. Stamina now explicitly requires rest without movement
or mining. No balance, save schema or native animation change was introduced.
Guide marker bounds follow the larger controls. The minimap collision fallback
is restricted to the enlarged layout so unrelated compact layouts retain their
existing arrangement.

The same final package passes input, overhaul, touch, layout and build-flavor
core suites, including 1,259 gameplay checks and 125 touch checks. The separate
Skills/save suite ends with `MINER_SKILLS_COMPLETE 28`. Both core-results and
Skills-log SHA256 values match the final build record. The DEV save identity
remains `user://ever_deeper_dev_run_v3.sav`.

Normal Mac WebKit 26.5 completes 51 observations using Apple GPU and no fixture
arguments. All six inspected images show the ordinary menu, fresh gameplay,
pause, saved-run reload, replacement confirmation and confirmed fresh game.
No crash, runtime error or lost context is recorded. These are Mac browser
checks, not physical-iPhone evidence.

## Final images inspected

All files below are from the `dev15-1-browser-review` artifact for run
`35822513557`, downloaded under `/tmp/hud151-accepted-browser`. Their byte sizes
and SHA256 hashes are recorded in the companion JSON.

From `dev15-1-browser/`:

- `01-new-game.png`, `02-surface-touch-released.png`, `03-earned-skills.png`.
- `04-approved-skills-844.png`, `07-approved-skills-667.png`.
- `05-map-844.png`, `06-map-667.png`.
- `08-inventory.png`, `09-settings.png`, `09-settings-back.png`.
- `10-exhausted-moss-touch-released.png`, `11-endless-touch-released.png`, `12-resumed-game.png`.
- `hud-844.png`, `hud-667.png`, `hud-3-2.png`, `hud-mole-open.png`.
- `tooltip-mining-844.png`, `tooltip-running-844.png`, `tooltip-carrying-844.png`, `tooltip-prospecting-844.png`, `tooltip-stamina-844.png`.
- `tooltip-touch-844.png`, `tooltip-touch-667.png`.

From `dev15-1-webkit/`:

- `01-ordinary-menu.png`, `02-after-new-game.png`, `03-after-escape.png`.
- `04-saved-run-menu.png`, `05-new-game-confirmation.png`, `06-confirmed-new-game.png`.

The earlier DEV15 baseline Surface and Skills captures were inspected for
comparison. Iteration captures informed fixes but do not provide acceptance
for these final bytes. This review does not certify every biome, a full animation
sequence, physical iPhone FPS/startup, or the separate publication mechanism.
