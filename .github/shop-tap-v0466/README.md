# Shop tap and browse correction — v0.46.6

A tap must select an item and update its preview immediately. Previously the shared
carousel treated every contact release as carousel movement, and swipe settling chose
the preview. Hover and focus also used the selected-card styling, so a card could look
selected while the large preview still showed another item.

CommercePanel now treats tap selection separately from list navigation:

- Up to three options stay fully visible with `Tap to preview`.
- Longer shop lists swipe smoothly to browse; swiping does not change the preview.
- Tapping a visible card updates its art, description, stats, cost and action without
  moving the card away. Only the selected card gets the accent selection treatment.
- Purchase/equip remains a separate main-button action. A drag or canceled tap never
  confirms. Confirmation snapshots its item ID before listeners can close the panel.
- Swipe handling is limited to the catalog pane; details keep independent vertical touch scrolling.

The same component covers Starforge, Tool Forge, Light Lab, Wardrobe, Forge, Wayfarer,
Treasure Chamber, Lift Workshop and depth shops. Single-item shops retain their direct
preview and action. Authored art, fonts, prices and save format are unchanged.

## Source and exact release

Start from the v0.46.5 editable source described in `EVER_DEEPER_HANDOFF.md`, then apply
`.github/shop-tap-v0466/source.patch` from its game-source directory. Source hashes are
listed in `source-files-sha256.json`. Use Godot 4.7.2 and the existing Web DEV / Web Production
presets. Do not use the outdated top-level repository source.

The final exact packs pass isolated native LIVE 72 / DEV 74 touch checks and LIVE 859
gameplay checks. The browser regression suite deliberately taps all three Starforge
cores, checks unchanged resources during preview, confirms only the chosen core once,
and swipes then taps in Tool Forge, Light Lab and Wardrobe. It also retains Settings
input isolation and the existing pet/inventory/achievement touch regressions.

The QA workflow captures 30 mobile shop states and actual tap-preview screenshots.
`review.json` binds the inspected evidence to the exact candidate hashes. Publication
requires successful QA, backs up the existing deployment, and verifies all 18 public files.
