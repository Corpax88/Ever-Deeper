# Independent Worn trial review — 20 September 2026

Status: **trial remains blocked pending a fresh export and browser review**.
Run i failed; the subsequent bounded numerical repair is supported below.
Only the additive `dev/worn` trial is in scope. This is not ordinary-game adoption,
LIVE approval, physical-device performance evidence, or a numerical motion-quality rating.

Source checked at branch head `63f4d096711ff75f1dd2654ea84d417addcc8cfe`;
runtime source `aa4362aaeff03be9013a1da3f090634f7f0b35fc`.
The existing candidate PCK was independently hashed:
`1bce497a6858ecda944152bfa9ba9d98fbd135429a5aa12266ee1ff2666f91dc`
(327093776 bytes). Neither the earlier g2 suite nor the new failed run i is passing evidence.

## Findings, in priority order

1. **Run i freezes during held mining.** `failure.json` records frame 52, impact
   serial 6, ore 17 HP 476 and `failed:true`, with
   `Rejected disconnected armR segment 0 error 0.0001066327095`.
   The actual `failure.png` was inspected: the stop message is visible and the
   last displayed hero remains intact. This is a trial usability blocker, not
   evidence that disconnected geometry was displayed. Only `01-ready` completed.
2. **The numerical repair is supported by a before/after reproduction.**
   `_solve_chain()` constructs an elbow as `origin + axis*along + radial*height`.
   It obtains `radial` through quaternion transport without restoring unit length
   and perpendicularity to `axis`; those invariants are required for the upper
   segment to equal its authored length. Gram–Schmidt projection and normalization
   can restore them without moving tool/hand endpoints or loosening `.0001`.
   The implementer added that single projection/normalization line and reproduced
   the numerical defect class on fractional poses before the repair. The same
   35,007-pose domain afterward has no recorded length failures. This does not
   establish antiparallel transport as the particular cause of run i. No approved
   asset, tool/hand endpoint, support-hand release or rejection threshold was changed.
3. **No publisher source blocker found for this bounded trial.** The reviewed
   publisher requires exact bundle/baseline/report identities, all nine served
   file hashes, the six interaction checkpoints, and an independent visual
   acceptance flag. It verifies the 18 baseline files before staging, reconstructs
   and hashes the candidate, retains rollback bytes, and verifies all 27 public
   files afterward. Passing final review metadata and evidence are absent, so
   this finding is not publication approval.

## Targeted regression reviewed

`verify_chain_lengths.gd` checks 5,001 fractional phases for idle, walk, mining and
four aimed mining directions (35,007 poses total), as well as all 50 authored
mining matrices. Both retained logs identify Godot 4.7.2 and contain a completed
`CHAIN_LENGTH_CHECK` record without script errors.

| Result | Before | After |
| --- | --- | --- |
| Maximum segment-length error | 0.000128567218780518 | 0.000000178813934326172 |
| Exact authored-matrix error | 0 | 0 |
| Passed | false | true |

The pre-fix report retains its first 20 failures, all on `armL`; run i's recorded
failure was `armR`. The reproduction therefore establishes the numerical defect
class, not an exact replay of run i. The `.0001` criterion remains unchanged.
The test should additionally reject non-finite transforms/errors explicitly:
`NaN > .0001` does not reliably record a failure. That test hardening is pending
at this review; the runtime's existing finite-transform rejection remains intact.

Reviewed repair source SHA256:
`8c3e464e2f2959ca6b313c6d688df46cd7f8e40e3c09385286971aae9a4aef86`.
Before-report SHA256:
`b788775814b4ac2bcebf557e2433eda98838cfafbc4c172678c86d3896b13c18`.
After-report SHA256:
`4ef4ca0422d3fc9f0bfebd5737dfe90678c95984ecfd43d02043216b6cc76468`.

The current `verify_task_motion.gd` calls `aimed()` at 101 phases without checking
its segment lengths; only its single 1/60-second sequence uses the final guard.
It also writes `complete:true` and exits zero independently of `sequence_valid`
and the unreachable-contact result. The new focused test exits 1 for recorded
length/reference failures. A mathematical pass alone does not approve appearance.
The new export must complete all six real controls and visual review.

The revised browser harness now contains fresh-frame stationary-position checks
after keyboard and touch movement release. Its touch origin is inside the
existing joystick region (`x <= .46*width`, `y >= .36*height`). Neither correction
completed in run i, so they remain source-reviewed, not verified interaction.

Run i evidence identities (SHA256):

- `failure.json`: `0810bd9419018179ea9e19204053f5161095b6b99493026696643f6613f1794d`
- `failure.png`: `36e9c2f4fad6f0a2bc0fc591840e0e6a8db502348613d441783c2e2da4371b01`
- `01-ready.png`: `50a370fcf85a3deabdd76efe4bc3fcaadde9ff62e5638f1a2baf9a84d3cdc47a`

Both CDP PNGs are actually 844×390 pixels. Context DPR2 is a requested setting;
these captures must not be described as 1688×780. Runtime reports Godot 4.7.2,
WebGL2 and single-threaded Emscripten. Evidence location is
`/tmp/ever-deeper-worn-review-i/` pending durable retention by the implementer.

The screenshot and the following telemetry read are checkpoint-associated, not
guaranteed to represent the same rendered frame. The current publisher shares
the `pages-ever-deeper` concurrency group with current release workflows; keep
the unrelated historical manual `pages.yml` workflow idle during publication.

Approved v28/study20 and its intentional support-hand release remain protected.
General directions, tools, repeated interruptions, normal-speed motion quality,
physical iPhone testing and the paused FPS work are outside this trial review.
No engine or continuous-video playback was run by this critic.
