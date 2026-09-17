# Camera-bound setup study — 17 September 2026

**V1 is rejected for a missing Crusher animation dependency. Nothing is adopted.**
V2 passes its short graphical cadence gate and saves measured terrain-setup work
in one completed moving A/B/A2 triplet. It demonstrates no throughput gain on
this host. No production adoption is made.

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

`review_visible_impact.gd` checks that the age-only comparison paints an actual
visible effect. With, without, then restored real impact dictionaries change
2,066 pixels within x=661, y=318, width=116, height=117. Maximum channel delta
is 70/255. The restored frame is exact RGBA; actual callbacks are 1/0/1 and
cached terrain redraws 0/0/0. Effect code, strength and materials are unchanged.
The native renderer exits 0 with `CAMERA_VISIBLE_IMPACT_COMPLETE`.

## V2 moving measurement

`run_dynamic_session.py` composes the original route and observer with an option
to load V2 only for B. All variants observe actual dynamic CanvasItem draw signals
without replacing production paint callables, saving the bound live age/position
at each callback. The same generated harness is used for all three variants.
No timing run freezes or substitutes clocks, route, input or animation.

Exactly one serialized 60-second A/B/A2 triplet completed successfully. Every
process exits 0; all three have the final marker and both pairs of window markers.
All source identities are unchanged from the isolated DEV10 checkout above.

| Moving report | A | B V2 | A2 |
|---|---:|---:|---:|
| Frames | 2,173 | 2,167 | 2,147 |
| Weighted FPS | 36.217 | 36.116 | 35.783 |
| Frame p95, ms | 34.319 | 33.656 | 33.950 |
| Setup, ms/frame | 1.855 | 1.057 | 1.859 |
| Draw callbacks, ms/frame | 0.087 | 0.089 | 0.089 |
| Candidate guards, ms/frame | 0 | 0.122 | 0 |
| Setup + callbacks + guard, ms/frame | 1.942 | 1.268 | 1.948 |
| Renderer CPU median, ms | 18.586 | 18.843 | 18.785 |
| Actual dynamic callbacks | 704 | 678 | 698 |
| Mined resources | 4,228 | 4,228 | 4,228 |

B bypasses 788 terrain setups and explicitly requeues 132 dynamic sections in
those fast paths. Measured setup + callback + guard work falls by 0.677 ms/frame,
or 34.79%, against the mean of the two controls. Its weighted FPS is only 0.32%
above their mean, within their spread. **This is setup CPU headroom, not a
demonstrated throughput improvement.** The renderer remains the dominant cost.

All three actual callback counts equal their total-minus-cache proxy, and all
captured paints target visible `_draw_impact_section` sections with live ages.
Each history contains 59 apparent bursts when grouped by age/position resets;
that grouping is inferred. These free-running histories have different frame
times, so their callback totals are not a deterministic cadence comparison.
The earlier explicit-age callback/pixel gate is the equality evidence for its
tested cases. No additional timing triplet was run.

The narrow reusable idea is to bypass unchanged terrain setup at the original
queued parent draw barrier while refreshing existing dynamic sections. A future
production design would need to encapsulate pool/cache access in LitDrawSections
and retain all conservative invalidation guards; the experimental subclass is
not itself an adopted production change. The present evidence does not justify
claiming a gameplay FPS gain or continuing repeated timing trials.

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
- `camera-dynamic-moving-A/`, `-B/`, `-A2/`: the one completed V2 timing triplet,
  raw frames, actual dynamic callback poses, all markers and exact source maps.
- `camera-dynamic-experiment-review.json`: recomputed V2 timing comparison.
- `camera-dynamic-visible-impact/`: real-effect present/absent/restored output,
  visible-pixel bounds, exact restoration and tested sources.

All rendering uses Godot 4.7.2 and Mesa llvmpipe at 1696×780. Instrumentation,
JSON/PNG writes and Dummy-audio warnings remain in timing. Process/physics engine
monitors repeat stale values and are not per-frame CPU percentiles. No Apple GPU,
physical-iPhone, 50 FPS or whole-game quality certification follows from this study.
