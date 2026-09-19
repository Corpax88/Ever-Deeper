# Study21 — exact entry and interrupted walking poses

Mats accepted study20's visible held-mining flow, then said to proceed.
Preserve that bank and its .68s/.42 gameplay timing. FPS remains paused.
The current experiment extends transitions; it is not a new swing design.

Baseline source: f9ff3d7e4f1d85ddc04b931700ceacbc04c39fd8.
Two actual baseline captures reproduce the remaining discontinuities:

- `interrupt`: the existing down-walk bridge shows cell6 at game frame89;
  stopping at90 immediately selects unrelated legacy walking/idle images.
- `walk-entry`: actual up-walking shows legacy cell15 at frame7;
  held mining at8 immediately selects approved FlowSwing cell1.

`capture.gd` replays real input in the unchanged seeded world. `render_edges.py`
adapts the exact pose families (FlowSwing20, bridge19, legacy motion_v9) into
one render camera and preserves each family's full-bone source/end matrices.
It does not feed the approved poses through the older generic motion sampler.
The runtime selects only the exact recorded source tuples. Uncovered or
interrupted new edges remain explicit gaps, not arbitrary input coverage.

## Bounded revision and pre-render gate

Analytical attempts are kept in the evidence archive. No rejected attempt
was rendered or adopted. Reach and endpoint equality alone proved insufficient:

| Attempt | Finding and resulting change |
| --- | --- |
| A | Both feet slid about9px and an unused arm endpoint hit an antipode. Use alternating planted steps. |
| B | Geometry passed but the forearm jumped70.36degrees in2.22ms. Interpolate a complete elbow plane. |
| C | Legacy rest-axis bone construction introduced a second discontinuity, also in knees. Use solved chain frames and endpoint local roll. |
| D | Nine brake frames still forced45.27degrees in one arm frame. Allow14frames for the near-half-turn and two steps. |
| E | A moving entry destination crossed shortest-quaternion branches. Bind one fixed future sink: approved cell10. |
| F | A straight carry-to-raised wrist path still folded rapidly. Use a torso-relative spherical wrist path with interpolated reach and the approved free support hand. |

The exact legacy adapter now applies the original pose first, then transforms
its complete bone matrices and original lights into the common render camera.
Transforming only IK targets was not equivalent to the actual legacy exporter.
Idle completion is native sample0/cell0, as required by the consumer's declared
times; the0.15s idle clock does not mean a0.15s native pose.

The brake takes14/60s; entry takes8/60s and reaches approved cell10 at the
unchanged mining clock. Neither changes the authoritative impact or damage.
Right foot is planted first, then left. Every candidate checks61 native
substeps, full-bone endpoints, grip, plant and adjacent-bone rotations at both
substep and actual60Hz cadence. These are numerical gates, not visual approval.
Actual native endpoints and same-input gameplay remain required afterward.

CheckG completes both paths: largest60Hz bone changes are29.17degrees for
the brake and39.78degrees for entry, with no half-turn substep flips. Entry
arm reach remains0.3818–0.5501m. The next bounded render is24 actual native
frames (15brake,9entry), followed by actual-game endpoint/sequence review.

## Reproduction

Use the restored Blender4.5.3/Godot4.7.2/Xvfb paths from the test handoff.
Existing banks are `/tmp/ever-deeper20-flow-loop` and `...20-flow-walk`.
Native originals are `/tmp/ever-deeper-retarget-20260918/native`.

1. Run `capture.gd` with `--scenario=interrupt` and `--scenario=walk-entry`,
   ordinary `--frames` and `--walk-frames`, fixed60Hz through the isolated
   graphical runner; require `TRANSITION21_COMPLETE` and exit0.
2. Run Blender `render_edges.py --native-tools ... --baseline-root
   /tmp/ever-deeper21-baseline --output NEW_DIRECTORY`; add `--render` only
   after the analytical gate and independent review.
3. Run `package.py NATIVE --flow LOOP --walk WALK`. Capture the same cases
   with `--candidate21 --bank=NATIVE`, then `review_capture.py GAME --baseline
   BASELINE`. Inspect the resulting original crops and seam sheets.

Production atlases, gameplay, camera, gear and saves are not changed by this
isolated diagnostic. Full phase/direction/tool/outfit coverage is still open.
