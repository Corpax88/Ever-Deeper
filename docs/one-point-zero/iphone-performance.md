# 1.0 iPhone lighting performance

## Release status

A small hub texture-margin optimization is included **provisionally for DEV device
measurement**. It is not a demonstrated fix for the physical iPhone bottleneck and
is not approval for LIVE or a 9/10 performance score. The final exported candidate
has completed all five paired lighting-style captures at the target mobile viewport;
physical iPhone acceptance remains open.

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

The final paired run used the exact DEV PCK from source
`f19c0ea61402c860fab60eae3560579aeed6ff21`, build run `34334701244`, with SHA-256
`7757ec55406704ce613ced7c34e51581e2f1e06eb1cae893ab7486c03d5e5260`.
The PCK hash was verified before and after rendering. Godot 4.7.2, Mesa llvmpipe,
`LP_NUM_THREADS=4` and `OMP_NUM_THREADS=4` produced all fifteen PNGs at
**2532×1170**, the 844×390 mobile target at DPR 3. Each measurement sampled eight
seconds after one second of settling; simulation time stayed frozen for each pair.
These are native software-renderer measurements, not browser or phone FPS.

| Fixture | Original FPS | Margin trim FPS | Restored FPS | Gain vs mean controls | Control drift |
|---|---:|---:|---:|---:|---:|
| Standard | 9.998 | 10.348 | 10.037 | 3.30% | 0.39% |
| Wide | 8.551 | 8.724 | 8.202 | 4.15% | 4.17% |
| Focused | 11.183 | 11.909 | 11.612 | 4.49% | 3.77% |
| Prismatic | 12.870 | 13.828 | 12.973 | 7.01% | 0.79% |
| Deepheart | 11.611 | 12.202 | 12.054 | 3.13% | 3.74% |

Gain compares the trimmed FPS with the mean of the original and restored controls.
Drift is the absolute difference between those controls divided by their mean.
The apparent gain is modest; Wide and Deepheart gains are no larger than their
control drift. P95 is not better than both controls in every fixture:

| Fixture | Original P95 ms | Margin trim P95 ms | Restored P95 ms |
|---|---:|---:|---:|
| Standard | 118.015 | 116.861 | 119.875 |
| Wide | 140.331 | 134.289 | 140.855 |
| Focused | 109.711 | 99.655 | 98.925 |
| Prismatic | 93.548 | 91.077 | 90.155 |
| Deepheart | 104.365 | 97.940 | 98.304 |

Draw-call counts are unchanged within every triplet (125, 152, 142, 136 and 124
respectively), with 17 visible sections. The harness confirmed that light-node count,
textures, masks, enablement, energy, color, positions, scales and shadow-filter
settings remained unchanged.

All five restored PNGs are **byte-identical** to their originals. Trimmed candidates
are not pixel-identical; their maximum per-channel difference is **2/255**:

| Fixture | Maximum channel difference | Changed pixels | Frame changed |
|---|---:|---:|---:|
| Standard | 2/255 | 2,077 | 0.07011% |
| Wide | 2/255 | 882 | 0.02977% |
| Focused | 2/255 | 1,078 | 0.03639% |
| Prismatic | 2/255 | 1,106 | 0.03733% |
| Deepheart | 2/255 | 3,272 | 0.11045% |

The UI reviewer inspected the original and trimmed full-frame images for all five
styles; the restored controls contain the same bytes as the inspected originals.
No introduced clipping, seams, lost material detail or changed lighting appearance
was visible in these comparisons. The sparse differences are consistent with raster
rounding. Independent final review and whole-game acceptance remain separate.

These exact-package results supersede the earlier four-style source trial for this
artifact gate. That trial and the intermediate `b061c4d` Deepheart pair used
2328×1260; their FPS numbers must not be compared directly with this mobile-target
run. All five styles here light the Hub; “Deepheart” names the headlamp style, not
the separate Deepheart world. Empty, partial and selected museum states belong to
the final native journey matrix. The unrelated terminal pulse uses wall-clock time;
the paired fixture uses its existing repaired visual state without changing any
production clock or pulse behavior.

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
original and trimmed draw paths across all five styles. Omit `--fixture` for the full
matrix; `--fixture=deepheart` selects only that diagnostic style. For an exported
package, use an empty isolated project directory, an absolute external script path
and `--main-pack` so the game's resources come from that exact PCK. The output
folder must be explicitly provided through `--output=...`. The final receipt below
records the full invocation, package/engine/harness hashes and all fifteen PNG hashes.

`tools/compare_hub_receiver_images.py OUTPUT_DIRECTORY` records raw image differences
and fails if restored controls differ; actual visual acceptance remains a separate
review. Final exact-package evidence and full numerical limits are in:

- `performance-evidence/hub-margin-final-f19c0ea-receipt.json`
- `performance-evidence/hub-margin-final-f19c0ea-comparison.json`

Earlier experiments remain available for history:

- `performance-evidence/hub-margin-trial.json`
- `performance-evidence/hub-receiver-attribution.json`
- `performance-evidence/rejected-receiver-splitting.json`
- `performance-evidence/rejected-receiver-splitting-images.json`

After exact-package review, a **new DEV candidate** must undergo the actual iPhone
180-second normal/restored lighting test and ordinary mining/travel tests. A brief
cold 60 FPS peak does not satisfy the gate. The 1.0 performance score stays open
until stable/smooth physical-device behavior is demonstrated.
