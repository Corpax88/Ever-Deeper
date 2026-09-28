# Native motion fresh-pose candidate

The production transform is `.github/fps-fixes-v2/motion_patch.py`. It starts from
the untouched DEV15.16 task source, SHA-256
`4946e722a77231c5a47f34bf4af85536ccabbb2e3c0e4f3283b54db154e25f9a`, and keeps the
approved stance runtime byte-identical, SHA-256
`2f5594057629eb9e15ad5385155da7cecd0aab3a418eb8648a0116eca311f720`. The resulting
task source is `270ed2bd8326ac0307be2fb2ec05903679264ef358b64fea3153ad06c7c4cd99`.
The build must verify the original task remap and compiled source hashes supplied
by the module before substituting this source.

This candidate removes two complete recursive pose copies from the normal native
display path. Every displayed idle, walking or mining frame passes through that
path; an earned impact can produce another pose through it. The transform changes
three call sites and adds two private helpers. It does not change transforms,
arithmetic order, clocks, interpolation, constraints, contact search, transition
snapshots, rendering, assets or rig application. The rejected contact-pitch hoist
and inverse-rest change are absent. Depth prepass remains parked.

## Ownership argument

`sample()` delegates to the approved `mix()` override with its default negative
`step`. That override immediately returns the base result when `step < 0`.
In the base implementation both endpoint branches use `duplicate(true)`. The
interior branch creates a new outer dictionary and new `bones` dictionary, filling
it with `Transform3D` values. Those are value types. It borrows `b.contacts`, so the
fresh pose is **not initially deeply independent**.

`_rotate_fresh_sample()` accepts a family and phase, never a caller's dictionary.
It calls `sample()`, deep-copies only `contacts`, then performs the exact rotation
loop previously performed by `rotate_pose()`. The returned pose is fully owned.
`aimed()` uses this helper, retaining its existing bone snapshot for arm solving.
`_world_owned()` translates only a fresh result of one of those two methods, in the
same iteration and arithmetic order as `_world()`. No retained pose is passed to it.

| Value | Ownership after change |
|---|---|
| Sample bank, metadata, original/aligned mining poses | Never mutated by the new helpers |
| Fresh sample's outer/bones dictionaries | Produced uniquely by the approved `mix()` |
| Fresh sample's contacts | Deep-copied before the result escapes |
| Result of `aimed()` | Independent of bank and earlier results, as before |
| `shown`, `older`, `transition_source` | Existing assignments and snapshot copies retained |
| Public `sample()`, `rotate_pose()` and `_world()` | Their existing behavior and copy contracts retained |

There is no persistent pose cache, pooled dictionary, runtime toggle, profiler or
new mutable field in production. The ownership assumption is specific to the
hash-verified approved runtime; a future `mix()` or `sample()` override must be
reviewed before reusing these private paths.

## QA integration

`qa_reference_scripts(original_task, active_runtime)` supplies an untouched task
reference and an approved runtime whose only change is its inheritance path.
`motion_fixture.gd` compares that reference with the actual production class.

- `run(main)` checks all 170 authored poses at four fractions (680 cases), including
  low/high endpoint branches and fractional interpolation, with varied rotations,
  nonzero translations and roots. Eleven aimed phases include approach, exact
  impact, withdrawal and loop boundaries. All dictionaries must match exactly.
- Fifteen mutation cases modify one fresh result's bones, contacts and release,
  then check another result, banks and retained display/transition snapshots.
  Public copy methods also receive arbitrary nested dictionary/array data and
  must preserve their caller's values after mutation of returned copies.
- `record_start(main)` seeds both implementations from the same actual motion
  state. `record_frame(main, delta)` supplies real animation packets and the same
  ore contours to both. It compares every dynamic script property, including
  shown/older/transition poses, velocities, contact selections/cache, errors and
  runtime counters, plus rig sink outputs. Both advances must succeed. Immutable
  banks/metadata are compared against their seed when `record_finish()` runs.
- `benchmark_recorded(repeats=1)` is optional and must run after `record_finish()`
  while the original rig still exists. It replays all saved packets in ABBA order,
  restoring the identical initial state outside each timer. The final complete
  state must match the exact reference replay after each sample, and input packets
  must remain unchanged. It measures full native `advance()` CPU with a sink rig;
  it is not a total game FPS or GPU measurement. Timer resolution and each raw
  sample must be retained. Recording/benchmarking are excluded from whole-game
  performance windows and the release package.

The local transform hash and exact three-site diff have been checked. Godot/Mac
execution, actual packet parity, visual parity and performance evidence are still
required before accepting the candidate. No performance gain is claimed from the
source change alone.
