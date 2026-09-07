# Wardrobe overhaul — v0.46.7

Wardrobe mixed cosmetic station finishes with outfits, used the retired Character B
art, and showed identical station thumbnails for different finishes. This made its
choices misleading and disconnected the preview from the current player.

Wardrobe now contains exactly five clothing colors: Miner Green, Expedition Blue,
Archivist Sand, Starweave Violet, and Deepheart Red. Each previews the existing dad
hero with the player's actual tool, real idle frames, and the same clothing mask,
shader and palette used in the world. Skin, glasses, helmet and tool are untouched.
No generated assets or redesigned character are included.

The next locked color is the upgrade itself, with the existing material cost.
Further colors show their required Wardrobe level. Unlocking preserves the worn
outfit and keeps the newly owned color in preview; Wear outfit equips it for free.
The panel stays open to compare outfits. Preview and browsing never equip or spend.
The current outfit opens selected. Existing saves, unlock levels and prices remain
compatible. Previously saved station decoration is preserved in the world, but
station-finish choices no longer clutter Wardrobe. Other shops retain their menus.

The approved metallic shop frame, fonts, rose accent and tap/swipe controls remain.

## Continuation source

Reconstruct v0.46.6 following EVER_DEEPER_HANDOFF.md, then apply
.github/wardrobe-v0467/source.patch from game-source. This patch includes the new
outfit_preview.gd and UID; do not additionally copy the standalone reference file.
Use Godot 4.7.2 and Web DEV / Web Production. The distribution repository's old
root gameplay files are not authoritative. Exact candidate hashes are in bundle.json.

## Verification

- Exact LIVE PCK: 97 native touch/transaction checks pass.
- Exact DEV PCK: 99 native checks pass, including DEV menu isolation.
- Tests cover insufficient materials, locked selection, exact unlock charge,
  free equip, persistent save reload, and all five production hero/color previews.
- Existing shop tap/swipe, Settings blocking, inventory, pet and achievements
  touch regressions are retained.
- Final browser mobile captures and touch results must pass and be manually
  reviewed before publication. Physical iPhone acceptance remains for Mats.
