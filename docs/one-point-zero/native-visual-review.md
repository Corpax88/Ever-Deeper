# Native 1.0 visual acceptance

`tools/review_one_point_zero.gd` is an external SceneTree harness for an already exported DEV package. It refuses source-only or headless execution. The package is not unpacked, patched, or repacked during review.

The matrix captures actual PNG framebuffers at 2532×1170 (844×390 at DPR 3), plus 844×390 captures for the new-player HUD, the actual Pulse four-row and Deepcore five-row recipes, and the completed Hub. Other states cover first Deep entry, mined edges in all five strata, diggable versus permanent boundary walls, all five generated relics on their physical ropes, the mole's authored Tunnel Home digging action, real Hub arrival, empty/partial/complete Museum states including pedestal selection, Tool Forge upgrade preview, Tunnel Workshop preparation benefit, and continued excavation after relic five. Every visible gameplay capture asserts that the goal and minimap have separate safe-area bounds and clear the action controls.

Prerequisite resources and camera/pedestal approach positions use explicit fixtures. Purchases, generated relic discovery, attachment, return, placement, construction and continued mining go through actual runtime owners. Mouse InputEvents travel through the viewport for the mine control and context button; the gameplay wait can advance through the same physics/process methods as the independent journey suite. One transient Tunnel Home image freezes simulation time after the action starts so slow software rendering can capture its real authored frame. The report identifies each fixture and this freeze.

Run only after performance measurements finish, since these captures share their software renderer:

```sh
python3 tools/run_rendered_isolated.py \
  --godot /workspace/scratch/6604552ab244/runtime/Godot_v4.7.2-stable_linux.x86_64 \
  --xvfb /workspace/scratch/6604552ab244/runtime/xvfb/usr/bin/Xvfb \
  --project /workspace/scratch/6604552ab244/Ever-Deeper \
  --resolution 2532x1170 --timeout 600 \
  --output /absolute/capture-output \
  -- --main-pack /absolute/candidate.pck \
  --script /workspace/scratch/6604552ab244/Ever-Deeper/tools/review_one_point_zero.gd \
  -- --output=/absolute/capture-output --pack-source=/absolute/candidate.pck
```

`review.json` records the exact PCK SHA-256, package version, engine/renderer/adapter, each PNG SHA-256 and framebuffer size, goal/stream snapshots, runtime assertions and any failures. `automated_assertions_passed` only concerns those assertions. `visual_review_pending` stays true until a human/independent critic inspects the PNGs against the approved art; native captures do not certify browser pacing or physical iPhone performance.

Current status: harness passes Godot 4.7.2 parse checking. Awaiting the immutable DEV candidate and free renderer before execution. No release approval or publication is implied.
