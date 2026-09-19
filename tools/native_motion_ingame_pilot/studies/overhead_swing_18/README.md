# Overhead swing18 — isolated reference study

Based on the observed overhead mining stroke in Valheim’s official Steam trailer
at21.80–22.90seconds, rather than guide text or unplayed YouTube metadata.
Reference work is saved in Ever-Deeper-Valheim-referanse-og-plan.md.

The approved Gruvepappa v28 is unchanged. The pick head goes behind the body,
then over the helmet, before meeting the preserved working-cap contact point.
The torso arches backward and folds farther forward at impact. Feet stay fixed.
The .68second cycle and .42 impact clock remain unchanged.

The stock helmet reaches about1.93units; shoulders are near1.05 and each arm
has.71units of total reach. Copying hands directly above the crown would be
anatomically impossible at the unchanged proportions. This study therefore
routes the dominant hand beside the helmet, with the tool head overhead. The
support hand deliberately releases during preparation, earlier than the observed
Valheim release, and regrips late in recovery. The source does not establish a
complete loop cadence. Hands retain the approved mesh; no finger rig is added.

Render four actual poses first (.24/.34/.42/.70), then seek independent image
review. If they fail, record the concrete cause and one revised plan before
another render. Only after the pose gate, render50actual frames and exercise
the isolated held-mining Godot fixture. No production sprites are replaced.

`render_preview.py --check-only` checks121actual rig assemblies without frames.
It records hand-contact intent separately from the existing foot-contact field.
A free support hand is checked against its authored hand target, not the shaft.
`--loop` renders50frames and places the .42 impact on cell21.
`package_preview.py` and `capture_loop.gd` reuse study17’s actual capture route.
Use Blender4.5.3 / Godot4.7.2 / Xvfb and the original private native models.
Never run the heavy engines concurrently.

Status:18B has a local preview pass on50native and150actual game frames.
See REVIEW.md for attempts, evidence, verdict and outstanding release gates.
Production acceptance and continuous-video quality remain open.

## Reproduce18B

Use the restored binaries and private native directory recorded in the handoff.
Pass absolute paths for output directories; the renderer requires a new folder.

```bash
"$BLENDER_BIN" -b "$NATIVE_TOOLS/hero-v28.blend" -t 2 --python-exit-code 1 \
  --python tools/native_motion_ingame_pilot/studies/overhead_swing_18/render_preview.py \
  -- --native-tools "$NATIVE_TOOLS" --output "$NATIVE_OUTPUT" --loop
python3 tools/native_motion_ingame_pilot/studies/overhead_swing_18/package_preview.py \
  --native "$NATIVE_OUTPUT"
python3 tools/run_rendered_isolated.py --godot "$GODOT_BIN" --xvfb "$XVFB_BIN" \
  --project "$PROJECT_DIR" --output "$GAME_OUTPUT" --resolution 1696x780 \
  --timeout 360 --completion-marker OVERHEAD_SWING_GAME_COMPLETE \
  -- --fixed-fps 60 --script res://tools/native_motion_ingame_pilot/studies/overhead_swing_18/capture_loop.gd \
  -- --output="$GAME_OUTPUT" --frames="$NATIVE_OUTPUT"
python3 tools/native_motion_ingame_pilot/studies/overhead_swing_18/review_evidence.py \
  --native "$NATIVE_OUTPUT" --game "$GAME_OUTPUT"
python3 tools/native_motion_ingame_pilot/studies/overhead_swing_18/package_preview.py \
  --native "$NATIVE_OUTPUT" --game "$GAME_OUTPUT" --video "$PREVIEW_MP4"
```
