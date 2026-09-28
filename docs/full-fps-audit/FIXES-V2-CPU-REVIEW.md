# V2 CPU evidence review

Reviewed the two `new-production-acceptance` stages in
`/tmp/ever-deeper-fixes-v2-evidence/fps-fixes-v2-{1,2}/report.json` and their
`build.json` receipts, source `21e415af523d497f6ec37706e42694b7f9c5302b`.
Both reports contain 94 passing checks and no report/stage error. The measured
runtime is Mac WebKit/Safari 26.5, Apple GPU, DPR 3, canvas 2328 × 1260.

The owned-pose implementation passes the exactness and ownership gates. Its CPU
benchmark is mixed: worker 1 improves, worker 2 regresses. It may be retained as a
verified allocation cleanup, but these results do not establish a repeatable CPU
speedup. This review makes no total-FPS, GPU, physical-phone or stutter claim.

## Pose, alias and actual-packet results

Each worker passes all 680 sampled-pose comparisons, 11 aimed-phase comparisons,
and 15 fresh-result mutation cases. The endpoint and fractional branches, rotated
and world-space results, and aimed approach/contact/recovery values are exact.
There are no state-difference or failure entries. Banks, metadata and original/
aligned mining snapshots remain unchanged. The public copy APIs preserve their
caller-owned nested dictionaries and arrays after returned copies are mutated.

| Actual recording | Worker 1 | Worker 2 |
|---|---:|---:|
| Exact frames | 364 | 237 |
| Mining / contour frames | 327 / 327 | 209 / 209 |
| Idle frames | 37 | 28 |
| Walking frames | 0 | 0 |
| Transition frames | 8 | 5 |
| Swings / impacts | 11 / 11 | 11 / 11 |
| Retargets / cancels | 2 / 2 | 2 / 2 |
| Clipped frames | 0 | 0 |
| Immutable bank/metadata | Pass | Pass |

Both recordings contain these two distinct nonempty target IDs while the actual
animation packet reports valid mining:

- `endless_d000001_node_001`
- `endless_d000001_node_000`

Thus retarget coverage is supported by distinct resource identities, not only a
counter. These are durable test targets; this does not assert that either resource
was completely destroyed. Each replay compares all dynamic script properties,
including shown/older/transition poses, velocities, selected contacts and their
cache, errors and runtime counters, and compares the rig sink outputs. Both
`advance()` calls must succeed. Immutable data is checked against the starting
seed at completion. Walking poses are covered by the 680-case direct gate; these
two actual recordings do not provide a walking-packet replay.

## Full native advance benchmark

Each sample restores the same recorded initial state outside the timer, then
replays the entire saved packet sequence. A is the untouched reference and B is
the production owned-pose implementation. All 24 sample end states exactly match
the reference replay and all input packets remain unchanged. These are sink-rig
`advance()` timings, including contact planning and transition work. They exclude
GPU work and are not timings of the whole game.

Raw elapsed milliseconds, with all samples retained:

| Worker | ABBA round | A | B | B | A | A total | B total |
|---|---:|---:|---:|---:|---:|---:|---:|
| 1 | 1 | 122 | 89 | 85 | 82 | 204 | 174 |
| 1 | 2 | 78 | 71 | 72 | 78 | 156 | 143 |
| 1 | 3 | 91 | 84 | 96 | 129 | 220 | 180 |
| 2 | 1 | 126 | 113 | 154 | 80 | 206 | 267 |
| 2 | 2 | 102 | 148 | 109 | 182 | 284 | 257 |
| 2 | 3 | 114 | 154 | 115 | 111 | 225 | 269 |

| Derived measure | Worker 1 | Worker 2 |
|---|---:|---:|
| Packets per sample | 364 | 237 |
| Replayed packets per implementation | 2,184 | 1,422 |
| Total A → B | 580 → 497 ms | 715 → 793 ms |
| Mean sample A → B | 96.667 → 82.833 ms | 119.167 → 132.167 ms |
| Amortized A → B per packet | 0.265568 → 0.227564 ms | 0.502813 → 0.557665 ms |
| B minus A per packet | −0.038004 ms | +0.054852 ms |
| Elapsed-time change | −14.31% | +10.91% |

Worker 1 improves in each ABBA round. Worker 2 regresses in rounds 1 and 3 and
improves in round 2. The 182 ms reference sample and both 154 ms candidate samples
are retained. Reported microsecond values advance in 1,000 µs increments, so the
observed timer granularity is 1 ms. Sample variance is considerably larger than
that granularity. The two workers also replay different packet counts and phase
sequences; their totals should not be pooled into a claimed universal gain.

The unchanged contact-search control is exact on both workers, with aggregate
reference/candidate timings of 79/80 ms and 167/148 ms. Its differing timings do
not represent a contact-search optimization: the rejected pitch hoist is absent.

## Companion outputs

All seven original/candidate path cases are exact in both workers, in ABBA order.
The three nonempty paths contain 6, 6 and 9 points. The four remaining cases return
empty paths in both implementations; those negative cases are retained.

Raw path timings in milliseconds, in A/B/B/A order:

| Case | Points | Worker 1 | Worker 2 |
|---|---:|---|---|
| moss_branch | 6 | 1 / 1 / 1 / 2 | 7 / 1 / 2 / 1 |
| moss_quarry | 6 | 1 / 1 / 2 / 1 | 5 / 2 / 2 / 3 |
| moon_bend | 9 | 1 / 1 / 1 / 1 | 1 / 0 / 1 / 1 |
| ember_route | 0 | 0 / 0 / 0 / 0 | 0 / 0 / 0 / 0 |
| ember_resource | 0 | 0 / 0 / 0 / 0 | 0 / 0 / 0 / 0 |
| star_route | 0 | 1 / 1 / 1 / 1 | 1 / 1 / 1 / 1 |
| unreachable | 0 | 0 / 0 / 0 / 0 | 0 / 0 / 0 / 0 |

Path totals are 9/9 ms on worker 1 and 20/10 ms on worker 2. Worker 2's first
reference samples of 7 and 5 ms materially affect that aggregate. With this short,
quantized workload these totals are not evidence of a repeatable game-speed gain.

The same-instance obstruction test passes on both workers: adding then removing
the obstruction changes the exact path lengths 6 → 8 → 6. Ordinary collision
queries remain fresh between searches. Original/candidate collision evaluations
are 160/128, 254/201 and 160/128, totaling 574/457 (117 fewer, 20.38%). This directly
supports the per-search work reduction and finite cache lifetime, while preserving
the earlier finding that stationary surface windows do not call this pathfinder.

## Production identity and disposition

All nine release file identities in each worker's `build.json` exactly match
`/tmp/ever-deeper-fixes-v2-stage1/release/manifest.json`, the root core-test package.
Release `index.pck` is 262,238,744 bytes, SHA-256
`be8aa8fc2ff2adf5726b6e8464415b7b6591f621b2c8e2e5b8ce5f69732b8f69`.
The receipts report 1,421 untouched original resources and verified original MD5s.
The replacement list contains task motion, companion, AudioDirector and version
menu resources/remaps; QA fixtures and references are excluded from release.
Both receipts mark depth prepass unchanged and the pitch hoist/FBO cache excluded.

The source-level allocation argument is valid. With the current three-field pose
shape, each old rotation and world conversion deeply copies the outer, bones and
contacts dictionaries. The candidate consumes the already fresh outer/bones and
copies contacts once: two outer dictionaries, two bone dictionaries and one
contacts dictionary fewer per consumed pose. Endpoint sampling keeps its original
copy. Script-call count is unchanged; the new explicit contacts lookup/detach
replaces two native recursive copy calls. All rotation/translation arithmetic and
iteration order remain the same. No retained pose reaches the consuming helper.

No remaining correctness failure in these results blocks retaining the change as
allocation cleanup. The supported claim is fewer copies with exact tested output,
not faster native motion on both workers. Total-package mining results cannot
attribute a gain to this isolated change. The existing mixed result does not
justify rerunning only to obtain a favorable timing. Any later performance study
would need a distinct question, such as isolating steady-frame pose construction
from unchanged cold contact searches, and would still not establish total FPS by
itself. No further test or runtime edit was performed for this review.
