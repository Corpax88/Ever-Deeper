# 1.0 iPhone lighting performance

## Release status

A small hub texture-margin optimization is included **provisionally for DEV device
measurement**. It is not a demonstrated fix for the physical iPhone bottleneck and
is not approval for LIVE or a 9/10 performance score. Runtime source is frozen after
Godot 4.7.2 editor parsing completed without script errors.

## Established physical-device evidence

The last actual iPhone measurement is DEV9: **52.1 FPS** with normal lighting,
**60.0 FPS** with pet lights disabled, and **52.1 FPS** after the final 70-second
restoration stage. Normal-light P95 is 20–21 ms. Each displayed row summarizes its
stage's last eight seconds, not its entire duration. This does not establish thermal
throttling. Do not ask Mats to repeat this same DEV9 test.

Source: `docs/performance-diagnosis/light-cost/iphone-dev9.json` and
`.github/dev-lighting/handoff.md`.

The controlled earlier DEV9 software-renderer isolation ranked pet-cone and non-floor
receiver work as the dominant remaining cost. The new group attribution retained
all other light contributions and excluded only the pet cone from each named group.
Its strongest signal was the relic museum: 17.74 FPS with that cone contribution
excluded versus neighboring restored controls of 14.98 and 15.76 FPS. This is a
render-cost diagnosis, not a suggested gameplay setting or expected phone FPS.

## Included runtime change

`HubWorld._draw_hub_texture_rect()` omits only verified all-transparent margins from
four existing resources: the wall, route marker, treasure chamber and relic pedestal.
It derives the bounds from the actual loaded texture once per hub instance, caches
only rectangles and retains two transparent texels for linear-filter edges. Destination
coordinates and UVs are compensated, including rotated walls and route markers.
Unsupported/mipmapped image data retains the full rectangle. No PNG, shader, light,
shadow, mask, energy, resolution, DPR, hero-v28 resource or gameplay state changes.

There are no extra CanvasItems or offscreen render targets. Existing world drawing,
materials, order and light lifetime remain intact. The cache has at most four texture
keys and is released with the hub. `trimmed_hub_texture_margins = false` retains the
original draw path for paired diagnosis. This switch is not exposed in the game UI.

## Measured result and visual limit

The paired run used Godot 4.7.2, Mesa llvmpipe, a **2328×1260** framebuffer and
`LP_NUM_THREADS=4`. Each reported measurement sampled eight seconds after settling.
These numbers cannot be compared directly with the earlier default-thread studies,
or used to predict physical iPhone performance.

| Fixture | Original FPS | Margin trim FPS | Restored FPS | Gain vs mean controls | Control drift |
|---|---:|---:|---:|---:|---:|
| Standard | 9.767 | 10.299 | 9.219 | 8.5% | 5.8% |
| Wide | 8.516 | 9.036 | 8.754 | 4.6% | 2.8% |
| Focused | 10.705 | 11.265 | 11.003 | 3.8% | 2.7% |
| Prismatic | 13.297 | 13.498 | 12.835 | 3.3% | 3.5% |

The benefit is modest and controls drift. P95 is not uniformly improved. Draw-call
counts are unchanged. The captured light-node count, light textures, masks, enablement,
energy, color, positions, scales and shadow-filter settings remain unchanged.

All four restored controls are pixel-identical. Candidates differ by at most **2/255**
on **812–2,138 pixels**, less than **0.073%** of each frame. Sparse raster rounding
appears on the existing artwork, without visible clipping, seams, loss of detail or
changes to lighting. The lighting agent inspected all four final candidate views;
the root reviewer inspected the full-size standard pair and accepted the negligible
rounding for provisional DEV testing, consistently with the earlier DEV7 visual gate.
This is not a claim of mathematical pixel identity.

The initial conservative exact-pixel check stopped the run after four styles. After
visual review, the small change was reapplied. Complete the missing Deepheart pair
and empty/partial/selected museum states on the **exact exported DEV package** before
DEV publication. The unrelated terminal pulse uses wall-clock time; deterministic
receiver comparisons use its existing repaired visual state. Raw completed-hub
captures were retained; no production clock or pulse behavior was altered.

## Rejected hypothesis

Splitting walls, routes and museum subdraws into smaller CanvasItems produced fifteen
pixel-identical broad/narrow/restored captures across five styles, but timing gains
were inconsistent and some views regressed amid drift. That experiment was completely
reverted. `LitDrawSections` and its original redraw behavior are unchanged.

## Reproduce and finish

`tools/run_rendered_isolated.py` launches authenticated task-local Xvfb and Godot in
the same process namespace, and isolates even Main's initial user-data load. It uses
private IPv4/local-hostname Xauthority records; authentication stays enabled.

`tools/review_hub_light_receivers.gd` is an opt-in external `--script` harness, separate
from QA startup. `--attribute` performs group attribution; the default compares the
original and trimmed draw paths. Pass `--fixture=deepheart` to complete only the
missing pair. For an exported package, use an absolute external script path together
with `--main-pack` so the game's resources come from that exact PCK. The output
folder must be explicitly provided through `--output=...`.

`tools/compare_hub_receiver_images.py OUTPUT_DIRECTORY` records raw image differences
and fails if restored controls differ; actual visual acceptance remains a separate
review. Evidence and full numerical limits are in:

- `performance-evidence/hub-margin-trial.json`
- `performance-evidence/hub-receiver-attribution.json`
- `performance-evidence/rejected-receiver-splitting.json`
- `performance-evidence/rejected-receiver-splitting-images.json`

After exact-package review, a **new DEV candidate** must undergo the actual iPhone
180-second normal/restored lighting test and ordinary mining/travel tests. A brief
cold 60 FPS peak does not satisfy the gate. The 1.0 performance score stays open
until stable/smooth physical-device behavior is demonstrated.
