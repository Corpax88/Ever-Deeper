Current:19C passes the bounded stationary/rapid-restart/walk image review. See [REVIEW.md](REVIEW.md) for limits.

# Study19 — 18B transition verification

Baseline: saved18B at7ad27afb9d1ebff6c93c7bbcd427bb40a6a04aed.
Keep the approved v28 hero, .68s clock/.42 hit, original gameplay and FPS pause.

1. Reuse the existing50frames. Capture actual idle→mine, pre-hit cancellation,
   restart, post-hit release and mine→walk with the current18B consumer.
2. Identify the largest visible discontinuity and its source. Record the cause
   before one bounded native correction; no camera sweep or loop rebuild.
3. Replay identical inputs and have the existing independent critic review
   exact original images/times. Compare damage, movement and target state.
4. Check remaining direction/tool coverage and save source/evidence. A frame
   review is not continuous-video viewing or a numerical9/10 approval.

Production sprites and runtime remain unchanged during this isolated study.

## Diagnosis and selected correction

Baseline180frames reproduces all inputs: two impacts/eight damage, no hit from
the interrupted first swing. At11→12 and25→26, the backpack changes visible
sides and the tool changes orientation immediately. The internal critic
confirmed both discontinuities. Legacy idle and18B have different native
heading/camera conventions. A0.10s turn between them would preserve the problem.

Use18B's existing frame0 as the Worn/up ready stance. Before-impact release
reverses only the actually shown preparation frames; after-impact release
continues through actual withdrawal to ready. Restart while returning blends
the phase back to the live gameplay clock before its authoritative impact.
No native rendering or changed gameplay clock is needed for this correction.

Walking is a separate experiment. A single exact presented source cell31
(progress.62) is connected to the real down-walk pose with native walking legs
over.20s. This narrow pilot must reject other starting cells/phases rather than
claim arbitrary-input coverage. It does not authorize publication.

## Reproduce

The restored binaries/private model paths are in `docs/TESTMILJO-HANDOFF.md`.
Start from18B's saved50frames/atlas. No loop regeneration is needed.

```sh
"$BLENDER_BIN" -b "$NATIVE_TOOLS/hero-v28.blend" -t 2 --python-exit-code 1 \
  --python tools/native_motion_ingame_pilot/studies/transition_19/render_walk_bridge.py \
  -- --native-tools "$NATIVE_TOOLS" --output "$WALK_NATIVE"
python3 tools/native_motion_ingame_pilot/studies/transition_19/package_preview.py \
  --walk-native "$WALK_NATIVE"
python3 tools/run_rendered_isolated.py --godot "$GODOT_BIN" --xvfb "$XVFB_BIN" \
  --project "$PROJECT_DIR" --output "$GAME_OUTPUT" --resolution 1696x780 \
  --timeout 360 --completion-marker TRANSITION_STUDY_COMPLETE \
  -- --fixed-fps 60 --script res://tools/native_motion_ingame_pilot/studies/transition_19/capture.gd \
  -- --output="$GAME_OUTPUT" --frames="$LOOP18B" --walk-frames="$WALK_NATIVE" --candidate --rapid
python3 tools/native_motion_ingame_pilot/studies/transition_19/review_capture.py "$GAME_OUTPUT"
python3 tools/native_motion_ingame_pilot/studies/transition_19/package_preview.py \
  --walk-native "$WALK_NATIVE" --game "$GAME_OUTPUT" --video "$PREVIEW_MP4" --gif "$PREVIEW_GIF"
```

Omit `--rapid` for the original180-frame scenario. Omit `--candidate` and
`--walk-frames` for18B's baseline. `capture_scope.gd` uses the same setup and
`--output`/`--frames`; require marker `TRANSITION_SCOPE_COMPLETE`.
The final run used a temporary output directory outside the active workspace,
then copied completed evidence into it. Never claim missing completion logs
as a pass, even when frame/report generation finished.
