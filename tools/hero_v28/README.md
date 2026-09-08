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
`HERO_V28_CAPTURE=1 CAPTURE_END=217 node tools/capture-web.mjs ...` captures all
gear/direction/pose combinations, outfits, worlds, wall corners, permanent walls, gates and transitions in the actual exported game.
`HERO_MOTION=1 CAPTURE_END=1` records live motion and checks real damage in twelve
mining combinations. Inspect the final package before publishing DEV.
