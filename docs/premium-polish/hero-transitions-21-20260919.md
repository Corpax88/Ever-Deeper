# Study21: exact walking entry and interrupted bridge

Mats accepted study20's visible held-mining flow and said Go. This work keeps
that loop and fixes two reproduced discontinuities around it. This is a
reviewable sparse preview, not a production replacement or publication.

## Source and preserved motion

Repository `Corpax88/Ever-Deeper`, branch `codex/hero-loop-flow-20260918`.
The motion, capture and consumer source was saved and remotely verified before
rendering at `8be8ce64635bced52bb3ca32f2118e58dba2b588`, tree
`7475acdb624ce4aadfd52f2efbb4deedabe0fe9f`. Later commits add evidence/docs/media
helpers; fetch the latest branch rather than resetting to the render checkpoint.
Baseline source is `f9ff3d7e4f1d85ddc04b931700ceacbc04c39fd8`.

Approved loop atlas SHA256 remains
`6a869dc427d9d0e66c2582f02be9c6719842e8878dc88af7426d4dc1da70fca1`;
approved walking bridge remains
`e3769f649875482dd02d85307e1a62848bed0b7cd3d018919caa3342c8a2eb62`.
No production scripts, scenes, atlases, gameplay, camera or save code changed.
FPS investigation remains paused.

## What the preview changes

The interrupted walking bridge previously discarded its displayed intermediate
pose at frame 90. Its new14/60 seconds path starts at exact bridge cell 6 and brakes
into actual legacy down-idle cell 0, with alternating planted feet. The idle
clock 0.15 seconds still selects native sample 0 under the declared production times.

Walking into mining previously swapped the view at frame 8. Its new8/60 seconds path
starts from actual up-walk cell 15 and reaches the exact approved mining cell 10
at the unchanged gameplay progress. The next real frame displays cell 11.
The main hand follows a torso-relative arc that avoids folding through its
shoulder, while the support hand releases into the already approved pose.

Original legacy bone matrices and lighting are transformed into one camera;
simply transforming IK positions had changed limb roll. Continuous chain
planes and endpoint local roll eliminate the observed arm/knee flips.
The native originals and the approved loop design remain intact.

## Evidence

| Case | Real frames | Hit frames | Damage | Baseline comparison |
| --- | ---: | --- | ---: | --- |
| Interrupted walking |126|47,76|8|All 126 mechanical rows identical|
| Walking into mining |106|25,65|8|All 106 mechanical rows identical|

Both Godot4.7.2/X11/Mesa runs exit 0 and include `TRANSITION21_COMPLETE`.
They capture actual input, world state and rendering at fixed 60Hz, 1696×780.
The input-release QA also passes. Protected-file checking retains only its
known `scripts/player/player_visual.gd` mismatch; that file matches baseline
byte for byte. These are not physical-device or FPS measurements.

Blender4.5.3 produced 24 genuine 200px native images, packaged to 160px cells.
The first six analytical attempts exposed specific drift/rotation defects and
were rejected without rendering. G passes 61 substeps per edge, full-bone source
and sink identity, hand targets, support-foot matrices and temporal checks.
Largest 60Hz bone changes are 29.17 degrees for braking and 39.78 degrees for entry.
These numerical checks support the diagnosed render; they do not rate beauty.

All four endpoint silhouettes match the actual old banks within 1 display pixel.
RGBA is not identical: small resampling/highlight differences remain in the
legacy endpoints. Actual boundary frames show no visible lighting flash/pop.

Independent critic: narrow ordered-frame pass. Brake89→90 progresses instead
of swapping pose;103→104 returns cleanly to legacy idle. Entry7→8 preserves
the incoming view;11–16 progresses through the turn, with a clean15→16
handoff. All 232 mechanical rows were independently compared with zero changes.
The critic did not watch continuous video or assign a numerical visual score.

The entry still makes a substantial facing turn in 0.133 seconds. This fixes the
one-frame discontinuity but does not unify the old/new view conventions or
establish subjective naturalness at normal speed. No further speculative
render is justified by the inspected frames.

## Artifacts and continuation

`Ever-Deeper-overganger-21.mp4` contains both actual-game cases at original 60Hz.
The accompanying 50Hz GIF has no synthetic interpolation. Both were encoded
to closed temporary files, decoded, frame/duration checked and atomically
installed. The proof archive includes all actual baseline/candidate frames,
native renders/masks/atlas, reports, logs, rejected analytical reports and
the independent review. Repository source stays in GitHub.

Exact artifact hashes and report identities are in
[`evidence.json`](../../tools/native_motion_ingame_pilot/studies/transitions_21/evidence.json).
Local source is `/workspace/scratch/c58aae856e15/ever-deeper`; native 24-frame
bank is `/tmp/ever-deeper21-native-g`. Treat scratch paths as disposable;
restore the saved proof archive when needed and verify its hashes.

Next work must extend actual source-phase coverage, interrupted new edges,
other directions, tools and outfits. The runtime currently selects only two
exact tuples and falls back for uncovered input; it is not safe to adopt as
a general production bank. Keep study20 unchanged, reuse these validated
frames, and apply the existing actual-mobile/gameplay release gates before
gated DEV publication. No DEV or LIVE was changed by this preview.
