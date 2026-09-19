# Simple swing 17

The user asked to stop extending the rejected motion stack. This isolated study
authors four poses: ready, raised, impact, and withdrawal. Impact and the approved
character are recovered from study15; its animation curves are not inherited.
The original .68-second cycle and .42 gameplay impact remain unchanged.

First render four actual poses. Check visible pick head, both grips and plausible
arms before rendering one short loop. Use the internal independent critic on the
actual ordered images. If it fails, record the cause and make one revised attempt.
No numerical optimizer, camera sweep or full production bank is part of this step.

The new motion is a preview until actual gameplay and visual checks pass. FPS
work remains paused and LIVE remains untouched. Image-sequence criticism is not
continuous-video viewing or a 9/10 score.

## Files and decisions

- `anchors.json` freezes study15 contact, the neutral body, and the native tool
  working cap. The current motion does not call the previous optimization stack.
- `simple_swing.py` authors ready, raised, impact and withdrawal with fixed feet,
  a shared tool frame for both hands and simple interpolation. The impact cap is
  preserved. Non-impact grip positions are authored independently of the cap.
- `render_preview.py` loads the original private Blender model, checks native
  grip/reach at 121 samples, and renders four poses or 50 actual loop frames.
  Geometry checks do not establish visible clearance or motion quality.
- `package_preview.py` builds a 160px atlas with the renderer's actual camera
  anchor and encodes original frames at their recorded rate. It adds no in-between
  frames. Original captures remain the evidence for individual poses.
- `loop_visual.gd` and `capture_loop.gd` enable the atlas only in an isolated real
  held-mining fixture. They do not edit the production player/world scripts.
- `versions/simple_swing_17a.py` preserves the first completed loop, before the
  broader head, lower ready pose and longer withdrawal were added.

The first completed 17A loop had a readable two-hand grip but a very narrow head
and little preparation. In 17B, keeping the cap fixed at every authored pose
pulled the raised grip behind the helmet. The correction keeps the cap fixed
only at impact; other grips retain their authored positions. A 135-degree view
showed more of the face, but its actual game capture missed the ore even though
damage registered correctly. It was rejected. `versions/simple_swing_17b.py`
preserves that motion. Neither mechanics nor a still-pose pass was sufficient.

17C returns to the 90-degree camera that retained actual visual contact. Its
raised direction is expressed in that camera's up/right axes instead of the
stale 45-degree axes, putting the pick head beside and above the helmet. The
four actual poses show both a recognisable head and a visible shaft/grip. The
impact cap, cycle, damage clock and fixed feet are preserved.

## Reproduce the selected study

Use the restored Blender 4.5.3, Godot 4.7.2 and Xvfb binaries. Native files remain
private; their approved SHA256 values are asserted by the renderer. Paths below
are placeholders for the restored local runtime and private model directory.
Run only one heavy engine at a time and use a new output directory.

```bash
"$BLENDER_BIN" -b "$NATIVE_TOOLS/hero-v28.blend" -t 2 --python-exit-code 1 \
  --python tools/native_motion_ingame_pilot/studies/simple_swing_17/render_preview.py \
  -- --native-tools "$NATIVE_TOOLS" --azimuth 90 --loop --output "$NATIVE_OUTPUT"
python3 tools/native_motion_ingame_pilot/studies/simple_swing_17/package_preview.py \
  --native "$NATIVE_OUTPUT"
python3 tools/run_rendered_isolated.py --godot "$GODOT_BIN" --xvfb "$XVFB_BIN" \
  --project "$PROJECT_DIR" --output "$GAME_OUTPUT" --resolution 1696x780 \
  --timeout 360 --completion-marker SIMPLE_SWING_GAME_COMPLETE \
  -- --fixed-fps 60 \
  --script res://tools/native_motion_ingame_pilot/studies/simple_swing_17/capture_loop.gd \
  -- --output="$GAME_OUTPUT" --frames="$NATIVE_OUTPUT"
python3 tools/native_motion_ingame_pilot/studies/simple_swing_17/package_preview.py \
  --native "$NATIVE_OUTPUT" --game "$GAME_OUTPUT" --video "$PREVIEW_MP4"
```

## Scope

This is the worn pickaxe, base green outfit, up-facing, stationary repeated loop.
It does not cover entry/exit, movement, other headings/equipment, recolouring,
other resource placements, or whole-game camera consistency. Mechanical mining
and ordered-frame review must be reported separately. Production acceptance
remains false until the applicable visual and transition gates are passed.
