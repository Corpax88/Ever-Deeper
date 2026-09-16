# Approved Gruvepappa v28 integration

The approved native Blender v28 model is the visual source. These tools combine it
with the existing v9 native working hands and tool meshes. The Blender sources are
retained with the project owner; personal reference photos are not repository assets.

Use Blender 4.5.3 LTS with the approved v28 scene and a native-tools directory containing
`<gear>/hero.blend` for all eleven existing gear keys:

```sh
blender -b approved-v28.blend --python tools/hero_v28/export_hero.py -- \
  --native-tools /path/to/v9 --output /path/to/frames --gear worn --threads 2
python3 tools/hero_v28/pack_frames.py --frames /path/to/frames --game . --gear worn
```

Repeat for each gear. `--review` generates seven diagnostic poses in four directions.
The output fingerprint prevents accidental mixing of scene/export configurations.
Completed frame markers allow interrupted jobs to resume. Each pose is assigned
atomically from world-space targets, so parent transforms from a previous frame
cannot displace the head. Camera transforms are evaluated before sampling the floor
anchor; older manifests had sampled the preceding camera transform. Grips and bone targets are checked numerically.

The exporter produces genuine 200px RGBA renders and separate cloth AOV masks.
Atlas writes are atomic and PNG checksums are validated before packaging.
Packing downsamples to the original 160px cells, eight columns, original animation timing and ground anchors projected from each active
camera. Crusher retains its 96 mining frames.
The game remains a 2D sprite renderer; no Blender or 3D rendering runs on mobile.
Skin, hair, eyes, leather and brass are excluded from outfit recoloring.

After integration, run the current core/invariant gates and export both flavors.
`HERO_V28_CAPTURE=1 CAPTURE_END=216 node tools/capture-web.mjs ...` captures all
gear/direction/pose combinations, outfits, worlds, wall corners, permanent walls, gates and transitions in the actual exported game.
`HERO_MOTION=1 CAPTURE_END=1` records live motion and checks real damage in twelve
mining combinations. Inspect the final package before publishing DEV.

## Native motion revision pilot (schema 2)

`native_motion.py` now owns the shared map heading, state-phase contract and
native transitions. The same approved v28 rig, geometry, materials, native gear,
cameras and 200px render pipeline remain in use. No production atlas is replaced
by these changes. `--native-motion-pilot` writes a separate pilot manifest.

The revised gait is authored at the actual requested game speed (340px/s by
default), with an 88px cycle. This gives about 7.73 footfalls per second. That
cadence must be judged in gameplay; numerical contact checks cannot approve its
appearance. Early swing clearance is spread out, the forward overshoot is
reduced to keep the native legs reachable, and tool load follows the hips with a
small gear-dependent delay. Runtime must use actual distance / stride without
the old 2.8cycles/s cap.

Transitions sample ongoing source and target poses, retain a planted sole using
the measured boot hull, and solve native limbs/grips after the blend. An entry
into running starts at a flat-sole phase with its ankle over the rest ankle. A
stop can end at a small retained visual root offset rather than moving the
support foot across the ground. Drill exits use an unwrapped, forward-only coast
ending at an integer rotor revolution, so they can join the original resting
orientation without snapping back to zero.

The gameplay mining clock is explicit. `--gameplay-mine-cycle .68
--gameplay-hit-phase .42` matches the unupgraded slow-capped The Deep fixture.
Other worlds, gear cooldowns and upgrades need their actual clock. Native impact
remains phase .55; the transition sampler uses the same piecewise phase mapping
as gameplay. Drills retain their independent one-second rotor clock. Never use
the old 1.45-second authoring duration as a replacement gameplay clock.

### Bounded first visual pilot

The following exports 96 Worn frames and 28 Deepcore frames. It is a diagnostic
bank, not a complete motion graph or release package. Set the three paths to the
existing Blender executable, approved v28 file and native-tools directory.

```sh
"$BLENDER_BIN" -b "$APPROVED_V28" -t 2 --python tools/hero_v28/export_hero.py -- \
  --native-tools "$NATIVE_GEAR" --output /absolute/native-motion-pilot --gear worn \
  --native-motion-pilot --direction right,up \
  --native-states idle,walk,mine,idle_to_walk,walk_to_mine,mine_to_walk \
  --native-loop-counts idle=1,walk=16,mine=16 --transition-phases .625 \
  --transition-fps 40 --gameplay-mine-cycle .68 --gameplay-hit-phase .42 --threads 2

"$BLENDER_BIN" -b "$APPROVED_V28" -t 2 --python tools/hero_v28/export_hero.py -- \
  --native-tools "$NATIVE_GEAR" --output /absolute/native-motion-pilot --gear deepcore \
  --native-motion-pilot --direction right --native-states idle,walk,mine_to_walk \
  --native-loop-counts idle=1,walk=16 --transition-phases .625 --transition-fps 40 \
  --gameplay-mine-cycle .68 --gameplay-hit-phase .42 --threads 2
```

`--validate-only` applies every requested pose to the actual Blender rig and
checks bone matrices/grips without rendering. It writes `pose-manifest.json`,
which the packer refuses to treat as image assets. It does not evaluate gameplay
or certify visual fidelity. Use a new output directory when source or settings
change; the fingerprint prevents mixing incompatible native frames.

```sh
python tools/hero_v28/pack_frames.py --frames /absolute/native-motion-pilot \
  --gear worn --manifest pilot-manifest.json --output-dir /absolute/candidate/worn
```

### Runtime contract

- `states[name].phases` contains normalized authored sample phases. Loop durations
  are seconds; transition duration comes from
  `directions[direction].transitions[name].duration`. Choose frames from their
  declared phases, not `round(phase * count)`. A transition includes its endpoint.
- Each transition names its exact source state/phase, target start/destination
  phase, body duration, mechanical mining timing and rotor coast. The pilot bank
  contains only requested source phases. Nearest-bridge guessing is not approved.
- Transition images include their own native in-clip root correction. Add the
  incoming retained screen offset as one constant sprite translation during the
  clip. At its end, retain `incoming + destination_offset_pixels` while playing
  the canonical target at `destination_phase`. Do not add the destination offset
  twice to the transition frames.
- A retained offset can return to zero during a complete airborne run interval
  with zero-velocity endpoints. Never ease it while either foot is planted.
  The contact windows and exact per-frame sole/ankle metadata are retained in
  the manifest. Re-interruption before this release remains a review gap.
- Packing assigns `state.page` and `state.offset`; each direction has a `pages`
  list of beauty/cloth filenames. Pages hold at most 200 native cells and remain
  below 4096px. Load the active direction/state page and release inactive pages;
  do not eagerly load a future full transition bank. Legacy schema packing keeps
  the existing production layout.

### Numerical checks and remaining acceptance

Run `review_native_motion.py` in factory-startup Blender for full target-pose,
IK, endpoint-position, raw-sole-height and monotone-rotor checks. `--quick` checks
the three representative gear types; the dense pass checks all eleven gears.
`review_native_continuity.py` separately compares second-order one-sided
endpoint derivatives and material-point sole velocities. Both require an
absolute `--output` path. These tools never render and report that distinction.

Before production: inspect native films and real gameplay at actual speed,
match the exact mechanical clock, cover all gear/views and arbitrary interrupts,
check evaluated boot bevel support and atlas/frame quantization, and inspect
actual exported mobile captures. The pilot is not a 9/10 assessment and cannot
certify stable iPhone FPS.
