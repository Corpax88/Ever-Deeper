# Bounded native hero animation trials

These tools use Mats's approved v28 Blender hero and original Worn equipment.
They are opt-in studies in the actual DEV13 game, based on runtime commit
`5ca6f0f77a1f87eaead777613062208159325068`. The later main documentation commit
`4024e551` has a different runtime tree and is not an interchangeable base.
No production hero assets or gameplay/save owners are replaced by these trials.

## Banks

`assets/worn` contains 92 cells: the frozen target-bound mining motion, native
walking, one idle pose and three exact-source transitions. Its original
`pilot-manifest.json` SHA256 is
`98aef75d77e95a03d5cd13b2493f8c7f37dc83681ea2df8182de20871b6bcc91`.
`export_return_bank.py` requires that trial's recovered pivot and loop evidence;
the private Blender inputs must not be committed to the public repository.

`assets/worn-rest` contains 170 cells. `extend_return_idle_bank.py` reuses all
92 original color/mask image bytes and renders 78 additional cells: the original
idle timeline, exact new endpoints, and five stop/start clips. It uses the same
200px render and 160px packing. A separate three-pose 400px/32-sample comparison
improved edges without resolving hand/tool occlusion; it was not adopted.

Pack into the explicit study directory with `tools/hero_v28/pack_frames.py`.
The packer preserves the 160px ground anchor, state phase tables and per-frame
native metadata. Neither study bank is a complete motion graph.

## Runtime and captures

`pilot_visual.gd` is installed only by `capture.gd`. The normal controller,
collision and mining systems still own movement, targets, damage and time.
The fixed fixture is Worn/up, seed4608, entry depth1, target depth2,
`endless_d000002_node_006`. The hero approaches from `[1696,1784]`, mines from
`[1696,1648]` toward the real resource at `[1760,1568]`, then walks136px onward.

Use `tools/run_rendered_isolated.py` with the real Godot binary, authenticated
Xvfb and a fresh output directory. The script arguments are:

```text
--fixed-fps 60 --script res://tools/native_motion_ingame_pilot/capture.gd --
--output=<absolute-fresh-directory> --source-sha=<exact-local-commit>
--mode=candidate --direction=up --depth=1 [--rest-cycle]
```

The first route records idle → walk → two mining hits → walk. `--rest-cycle`
selects the separate rest bank and records the following six transitions:

| Presented source | Requested target |
| --- | --- |
| Early idle cell `.033333` or `.055556` | Walk |
| Walk `.625` | Mine |
| Mine `.625`, after two hits | Idle for one complete3.6s period |
| Actually displayed idle0 | Mine for one new hit |
| Mine `.625` | Walk136px |
| Walk `.625`, after airborne offset release | Idle |

The fixture chooses input times from actually presented supported source cells.
It does not establish arbitrary input coverage. Missing clips and interruptions
still stop the study with an explicit failure instead of guessing a bridge.
The second early-idle bridge exists but one route cannot exercise both choices.

`--cancel-cycle` selects `assets/worn-cancel`: all170 rest-bank cells plus24
cells for mine `.392857` → idle and idle `.033333` → mine. It releases MINE
before the first hit, resumes on the first actually displayed idle endpoint,
allows exactly one real hit, then returns to idle. This route has five bridges
and one136px approach, with no walking exit. It does not interrupt an active
bridge. It is mutually exclusive with `--rest-cycle`.

`probe_windup_cancel.py` first measured this exact stop against the retained
V3 draw44 ore transform and rendered four original poses. The continuation of
the source mine timeline does reach contact during the120ms blend; the blended
cap samples remained outside the frozen ore alpha. That result is limited to
the captured transform and sampled cap, so actual cancellation frames still
need contact inspection alongside HP/impact checks. `extend_return_idle_bank.py
--pre-hit-cancel-proof <closed-report>` binds that diagnostic before adding only
the two clips; it preserves all170 original color and cloth bytes.

The startup toast queue must settle naturally. It took72.6 simulated seconds
in the closed V3/V4 trials. A rest trial reached only71.85s before its180s host
watchdog expired, before arming or capturing. Its failure is preserved. The
host watchdog was extended to300s; the110s simulation budget, actual busy-state
predicate and0.5s quiet requirement remain unchanged. No queue is force-cleared.

The next rest trial recorded359 frames, a complete idle cycle and three actual
hits. It stopped two frames into the final walk-to-idle clip: the old resource
sprite came within7.945 logical pixels of the context button, below the8px
framing requirement. This remains a failed, incomplete trial. The optional
`--continue-framing-diagnostics` flag records the remainder after such a failure
so it can be inspected. It retains every failed check, the failed final result
and exit1. Draw, input, unsupported-state and mechanical checks still stop on
their own errors. A failed diagnostic capture cannot become a baseline replay
source. This flag does not change the camera, world, animation or pass criteria.

## Timing and placement contracts

- The actual mining cycle is0.68s, gameplay impact at progress.42 and native
  contact at phase.55. An actual impact serial forces the contact cell on the
  same captured draw as HP loss. Before impact, all native phases at/after.55
  are excluded. Excluding only the exact.55 cell was tried and rejected because
  another cell in the held-contact interval could be selected early.
- Walking phase follows actual distance/88px. Mining follows the game clock.
  Idle and idle-bound transitions advance on actual process delta, including
  the exact target phase at their canonical handoff.
- Transition images contain their own root correction. The incoming displayed
  offset remains constant through the clip; the destination offset is retained
  once at handoff. A later bridge inherits the last actually drawn offset.
- Release a retained offset only across a complete airborne walking interval.
  Finish before nearest-cell selection can show a planted foot. In the closed
  route this is unwrapped phase.681818187–.96875, with offset0 from draw108.
  A final walk-to-idle stop can create a fresh authored support correction and
  retain it while stationary; zero is not the correct final-idle requirement.
- Native mine↔idle transition metadata historically marks intermediate
  contacts false even when the measured soles remain stationary on the floor.
  Those flags are preserved; they are not evidence that the feet are airborne.

Inspect the actual final JSON, original PNGs and logs. Headless imports and
endpoint/grip checks do not approve appearance. Encoded60fps and fixed60Hz
simulation are not measured game FPS. Full direction/tool/target/cooldown and
rapid-interruption coverage, hand/tool readability, final mobile package review
and DEV release approval remain open. Keep rejected runs and independent reviews.
### Restart while a stop bridge is still active

`--bridge-restart-cycle` is a separate diagnostic route using `worn-bridge-restart`.
It resumes ordinary mining input immediately after the actually presented
`mine_to_idle-392857` cell at 50 ms, before canonical idle. Only that exact
bridge source is authored; other unsupported sources still fail explicitly.
The native source continues its old stop, then its advancing idle, while the
target follows the new mechanical mining clock. The last shown offset is
inherited once. Five starts must produce four canonical handoffs and one
explicit interruption; the cancelled windup must cause no damage.

`probe_bridge_restart.py` actually completed on `6fc9b2f`, with four native
originals and 73 geometry samples. `extend_return_idle_bank.py` then completed
on `0298578`: 194 existing cells retained byte for byte, 12 new cells, two pages;
the original beauty/cloth page is unchanged. Endpoint matrix errors are below
4.5e-7 and measured sole drift is 1.5e-8. Finite-difference velocity observations
do not establish numerical convergence or visual smoothness.

The frozen ore projection remains a recorded failure: alpha overlap starts at
83.333 ms and reaches all 270 sampled cap points at 98.333–120 ms. At 120 ms the
source weight is zero and the pose is unchanged canonical mine .231092. This
does not isolate an interruption defect or prove physical contact. The bank
preserves `projected_clear_at_sampled_points=false` and `contact_approved=false`.
No contact, unrestricted input, FPS, production, or release approval follows
from this diagnostic route.
