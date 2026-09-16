# Native animation and runtime pilot handoff — 16 September 2026

Work was frozen because Mats requested **SAVE FOR NEW CHAT**. This is a work
checkpoint, not visual, animation or performance acceptance. No production
hero atlas or GameData speed was replaced. The real game speed remains 340 px/s.

## What is saved in source

The shared-heading native motion/export revision was checkpointed by root at
`6e3e4fa`. The initial runtime preparation/bake pipeline and cadence fixture
were saved at `9fed86ffdfbbea14e1a212671e06558c0b5b968d`. The runtime renderer
and review scaffold were saved at `1b11e0fd393eecf9111a00020dfd7a0a48f06cad`.
Root owns the final save commit after this handoff.

Since that last scaffold checkpoint, only
`tools/hero_v28/runtime_pilot/native_rig.gd` has further animation source edits:
75 ms blends, retained gait phase across short interruptions, and bounded
retargeting of an airborne ankle to the real leg's reachable sphere. The latter
never moves a planted contact. This handoff is also new. All these files are
frozen for root's final checkpoint.

| File | SHA256 at freeze |
|---|---|
| `tools/hero_v28/runtime_pilot/export_runtime.py` | `eaf68b7beacf8435e1f9fc2239c0b2594dd6202401b6fb6c5dc775d86bf22429` |
| `tools/hero_v28/runtime_pilot/native_rig.gd` | `5ff20e2c13379d08a966c357def73d1f9e4e18f738918b079b79f460cd60eb5e` |
| `tools/review_native_rig.gd` | `e897071d533ef0210995615418117b48931e84ba2c63cf20e7b3dc1a548f6c89` |
| `tools/review_native_gameplay.gd` | `e4434994986f3b1c7c8d65aa869922f22f17e0a944b426a3e3550e6153e559f8` |
| `tools/hero_v28/runtime_pilot/README.md` | `33807a42f99ef17d006b7648c16b0bfbddf630ddbe056f8dba85b345a8d99ab9` |

The code parses in Godot 4.7.2. The Python export pipeline compiles. Successful
parsing does not approve the unfinished motion solver or the render pipeline.

## Native frame evidence that actually exists

Working base: `/workspace/scratch/5a78be25fc28`.

`native-motion-pilot-b1` contains **124 actual native Blender frames** from the
approved v28 rig, original material/camera setup and original Worn/Deepcore
equipment. No image-generated or reconstructed character was used.

- Worn: right/up, 48 frames each. Idle 1, walk 16, mine 16, and three exact
  authored bridges with 5 frames each. The walk/mine source phase is `.625`.
- Deepcore: right, 28 frames. Idle 1, walk 16 and the 11-frame forward-only
  canonical rotor coast from mine phase `.625` to running.
- Original native source fingerprints are recorded in each pilot manifest.
  Worn: `c0e7d6a1d7b25ed4fbcfba6270685346c978889f22d75d40a98fa28d38de4bc7`.
  Deepcore: `4ee895e2402d5bb154a423f75aa00122be67c633b9e9d98df280909716c32cc5`.
- `native-motion-candidate-b1` contains the independently packed, genuine
  160px-cell candidates. SHA, alpha, clipping and native grip checks passed.
  These remain outside production assets.

`native-motion-review/native-pilot-340pxs.mp4` is a deterministic diagnostic
assembled from those frames. `native-pilot-340-preview.json` records exact
phase/time/root motion and clip selection. `native-pilot-340-contact-sheet.jpg`
shows selected frames. It is not Godot gameplay or an FPS measurement.

The exact transition/pose numeric checks are also retained in that directory:

- `dense-gameplay-340.json`: 292,908 sampled target poses and 8,492 transitions,
  11 gear types × 4 views at 340 px/s. Minimum leg reach margin 0.0019142276
  native units; maximum endpoint position error 0.00000250924.
- `continuity-gameplay-340.json`: 396 transitions and 5,336 raw boot-hull
  material-point contact samples; second-order finite-difference checks passed.
- These are target pose/raw hull checks, not rendered mesh acceptance. The
  exact authored source-phase bank does **not** cover arbitrary interruptions.

## Cadence critique and real controller comparison

The 340/88 pilot was rejected for promotion. It has 7.73 footfalls/s, 47 ms
support and 63.6% of each cycle airborne. The rendered temporal arrays show a
comparatively quiet torso over very fast feet; the miner reads too hurried and
light. Identity and matching heading improved, but that does not approve the
motion. The critic could inspect frames/trajectory/contact sheets, not directly
watch continuous MP4 playback through the image tool; this limitation was
explicitly reported to root.

The subsequent **real Godot hub/controller** comparison exists in
`native-gameplay-cadence-b1`:

- `native-gameplay-260-vs-340.mp4`, `native-gameplay.json` and four endpoint PNGs.
- Right/up routes at 260 and 340 all passed actual controller/collision distance
  checks. Gait phase follows actual distance / 88, using genuine pilot atlas
  pages and their real ground anchors.
- 483 deterministic movie frames, approximately 8.05 seconds. This is not
  measured FPS. The four routes travel 472.332, 617.668, 394.332 and 515.667 px
  respectively over 1.8167, 1.8167, 1.5167 and 1.5167 seconds.
- The 260 case retimes the **340-authored poses**. It is a cadence/traversal
  comparison, not an approved reauthored 260 animation. It yields 5.91 footfalls/s
  and 61.5 ms support. A gameplay speed decision remains open.
- Achievement toasts from the full built-hub fixture appear in this film. The
  later runtime-rig fixture hides that toast layer, but has not been rendered.
- `cadence.avi` is a reproducible 103 MiB intermediate. Root can exclude it from
  the private save while retaining the 13 MiB MP4, JSON, logs and PNGs.

Merely stretching the authored stride is not the recommended fix: 112 px at
340 reduces cadence but raises airborne time to 71.4%. Increasing contact travel
to 18–20 px exceeded native leg reach in the current pose. These were numeric
geometry probes, not rendered approvals.

## Why a runtime rig pilot was authorized

Exact arbitrary, repeatedly interrupted motion cannot honestly be supplied by
the single-phase sprite bridges. A small phase-gated atlas graph would introduce
bounded visual delay/root-offset limits; keeping the full native pose at runtime
can instead blend ongoing poses and solve real grips/contacts. Root explicitly
authorized this **bounded Worn-only feasibility pilot**, preserving native
identity and requiring visual plus performance gates before any production swap.

The exact Worn inventory is in `native-runtime-inventory/inventory.json`:

- 629 visible source mesh objects, 634 object/material partitions, 32 materials.
- 2,520,394 base triangles; 3,130,548 evaluated triangles; 1,693,994 evaluated
  vertices. The 1,156,484-triangle face and 602,400-triangle facial groom already
  exist as dense base geometry. Disabling subdivision is insufficient.
- 17 native bones. 619 meshes have one bone influence, 10 have two.
- Source materials use procedural noise, bump, cloth weave and facial vertex
  attributes. Face, groom, beard and hands lack UVs. A plain glTF material export
  would lose visible detail.
- Native rendering uses AgX / Medium High Contrast and three area lights.

## Prepared private runtime candidate

Directory: `/workspace/scratch/5a78be25fc28/worn-native-runtime-b1` (about 234 MiB).

Preparation completed. It copied and reduced the actual meshes, retained the
actual rig/weights and full-detail source, merged the derived geometry, created
an atlas UV layout, and exported exact native pose matrices. It did not create a
new face or character proxy.

The result is **318,150 triangles**, above the nominal 120k target. The target
allocations total 119,862, but collapse preserves thousands of separate strands:
facial groom remains 180,286 triangles and hair 46,534. The actual face reaches
27,998. Those strands were retained pending visual and cost review instead of
being silently deleted. There is not yet evidence that 318k is viable on target.

| Durable candidate file | Bytes | SHA256 |
|---|---:|---|
| `prepared.blend` | 236885784 | `2e7da103c3b4d16cf159d68525f1853630058a85747964a9f8305eb54aeedd91` |
| `preparation.json` | 157745 | `6755d297648e72520d57b5d0827e520bd6cbeb3960c4d080c057e7ae971d5499` |
| `motion.json` | 1195299 | `8926a5a297b70984711c32876a9271fd390fbddf72028074744b13dc1f5417fd` |

**Bake state at save:** interrupted during the first `albedo` channel. No PNG
completed. The owned execution session exited 130 and the Blender process no
longer exists. Do not try to resume a stale PID. The intact prepared file is the
restart point; mesh preparation need not be repeated. `bake.log` is retained.
The first bake spent several minutes repeatedly synchronizing source objects;
inspect bake operator selection/settings and profile this before accepting a
long unattended restart. No completed `candidate.json`, GLB or runtime render
exists yet.

The planned texture transfer is original albedo/face attributes, roughness,
metalness, tangent normal detail, AO and cloth mask at 1024. The estimates are
17.3 MiB for three RGBA8 textures plus one R8 mask including mipmaps, a few MiB
geometry, and 0.31 MiB per 200px color/depth target before buffering/MSAA. Actual
formats and overhead must be measured; these estimates prove no FPS result.

## Runtime solver state and unresolved gates

`native_rig.gd` loads the external candidate into a transparent 200px SubViewport,
maps exact native bone transforms through the imported bind poses, and samples
native idle/walk/mine curves. It uses 75 ms cancellable pose residuals, real
two-bone arm/leg solves, rigid hand/tool frames, real boot-hull rolling contacts,
retained stop offsets and offset release during a full airborne interval.
Short movement interruptions preserve gait phase. This is experimental code.

An early stress probe exposed a real defect: restarting the same support foot
on every tiny movement burst could retain a planted foot while authoritative
movement accumulated distance. Retaining gait phase improved it. A later probe
also exposed overshoot of a free ankle during inertial blending; free ankles now
respect the actual reach sphere. Planted feet are not projected or slid.

The latest **mechanically reset mining-clock** scratch probe is
`native-motion-review/check_runtime_mechanical.gd`. It exercised 40 transitions
at each of 260 and 340, including two-frame walk/idle/mine interruptions:

- Both speeds: maximum limb reach excess 0.0, airborne projection 0.0 in that
  particular final run.
- 260: maximum extra pelvis lowering **0.0394412373** native units. This still
  exceeds the review fixture's 0.035 limit and needs correction or a carefully
  justified visual assessment; it has **not** been waived.
- 340: no extra pelvis lowering in that particular run. This does not overturn
  the rejected 340 cadence or approve arbitrary interruptions.
- Earlier `check_runtime_pose.gd` deliberately injected phase jumps into new
  mining cycles, unlike real gameplay's reset to phase zero. It found larger
  failures; do not relabel those as a successful gameplay test. Separate actual
  arbitrary *source interruptions* from impossible fresh-cycle phase teleports.

No rendered runtime solver motion has been seen. Root must still inspect foot
contact, torso response, tool weight and transitions. The current isolated
review script's comment says 85 ms; the actual constant is now 75 ms. Update
that comment when authoring resumes.

The prototype's shadowless omni lights approximate the original area-light
positions/colors; energy, ambient response and tone-map look have not been
matched. Original material detail is intended to be baked into PBR channels,
not replaced by a screenshot texture. This lighting/material fidelity is a
major open gate. There are no runtime 3D shadows in the pilot.

## Resume commands and order

Restore the private archive and the final source commit first. Existing approved
native v28/v9 originals already have durable identities recorded by root; do not
upload native private Blender files to the public repository. The scratch paths
below are convenience paths and may need changing.

Verified executables at freeze:

- `/tmp/ever-deeper-runtime-20260915/blender-4.5.3-linux-x64/blender`
- `/tmp/ever-deeper-runtime-20260915/Godot_v4.7.2-stable_linux.x86_64`
- `/workspace/scratch/02374ae65f32/runtime/xvfb/usr/bin/Xvfb`

After checking why the first channel was slow, restart from the saved prepared
scene. Coordinate CPU-heavy work around other agents' timing windows:

```sh
blender --background /absolute/worn-native-runtime-b1/prepared.blend --threads 2 \
  --python tools/hero_v28/runtime_pilot/export_runtime.py -- \
  --output /absolute/worn-native-runtime-b1 --bake-only
```

Then run **five reference poses before motion/cost captures**:

```sh
python3 tools/run_rendered_isolated.py --godot /absolute/Godot \
  --xvfb /absolute/Xvfb --output /absolute/native-rig-poses \
  --resolution 1696x780 --timeout 300 -- \
  --script tools/review_native_rig.gd -- \
  --candidate=/absolute/worn-native-runtime-b1 \
  --output=/absolute/native-rig-poses --mode=poses
```

Compare the 200px runtime PNGs with these genuine frames in
`native-motion-pilot-b1/worn`:

| Runtime pose | Original PNG |
|---|---|
| `idle_000000` | `right-idle-000.png` |
| `walk_000000` | `right-walk-000.png` |
| `walk_250000` | `right-walk-004.png` |
| `mine_437500` | `right-mine-007.png` |
| `mine_550000` | `right-mine-009.png` |

Do not proceed merely because the renderer loads. Preserve the approved face,
silhouette, cloth, metal and hand/tool attachments. If that gate passes and the
solver's numerical limits are resolved, run the same tool with `--mode=motion`
and `--write-movie /absolute/review.avi --fixed-fps 60` before the `--` user-arg
separator. This fixture uses the real hub/controller but explicitly drives
mining poses without gameplay damage; it does not replace a real mining test.

Run `--mode=cost --cost-seconds=20` **without movie/fixed-frame flags** in a clean
timing slot. It compares atlas / rig / atlas with the candidate resident and the
same stationary animated hero/hub workload. It is incremental overhead evidence,
not a complete-game, mobile Safari or physical iPhone performance gate.

## Private archive contents requested from root

Save these derived directories, not another copy of the public git checkout:

- `worn-native-runtime-b1` — preparation, high-detail source retained for baking,
  exact pose data and interrupted bake log.
- `native-motion-pilot-b1` and `native-motion-candidate-b1` — genuine 124 frames
  and packed pilot candidates.
- `native-motion-review` — diagnostic film/contact sheet, numeric reports,
  continuity/probe scripts and a copy of this resume text.
- `native-gameplay-cadence-b1`, excluding `cadence.avi` — real controller movie,
  frame PNGs, report and logs.
- `native-runtime-inventory` — exact source geometry/material counts.

Root handles the Library archive and records its durable identity in the main
handoff. No whole-game score, production native-rig replacement, 260 movement
change or sustained 50 FPS approval is implied by this checkpoint.
