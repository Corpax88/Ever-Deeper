# Continuation: geometry blocker and static diagnostic, 17 September 2026

The previously prepared54df118 full-scene probe has now run successfully as a measurement. Its final report SHA256 is e060fa13e963229bea90cd9bc3e1131c9b5bc9b55fa2f77ab6aa9f1641162277. All135 dense rig constraints pass, but the independent critic rejects the unchanged candidate: at recovery .8125 the right hand is0/85 visible pixels, the left6/82 and the tool/hand mask has94/17/3 disconnected pixels. No images, bank or runtime adoption are approved.

`probe_recovery_elbow.py` is a newly prepared, parser-checked static discriminator, not yet run. It repeats the unchanged control, then rotates only the right elbow +/-25 degrees around the fixed shoulder-wrist at .8125. Both hands, all other bones, torso/head/feet/root/tool, real grip attachment and cap path remain protected; actual and analytic limb lengths must match. It uses the original629 meshes for both hand/tool masks. This is not a continuous animation and cannot establish five-phase/native-image readability. The original pose is restored before a closed atomic receipt is written.

No original pose owner, art, camera, material, input or production source is changed. Run once only after independent fixture review, with a clean immutable source, a fresh isolated output, the original asset bindings and a200MB geometry budget retaining1.5GB free. The3424134400-byte image-start guard is unchanged. Preserve both failures and passes. Current root handoff is authoritative for DEV13 publication; older project release docs on this study branch remain history.

The earlier handoff below is preserved for its exact input paths and source history; its "never run"/paused statements are superseded above.

---

# Native Worn/up study — paused for a new chat, 17 September 2026

No Blender, BVH, Godot or graphical process is running. The user requested a new
chat. The next full-scene geometry fixture is **prepared and parser-checked but
has never run**. Do not mistake this checkpoint for animation acceptance.

Source branch: `codex/native-up-stance-20260917` in `Corpax88/Ever-Deeper`.
The source immediately before this prepared fixture is
`894869b05335f48378036be5020cda8bafcaa437`, tree
`4ae0a827e1ff8e2fe107a6dba1bc30d400d81392`. The branch's next commit adds this
handoff, `upper-body-hinge-selection.json` and `probe_upper_body_hinge_scene.py`.
Verify its actual remote ref rather than treating the earlier SHA as HEAD.
This checkout's older general release docs are historical: use the main team's
current handoff for published DEV status. No native study has been adopted.

## Current selected proposal

One genuine anatomical bend: **10 degrees rest-local Y side lean and -12
degrees rest-local Z twist**, around the actual approved body joint
`(0, 0, 0.5849999785423279)`. Twist is applied first, then lean. The entire head
receives the same world delta as the torso. Arm IK is solved again to the
unchanged two grips; all other pose fields are preserved by identity.

Weight rises smoothly from zero to one by phase `.125`, stays through `.625`,
then returns to zero by `.82`. Actor root, original full leg chains, sole
matrices, contacts, model/materials, camera and scale remain fixed. The previous
fixed-cap tool orientation (+15-degree yaw, 45-degree contact pitch), rigid tool
trajectory, actual working-cap centroid path, selected ore and gameplay clock
are unchanged. The actual target remains `endless_d000002_node_006`, offset
`(+64, -80)` in the preserved ordinary up case. This is not target reselection.

`upper_body_hinge_pose.py` is the pose owner. Its SHA256 is
`d180c285396c91c86e39d317eb7d4a8252d071ac62039b7dd12c8dac297142a8`.
The selection JSON pins every input report and helper used to choose the arc.

## Closed evidence and precise limits

All paths below are under the scratch evidence root
`/workspace/scratch/d5437d917805/evidence/native-up-contact-arc/`; the root agent
is saving a closed `native-up-hinge-preparation-20260917.zip` for restoration.
Private native vertex arrays must not be uploaded to public Git.

| Evidence | Result / identity |
|---|---|
| `upper-body-joints-01/joints.json` | Approved real joint read, no mesh load; SHA `ae2619519c40cd1fbe14754bd67020e55294841d5f0681453b5a4e41a0f0c608` |
| `upper-body-hinge-math-02/hinge-reach.json` | Six of ten analytic cases pass; four reach failures retained. All ten prior case values exactly preserved when pose matrices were added. SHA `9a81e02942ccd6f652873f4c9bc118d15df4b9094ff2902675f04ce03ac05073` |
| `complete-head-cache-05/head-geometry-final.json` | Complete actual 179-object / 1,229,457-vertex / 2,217,334-triangle head cache. SHA `2d1cc98df5c19a44c4d53df09ec122fb0b6b67f6fd76e8b59fb5a49571eee443` |
| `complete-head-cache-05/closure.json` | All 20 payloads / 27,450,584 bytes checked after process exit, delayed readback and copy. SHA `2ec1c5fcd32cc6f9011c8d736900e1b5b1d794de008f6605f711e4ce05cda50b` |
| `root-complete-head-cache-05-review.json` | Root independently reloaded both complete vertex arrays and recomputed all errors/179 maxima; SHA `e80de52a38f42dd4d97ddb191d4b332e5a35f20887fa018eceb3c0c541ee853b` |
| `upper-body-footprint-02/footprint.json` | CPU conservative complete-head screening; SHA `aea61aa25c152c75ebcf1fb0f71389a9edd3290e2a41609fc309b21450e26105` |

The cache uses every helmet, face, ear, beard and hair object and exact immutable
modifier stacks. Source weights are exactly head-only. Generated weight
metadata is descriptive: the actual lamp bevel yields 0.9999995828–1.0.
The real second-pose all-vertex transport stress check used 14/-12 degrees and
measured maximum error `6.431065453669665e-7`, below the unchanged `1e-5` gate.
Both full reference and actual second-pose coordinate arrays are retained.
This is head-transport evidence, not full-scene acceptance of the selected arc.

For selected 10/-12, all 132 windup and 147 contact shaft pixel centers lie at
least two native pixels outside the conservative complete-head cover. Minimum
centerline margins are 5.52/5.85 native pixels. The maximum dense analytic arm
reach remains 0.671060784 (limit 0.71), whereas 10/0 or 14/-12 approaches 0.702.
The `.8125` recovery centerline still enters the cover by about one pixel.
Inside a conservative cover is not proof of actual occlusion; outside it is not
proof of body/arm visibility, material readability or animation quality.

## Preserved failures

- `complete-head-cache-01`: strict fixture assumed armature-only; the original
  helmet also has pre-armature SOLIDIFY. No native geometry defect asserted.
- `complete-head-cache-02`: next strict assumption stopped on pre-armature
  BEVEL. This run saved the complete 179-object modifier inventory.
- `complete-head-cache-03`: strict generated-weight metadata assertion stopped.
  `mesh-weight-layers-01` separately documents Blender float interpolation.
- `complete-head-cache-04`: exit zero and an immediate successful tool read were
  observed, but the later persisted progress JSON lacked the transport block.
  Cause is unresolved. `cache-report-integrity-stop-01` preserves the exact
  incomplete bytes, source, receipt and facts; no missing metrics were rebuilt.
- `complete-head-cache-05`: source `894869b0` used isolated `/tmp`, distinct
  atomic/fsynced final report, raw actual coordinates and post-exit hashes.
- `upper-body-footprint-01` correctly refused the incomplete 04 receipt.
- Previous native image trials (`354bc9bd`, `7f1b22c4`, `7b1a5dda`) remain
  rejected for up mining readability. The `66bb10e1` fixed-cap orientation was
  rejected on actual shaft/hand occlusion without rendering images.

## Next bounded action after continuation

Root authorized **one** full-scene geometry/BVH run for 10/-12 after the clean
immutable source checkpoint. That run was not started before the new-chat stop.
Coordinate the sole renderer, verify the branch/ref and source hashes, then use
`probe_upper_body_hinge_scene.py`. It checks 135 actual rig samples (134 distinct
normalized phases), real two-hand attachment, bone lengths, root/feet/sole/tool
matrices, body-joint/head relationship and the working-cap trajectory. It then
uses all 629 original objects / 2,714,340 triangles for actual ray masks at
`.125, .375, .55, .625, .8125`, with each hand measured separately and recorded
shaft/hand connected components. It reuses each full BVH instead of rebuilding
it for the hand query. This fixture has only been parser-checked, not exercised.

Run with a fresh isolated `/tmp` output and retain every failure. Use
`hinge-scene-final.json`, its printed SHA and a closed-process delayed hash
readback before copying. Never use `hinge-scene-progress.json` as final proof.
The original five critical phases must all be reviewed, especially recovery;
no head-only percentage can replace full-scene visibility. Ask an independent
critic/root to review the saved geometry before any five native images.
**No images, full bank or in-game pair are authorized by this handoff alone.**

Required CLI inputs (plus `--output` pointing to a new `/tmp` directory):

| Argument | Current input |
|---|---|
| `--native-tools` | `/tmp/ever-deeper-native-sources-20260917/hero-blender/v9` |
| `--project` | `/tmp/ever-deeper-native-ingame-f34bf748/project` |
| `--recorded` | `evidence/native-motion-ingame/render-f34bf748/up-candidate/native-ingame.json` |
| `--target-identity` | `target-identity-01/contact-target-identity.json` |
| `--pivot-report` | `fixed-cap-pivot-math-02/pivot-reach.json` |
| `--joint-report` | `upper-body-joints-01/joints.json` |
| `--hinge-report` | `upper-body-hinge-math-02/hinge-reach.json` |
| `--head-report` | `complete-head-cache-05/head-geometry-final.json` |
| `--footprint-report` | `upper-body-footprint-02/footprint.json` |
| `--head-topology` | `head-topology-04/topology.json` |
| `--inventory-report` | `evidence/native-up-working-plane/anatomy-visibility-01/visibility.json` |

Blender 4.5.3 executable is currently
`/tmp/ever-deeper-runtime-20260917/blender-4.5.3-linux-x64/blender`; load the
approved `Ever-Deeper-hero-dark-eyes-v28.blend` with SHA256
`94304c12a042b168c0d655dc0ceacffe2efb08997039a7a26c1ed0cc1770bc91`.
Worn equipment SHA256 is
`0f90a49329acfd6db5b62cfbe6361efce1c79bea4a9d57a93fab130d46ac5b2b`.
Restore the game-test environment and exact native originals if scratch is gone.

Ordinary arbitrary interrupts/turns/recovery remain unclosed. The original
`.625` transition pilot is diagnostic, not a shipping controller. No animation
quality, full-polish, all-tool, device or 50-FPS approval is implied here.
