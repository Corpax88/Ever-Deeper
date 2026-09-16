LATEST: [Published DEV9 and paused continuation](dev9-20260916/HANDOFF.md).
The following rebuilt-source notes are historical.

Read [START-HER.md](../../START-HER.md) for the saved source identity, original mandate, preserved evidence and next steps.

# Premium polish — rebuilt source checkpoint

This is a reconstructed subset of the premium-polish work, based on canonical
source `d4619e5429326b880c4da2d466a2bf5351f0f46c`. The previous unpublished
checkpoint and its newly rendered atlases were lost when its local checkout
was cleared. This branch does not reproduce that complete checkpoint.

## Restored and checked

- Retired chest/storage runtime, controls, data and 20 related textures.
- Removed disconnected portable-base building and belt runtime/assets while
  preserving the current five workshops, relic delivery, inventory and trading.
- Retained seal targets through hit follow-through, with movement cancellation.
- Drained pending hero texture loads when the game exits.
- Updated obsolete chest assertions and documented intentional protected-file
  changes in `protected-changes.json`.

All 14 current source cases pass: 13 in `qa-results/rebuilt-source` and the
corrected layout case in `qa-results/rebuilt-layout`. The protected-file and QA
registry gate passes. `tools/capture_recovery.gd` captured 31 actual source states
at 1696×780 through authenticated Xvfb, Godot 4.7.2 and Mesa llvmpipe; all images
were inspected. These checks do not establish exported-package or iPhone FPS.

## Remaining work

The larger shop/hub layout, compact top HUD, bottom context-action placement,
terrain blending, lighting/performance changes and new animation sets still need
reconstruction and review. Current production atlases remain the canonical v28
baseline; the five previously completed replacement sets are not in this branch.
Approved native Blender originals remain available through their saved sources.
Do not substitute a recreated character or claim that the lost animations were
uploaded. Resume native export using `tools/hero_v28/README.md`.

Use [the testing handoff](../TESTMILJO-HANDOFF.md) to restore local graphical
testing and the established Mac/Safari route. Existing package, visual and
physical-iPhone acceptance gates remain open. No game deployment is included.
