# Continuity after workspace pruning, 20 September 2026

## Current recovered work

### Corrected model rendered; atlas allocation failure isolated

The 1,017,722-triangle model completed all six maps and five actual Godot poses.
The independent visual gate still fails: the dome is repaired, but brown
speckling, angular dark sleeve patches and weak material definition remain.
Texture-free Godot clay also retains fragmented fine detail around the trim,
face and backpack; this is a separate unresolved runtime-rendering issue.

An actual UV audit found only 0.00192785 summed triangle UV area: about 0.193%
of the atlas. The main cloth had about 423 texels at 1024 squared. The former
smart-project padding consumed virtually all space across the many tiny native
groom islands. No light or geometry change can recover missing texture samples.

Source44b468c47daf3c2fcfe5c185149b3e5a354d45e7 adds a guarded UV-only repack.
It preserves exact geometry, corner normals, material assignments and weights;
before/after fingerprint26cb0c98af9ee0423369baa526ed6cdb0ae0db13cf7c6f208083cb8c7f67d101.
Actual summed UV area is now0.360700386 with a2048-pixel atlas. The isolated
six-map bake runs in `/tmp/ever-deeper-native-runtime-uv-20260920`. This numerical
repair is not visual acceptance. Inspect the new five rendered poses, and
diagnose the separate texture-free artifact before considering motion work.
The optional isolated camera-clip diagnostic keeps the default unchanged.
No new DEV/LIVE publication; ordinary Flow20 remains disabled and FPS paused.

### Actual renderer result and corrected geometry

The first six-map/GLB candidate completed, but the independent five-pose image
gate **failed**. The helmet dome was missing and surfaces fragmented. Retaining
the GLB's double-sided material property did not repair it. Valid equal-clay
comparisons traced the fault to preparation: the original4352-triangle dome
became a collapsed triangle after the legacy reduction (392reportedtriangles).
This rejected candidate and its actual images are retained in
`libfile_c23c8806954c819189c749305207a13c`, archive SHA256
`4d782c968934479eed6a7e08f19304988c6fd201907baafd19201c41074f38bf`.
The Library continuation is version89 at this checkpoint.

Saved source71358835cfe39b3d002732807efa26d8477c325b adds an explicit
`native_components` policy. Ordinary structural components keep all native
triangles. Only the existing dense face/groom/jaw/hair/hand copies are reduced.
Coincident welding is restricted to one connected component, identical weights
and material; custom normals and open/hard/UV/material boundaries are protected.
A first per-strand implementation was explicitly interrupted before saving a
model; the corrected implementation performs one checked weld per mesh.

The corrected preparation has1017722triangles. Prepared SHA256:
`10fe8fa003bf5a84b949a010465e7e787988db9d4f0909d7f4dbfb6dcb9d2b1e`.
It was produced at113e1325 before the added material bucket key. The subsequent
audit proves every reduced original component has one material, so that key
cannot alter the prepared weld groups. All unreduced component triangle counts
match their originals. Original donors and approved action remain unchanged.

Two actual equal-clay comparisons, cells0and21, pass the independent narrow
geometry review: helmet, body, boots, backpack, hands and tool retain the native
silhouette. Bone matrices are applied atomically using the native parent-aware
conversion; maximum error is4.77e-7. This is NOT material, motion, mobile-cost or
production acceptance. New six-map transfer is running on this corrected model;
the next gate remains five actual Godot images against the approved native PNGs.

### Earlier recovered checkpoints

Source is saved through `aba858c9ca7a505191050fe7351811a3faaccf49` on the same
work branch. The recovery chronology below describes the earlier state.
The complete regenerated preparation is saved as
`libfile_46678bf9aadc8191a562ac44d3ddb2a5`, archive SHA256
`1673042e9218f752e3b8c58331dff48318865571e0e8ad4f03e64dfba7251b92`.
Its three source members and archive CRC were verified after Blender exited.

The bounded five-pose renderer tools and identity guards are now saved; see the
[independent source review](native-reference-review-20260920.md).
No rendered native-runtime fidelity, gameplay integration or DEV approval exists.

The original 261-donor full albedo attempt was explicitly interrupted before it
produced a map. Persistent scene data produced identical sample bytes but no
useful speedup (34.21 versus33.36 seconds), so it was not adopted.

The opt-in Object-coordinate donor route stores each evaluated donor's signed
local vertex coordinates on unchanged, disconnected geometry. Cloned shaders
read that field; Generated, artwork UV and authored attributes stay separate.
The independent critic found no source blocker. Four representative original
donors produced identical RGB8 albedo, bump-normal and cloth maps. Raw albedo
and normal floats differ by at most1.79e-7 and1.41e-6 respectively; do not call
those raw buffers bit-identical. This is sample transfer evidence, not art acceptance.

Full merging exceeded the unchanged3e-4 corner-normal bound for `boot upper`,
`boot folded top`, `boot folded top.001`, and `helmet band rivet.001`.
These four are explicitly kept unmerged. The bound was not relaxed. The full
route has13 donors:617 merged originals plus12 unchanged originals. Input
receipts bind the exact helper, strategy and four exclusions. Its first complete
albedo map took109.68 seconds; the remaining maps and first GLB comparison are
still in progress. Full conversion does not establish fidelity or mobile cost.

Probe evidence is saved in `libfile_d94b1a60253c8191bc38b19f4d22a847`,
`Ever-Deeper-materialoverforing-20260920.zip`, SHA256
`a76a9435aac1d0085b31a0788a46d6171122f3cff5922321dcbc6adb39c1078a`.
The continuation file is version88. Flow20 remains disabled in ordinary gameplay;
DEV13 and LIVE remain unchanged. The next gate is exactly five actual Godot
poses against retained native cells0/12/17/21/35, then independent image review.

## Recovery chronology

The environment reported automated workspace pruning when Mats asked for status.
The local checkout, /tmp native models, all new captures, prepared native runtime
mesh and the unfinished upload cell disappeared. Mats did not delete them.

## Verified retained source

At recovery, the work branch codex/hero-loop-flow-20260918 pointed to
497e936a95d804e9360640ad1b2fbc5db37f48af, tree899ce5b2b2590687365098cb738dc0c8365182ca.
It has been cloned again. The later staged tree
dea768b6df5c0a742ccf78f73b1a566c331ce3d6 was NOT created remotely (404).
Do not describe the post497 controller fixes,650-cell exit bank or heading preview
as fully saved or present. The ordinary flow_graph_enabled flag remains false.

The original user-approved study20 atlas is still exact:
SHA256 6a869dc427d9d0e66c2582f02be9c6719842e8878dc88af7426d4dc1da70fca1.
Study20 and21 evidence already in Library is retained. The current v85 handoff
and study20 evidence were restored. Native v28 and Worn originals were recovered
and match94304c12a042b168c0d655dc0ceacffe2efb08997039a7a26c1ed0cc1770bc91
and0f90a49329acfd6db5b62cfbe6361efce1c79bea4a9d57a93fab130d46ac5b2b.

Latest published game is DEV13 runtime5ca6f0f77a1f87eaead777613062208159325068,
treec754eb0084391ecdb69c04122b7181fff17d5083. QA35238733050 and publisher35243448363
passed. Older README/START-HER DEV12 claims are stale historical text. No new
DEV or LIVE was published. Before pruning, comparison with5ca confirmed companion
files unchanged; the only prior world-owner difference was delayed ore squash.

## Findings reconstructed from the completed work conversation

These observations guide the next step but are not recovered capture evidence.
Do not cite missing report paths as current independently inspectable artifacts.

- Original diagonal study20 contact projected roughly52px right of the feet and
  visibly missed ore centered directly above. It cannot cover the full up sector.
- Rigid whole-native yaw+74.3355828421 degrees, same camera/anchor, projected
  contact cell21 to x79.99994 vs anchor80.00005. Its50-frame native derivative
  passed a narrow centered-up game image review at112/84/68px target distances.
  It preserved the original action, including the deliberately released support
  hand, but its pixels were a derivative, not Mats's original approved view.
- Three57-image entry ports targeted flow cell10, with airborne transfer and
  authored minimum0.085s. A fixed deadline capped entry0.12s and reserved visible
  swing time. Recomputing a fraction of remaining hit time had consumed the windup.
- Exact shown source identity, coalesced stop/restart and earned-impact presentation
  were fixed. Zero-delta packets did not replace an already displayed source.
-650 original-diagonal exit cells (50sources x13) were rendered at0.18s/61.2px
  travel, native reach/grip/endpoints and unchanged3600deg/s bound passed.
  Original source endpoints and one common final legacywalk12 frame were reused.
  Their heading problem still blocked production.
-1141 route checks passed, including worst legacywalk12 -> settle24 -> entry
  -> flow10/14/18 -> earned contact21. Actual fastest Forge5 fixture required its
  relic; an earlier requested Forge5 capture actually ran0.68s and was rejected.
- Two same-input150-frame comparisons (reverse-fast-c and entry-c) had identical
  mechanics, four hits/44damage, true0.425s cycle. Their new reports/frames were lost.
- Independent critic accepted only centered-up contact and specific early/late/
  worst-walk entry sequences. No complete movement,9/10 or DEV acceptance.

## Architecture blocker and next bounded step

Do not multiply the650-cell bank across arbitrary views. Exact target bearing is
currently discarded by cardinal facing. Preserve committed target bearing separately
from gameplay facing; _update_mining repeatedly supplies cardinal _swing_facing.
The hardest gate is an opposite-bearing restart at fastest impact deadline.
Simply switching view at a rest pose cannot guarantee reaching that deadline.

The existing native runtime pilot is a bounded alternative, not an approved
renderer switch. Its original prepared318150-triangle model was stored inside
Ever-Deeper-native-polish-checkpoint-20260916.tar.gz, libfile_d7b5f69ee8a48191a4b19316f04bca84.
That archive is TRUNCATED:86391262bytes/SHA040ae7c6cb0a32897afecdb1e206f70ff2b9280a728e0b3570b1aa82f92515cd.
motion.json and preparation.json extracted with their recorded hashes, but
prepared.blend was cut off. Preparation was then regenerated successfully with
318150triangles; that new local result also disappeared before persistence.

Reuse the preserved constant_donor_probe.py audited opaque RGB writer and donor
merge. Do not run the old bake blindly: raw Blender alpha serialization changes
RGB edges, and cached data maps must explicitly load as Non-Color. Only the369
strict constant-material donors may merge;260 coordinate-dependent donors stay.
A new bake_complete.py wrapper was written but not saved remotely. It ran no bake.
No complete bake, GLB, rendered runtime comparison or performance result exists.
The old native_rig._constrain reattaches both hands and is incompatible with the
approved Flow20 support release. Export actual full bone matrices through study20's
custom apply; do not substitute its older rest-axis solver.

Checkpoint each bounded source change BEFORE long rendering. Close and validate
archives before saving, persist outputs promptly, and never infer preservation
from a local path or successful numeric check. FPS remains paused.
