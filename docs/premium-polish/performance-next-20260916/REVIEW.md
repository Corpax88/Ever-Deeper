# Next performance study — 16 September 2026

Read-only diagnosis of source `c8906f1d46309227344f101a6b0ae7c1a9b1e69b`,
reviewed in canonical documentation checkpoint `9502675`. No runtime edit,
renderer run, publication, or new FPS improvement is claimed here.

**First test the shadow-caster submission topology.** The current rectangular
caster pool creates repeated engine draw submissions that the normal reported
draw count does not include. A bounded contour representation of exactly the
same solid union is the highest-value remaining hypothesis found in this audit.
It is unmeasured and cannot by itself promise sustained 50 FPS.

## What the current evidence establishes

Reports are the three `native-{hub,ember,deep}` directories under
`evidence/dev-ready-c8906f1`, native workflow run `35088488292`, 1696×780,
Godot 4.7.2, Apple Paravirtual / ANGLE Metal. These are virtual Mac source runs,
not physical iPhone or exact exported-package FPS measurements.

| Area | 300-second session: 30-second FPS range | p95 range, ms | Distance in every 30-second window |
| --- | ---: | ---: | ---: |
| Built Hub | 44.98–56.60 | 28.51–38.29 | 1,563–1,684 px |
| Ember D2 | 20.79–39.54 | 39.97–107.07 | 2,930–6,335 px |
| Deep | 18.01–30.91 | 51.36–96.58 | 7,236–7,775 px |

All fail the strict sustained gate. Both mining sessions continue moving in
every window, unlike the older stalled Deep run. The reports record total
mined rewards (Ember 1,064; Deep 26,949), but do not prove excavation in every
individual interval because per-window mining/depletion counters are absent.

| Frozen profile | Deep FPS | Deep p95, ms | Reported render CPU median, ms | Reported draws |
| --- | ---: | ---: | ---: | ---: |
| Original lights/shadows | 31.73 | 48.18 | 28.32 | 201 |
| Shadows disabled | 37.83 | 38.38 | 23.41 | 201 |
| Lights disabled | 44.91 | 36.48 | 18.46 | 166 |
| Original restored | 33.56 | 45.36 | 25.95 | 201 |

This supports investigating shadow and lighting work, not attributing an exact
number of GPU milliseconds to it. All GPU timing is unsupported; Ember contains
invalid timestamp samples, while Hub/Deep report zero. The original/restored
drift is material, especially Ember (43.21 → 33.47 frozen FPS). Lights-off Deep
still misses 50, so there is substantial remaining cost outside shadows.

## Concrete ownership and mechanism

`scripts/lighting/cave_light_occluders.gd:24` owns the caster generation and
refresh. Its existing footprint query includes the emitter-to-receiver path
and a full tile of filtering margin (`:102`). It scans the union of covered row
intervals, excludes emitter cells, then merges only vertically adjacent spans
whose horizontal extents are identical (`:113`). Each remaining rectangle is
one `LightOccluder2D` with a four-point `OccluderPolygon2D` (`:88–99`). Adjacent
rectangles with different extents still retain their shared internal edges.

The exact Godot 4.7.2 implementation explains why this can be expensive:

- [renderer_viewport.cpp:543–581](https://github.com/godotengine/godot/blob/4.7.2-stable/servers/rendering/renderer_viewport.cpp#L543)
  builds one caster list against the combined shadow rectangle and supplies it
  to each shadowed point light. There is no per-light caster AABB filter here.
- [rasterizer_canvas_gles3.cpp:1705–1742](https://github.com/godotengine/godot/blob/4.7.2-stable/drivers/gles3/rasterizer_canvas_gles3.cpp#L1705)
  traverses that list in each of four shadow-map quadrants. Every eligible
  instance incurs two model-view uniform updates, a vertex-array bind and a
  separate `glDrawElements`. The supplied light rectangle is unused there.
- The normal canvas draw counter is incremented in `_render_batch` (`:1318`,
  `:1354`, `:1373`, `:1530`), not in this shadow loop. The profile's unchanged
  201 draws with shadows disabled therefore does not show unchanged submission
  work.

The earlier exact source-owned coverage study records **13–29 Deep casters**
with upgraded hero/pet lighting. If all four helmet cone/bounce lights are
visible, that is potentially **208–464 shadow submissions per frame**, before
the normal canvas calls. This is an engine-derived illustration using historical
caster counts, not a measured count for the new c890 frame; log actual current
counts before using it as a result. Source evidence is
`../iteration-four-20260915/shadow-max-pet-locked-shadow-coverage.json`.

Keep `HeadlampBeam` untouched. The cone and bounce share an emitter but have
different tint, energy and PCF smoothing; merging the lamps is not an equivalent
replacement. Keep terrain drawing, native PNGs, draw order, masks, field texture,
light ranges, PCF settings and shadow-atlas resolution unchanged.

## Smallest decisive study

1. In an isolated opt-in harness, derive boundary loops from the **same final
   solid rectangle union**. Retain separate disconnected loops and hole loops;
   remove only internal edges. Do not connect components across open space or
   diagonal-only contact. Keep the existing terrain queries, coverage margin,
   emitter exclusions, same-frame priority 100, and cache invalidation inputs.
   Before rendering, compare the union and ray-entry distances mathematically,
   record old rectangles/new loops/edge counts, and stop if submission count
   barely decreases. No broad runtime rewrite is justified before this count.
2. First parity rejection gate: unchanged seed-4608 Deep view, a real one-cell
   depletion, diagonal/grazing lamp aim, and maximum wide hero plus distant Long
   Beam pet crossing a tile boundary. Use the existing
   `tools/review_shadow_coverage.gd` states, but compare **current rectangles →
   contour candidate → restored rectangles**, with HUD clocks/tweens and shader
   time actually locked for the captures. Require exact full-frame RGBA and an
   identical restored control; preserve the first failure and skip timings.
3. If that passes, extend exact parity to all five Deep strata and all four D2
   mine profiles, concave walls, enclosed holes, permanent walls, drill-gated
   rocks, partial hit/depletion/pet/Crusher changes, direct restore, stream
   rebasing, zoom/visibility/re-entry, maximum upgrades and same-frame emitter
   motion. A hole boundary is a separate double-sided shadow loop, not filled
   terrain. Keep culling disabled so winding cannot change shadow behavior.
4. Only after parity, run one serialized frozen A/B/A at 20 seconds per stage,
   then moving Deep and Ember A/B/A at 60 seconds per run, same renderer/source,
   input route, seed and upgrades. Record actual elapsed time, frame p95/p99,
   render CPU, supported GPU timing, caster/loop/edge counts, refresh CPU and
   rebuild counts. Record distance **and** mined/depleted cells every ten seconds.
   A changing polygon size reallocates engine buffers, so its moving/rebuild
   cost must be included. No concurrent renderer, capture or archive job.
5. Adopt only after meaningful total frame cost improves against both controls
   and moving p95/rebuild cost does not regress. An unchanged canvas draw count
   or fewer caster nodes alone is not acceptance. Follow a successful local
   result with current Mac/browser and physical-device validation; do not call
   software-renderer improvement an iPhone result.

API caveat: `OccluderPolygon2D` accepts one closed point loop and the shadow path
extrudes its edges. Its separate SDF path triangulates closed polygons
([engine source](https://github.com/godotengine/godot/blob/4.7.2-stable/drivers/gles3/rasterizer_canvas_gles3.cpp#L2091)).
Separate hole loops do **not** preserve a filled SDF union. Current runtime
scripts/shaders/scenes contain no SDF sampling, but the study must document that
limit; do not adopt this representation for a path with an SDF consumer. Bound
contour vertex counts for the engine's 16-bit shadow indices. Exact raster parity
is still mandatory even when the geometric union is identical.

## Measurement limitations and alternatives already ruled out

`tools/profile_premium_render.gd:83` freezes only the selected world, leaving Main,
HUD, autoloads and independent tweens outside that freeze. Stages are eight-second
sequential ablations, not randomized A/B/A timing. Its `render_cpu_median_ms`
combines viewport render time and frame setup, not exclusive game-script CPU.
It never enables `lit_draw_sections.profile_draws`, so zero callback/setup values
are disabled instrumentation, not free terrain work. The 500-call occluder
refresh probe is a warm stationary cache-hit microbenchmark, not moving rebuild
cost (Deep 9.846 µs; Ember 238.442 µs).

The workflow checks functional completion and resolution but does not pass
`--require-fps`; green CI is not a 50-FPS pass. Its profile gate counts six stages
without validating the exact stage set/restoration. The session report stores
requested duration rather than a separately measured actual total; retain the
real monotonic timestamps in the next study.

Already-present improvements include local terrain-strip invalidation, exact
zero-alpha fragment rejection, one-shot fixed-light baking, camera-bounded floor
chunks, and vertical caster merging. Do not repeat receiver/support-mask caches,
downsampled albedo caches, native texture-atlas grouping, or remove shadows.
Root's separate corner-crop preflight has already failed strict pixel parity;
it is not a prerequisite for this shadow-topology study.

`evidence-summary.json` retains the extracted measurements and SHA-256 identities
of the six input reports. No evidence file or runtime source was modified.
