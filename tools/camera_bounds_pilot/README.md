# Camera-bound setup study — 17 September 2026

**V1 is rejected for a missing Crusher animation dependency. Nothing is adopted.**
V2 is a separate, unmeasured prototype. Its short graphical cadence gate passes;
no moving performance measurement or production adoption follows from that gate.

The isolated checkout is `/workspace/scratch/d5437d917805/camera-bounds-study`,
detached at `fec3185e7aa78b644bfa1c1ddc2ebd5cd10b5cd3`, tree
`599f28c4b301f676ceb7c39a77fa3b4c05314135`. Tracked files remain unchanged.
This is the DEV10 runtime (scripts tree `7ee867e3fb13066781acc2e98ad29f5907584656`),
without the independently developed later UI changes. Only excluded study tools
were copied into this checkout. No production source, art, shaders or exports changed.

## V1 and its measurements

`candidate.gd` inherits the Deep world. It keeps the original camera eligibility,
then skips requests while exact clamped draw-cell bounds, render configuration,
seed/band and exact floor/damage snapshots remain equal. It does not change
terrain, mining, pet, restoration or rebase mutators.

The corrected, isolated `review.gd` passes 17 original/candidate/restored triplets
with zero RGBA differences. Controls execute real camera setup in every history;
108 requests are skipped in the candidate. Frozen setup + callbacks + guard cost
is 298,446 / 87,114 / 298,387 microseconds. This is not an FPS measurement.
Frozen coverage includes tile boundaries, diagonal/grazing light, all clamped
edges, zoom/viewport changes, direct floor/damage restoration, world modulation,
and camera histories after actual wall hits, pet digging and both rebase directions.

Frozen tests disable camera drag/smoothing and widen limits equally so every
mode follows the same actual camera. Some frames deliberately show outside-world
regions. Moving sessions retain the original camera, animation and physics.

`run_session.py` composes the unchanged `review_premium_session.gd` with the
existing `moving_draw_diagnosis.gd` observer. Both controls use the original world;
only B substitutes V1 before scene-tree entry. All three generated files have
SHA256 `24b70fb5dfc28b194af4c2cf136d30678cc5fccc99e916e4cec9fa198dedbb6e`.

| Moving 60-second report | A | B | A2 (gate incomplete) |
|---|---:|---:|---:|
| Weighted FPS | 36.065 | 38.042 | 36.575 |
| Frame p95, ms | 33.645 | 31.992 | 33.015 |
| Setup + callbacks + guard, ms/frame | 1.931 | 1.197 | 1.916 |
| Mined resources | 4,228 | 4,228 | 4,228 |
| Required completion marker | present | present | **absent** |

The existing route seeds Crusher plus maximum drill. Deep's only dynamic
sections paint `_crusher_impacts`; their age changes every process, but explicit
clock redraw is 30 Hz. Original camera redraws can fill intervening frames.
V1 skips some of those refreshes. A frozen, equal-age pixel comparison does not
prove motion cadence. The callback proxy (all callbacks minus cached redraw
counters) is 698 / 597 / 706; it is not a dedicated per-impact timestamp counter.
Source inspection establishes the dependency independently. V1 must not be adopted.

A2 retained full 60-second JSON, raw samples and final images, but its stdout
and native logfile both stop 12.48 seconds before final JSON. Second-window
markers and the final marker are missing. The wrapper correctly exits 4.
No source print suppression was found; the exact logging failure is unproven.
Do not reinterpret this as a completed passing triplet or accepted FPS gain.

## V2: preserve the queued draw barrier

`candidate_dynamic.gd` preserves every original camera request. At the queued
parent `_draw` barrier, an unchanged terrain/configuration key can reuse terrain
and queue only the existing active dynamic sections. This preserves the point
at which ordinary world draws schedule child callbacks; it does not queue child
draws early from physics before a later same-frame expiry or pool update.

Eligibility requires the same ordered, live Callable-bound impact dictionaries,
active count and visibility. Append, removal, ring eviction, reordered or replaced
bindings fall back to the inherited full draw. Cache count/epoch, emptiness,
visibility and the existing fresh-command invalidation sentinel are checked.
Null/invalid camera and empty-world behavior retain the original fallback.
Private pool/cache access remains confined to this experiment; any production
design should put the reusable operation in the owning draw-section component.

`check_dynamic_bindings.gd` passes 19 headless identity/lifecycle/cache guards.
These checks establish that bound dictionaries retain live age/position changes,
while equal-valued replacement dictionaries cannot reuse stale bindings. They
do not verify Godot's graphical callback order or pixels.

`review_dynamic_cadence.gd` passes actual queued callback, same-frame pixel and
impact-state equality over 14 synthetic age/lifecycle steps in A/B/A2. All 42
native 1696×780 PNGs were saved; both comparisons for each state are exact RGBA,
with the same callback counts and live impact poses. The candidate takes the fast
path five times, including age-only, coalesced scheduled/camera, position mutation
and empty-camera steps. Append/removal before and after the camera queue,
fixed-size eviction, identical-value replacement and fresh-cache invalidation
take the inherited full path. The latter redraws 331 sections in all three modes.
Both required finish/success markers are present; wrapper exit is 0.

Tested V2 SHA256 is
`8aee513c9be01beac08e06f7ed7475f967234f30a662359a99178cc235b4e80f`;
the harness SHA256 is
`69373f33a7706b8b5cfc7ce085e336c34923b6805405cc512d0740efff66b8d8`.
Exact tested sources and tracked source identity are saved with the evidence.
This fixture freezes ordinary processing and explicitly advances real impact
ages, then lets the engine execute queued draws. It proves these tested callback
and pixel cases, not free-running gameplay cadence or a performance gain.

## Evidence and limits

Evidence is under `/workspace/scratch/d5437d917805/evidence/`:

- `camera-bounds-experiment-review.json`: full V1 comparison and source mapping.
- `camera-bounds-isolated-parity/`: accepted frozen V1 gate and 51 PNGs.
- `camera-bounds-moving-A/`, `-B/`, `-A2/`: raw moving attempts, including failed A2.
- `camera-bounds-parity/`: first fixture retained as invalid camera-history coverage.
- `camera-bounds-parity-verified/`: completed corrected shared-checkout attempt,
  excluded because independent UI edits made source identity uncertain.
- `camera-dynamic-guards/`, `camera-dynamic-guards-complete/`: headless guards
  and snapshots of the exact prototype versions they checked.
- `camera-dynamic-cadence/`: passing V2 14-state graphical cadence gate, 42 PNGs,
  callback/pose rows, tested sources and source identity.

All rendering uses Godot 4.7.2 and Mesa llvmpipe at 1696×780. Instrumentation,
JSON/PNG writes and Dummy-audio warnings remain in timing. Process/physics engine
monitors repeat stale values and are not per-frame CPU percentiles. No Apple GPU,
physical-iPhone, 50 FPS or whole-game quality certification follows from this study.
