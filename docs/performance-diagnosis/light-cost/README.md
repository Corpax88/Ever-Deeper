# Lighting cost investigation after the physical DEV5 result

## Physical result

The affected iPhone Air ran DEV 0.46.9-dev.5 in the hub. The user's IMG_1735 report
started at 46.7 FPS, then measured the following final eight-second windows.

| Stage | Engine FPS | Browser RAF | p95 ms |
|---|---:|---:|---:|
| Original after 60 seconds | 19.8 | 19.8 | 51 |
| Pet lights off | 22.9 | 22.9 | 45 |
| Restored | 20.1 | 20.1 | 51 |
| Shadows off | 20.7 | 20.7 | 49 |
| Restored | 20.2 | 20.2 | 50 |
| All lights off | 60.0 | 60.0 | 17 |
| Restored | 19.9 | 19.9 | 51 |

The reversible recovery establishes a lighting-dependent rendering cost on the phone.
It does not establish why performance changes after roughly 30 seconds. Neither thermal
throttling nor a particular browser/GPU mechanism has been measured. Pet lights alone
and shadows alone account for only part of the observed cost.

## Native isolation

Source baseline: `31546a471cfbde1f71e49e6fbd4cf42d563fd909`.
Study: `b24ece942a5367c21791f822aa70cb4f8cc4ec39`,
[run 34250417576](https://github.com/Corpax88/Ever-Deeper/actions/runs/34250417576).
The original lighting stays active for 45 seconds before grouped and individual light
ablations; each intervention is followed by restoration. Tests use isolated seeded saves,
the complete hub and upgraded companion, and Mesa software rendering under Xvfb.

| Area / framebuffer | Original FPS | Root world receives no light | All lights disabled |
|---|---:|---:|---:|
| Hub / 844×390 | 16.15 | 60.00 | 60.00 |
| Hub / 2328×1260 | 2.01 | 13.37 | 14.64 |
| Mossvein Depth 2 / 2328×1260 | 1.71 | 10.41 | 11.86 |

Removing only the root world's light mask retains the light nodes and lighting on child
objects. At full framebuffer size this removes approximately 98% of the measured extra
lighting frame time. The world-sized floor and the other immediate drawing commands
share that root CanvasItem. Individual non-shadowed lamps have similar costs, including
lamps remote from the visible central area. The cone lamps are individually more costly.

These software-renderer FPS values are not estimates of phone FPS. The baseline and
restored samples are stable in CI; the physical delayed fall is not reproduced.
Three result artifacts were saved successfully. The Mossvein 844×390 job completed all
16 stages and restoration, but artifact finalization returned HTTP 403, so the overall
workflow is not described as passing. That job's unretained measurements are not used.

## Candidate and evidence still required

First candidate partitions the two existing floor passes into local CanvasItems while
preserving texture coordinates, colors, overlay alpha and draw ordering. A separate QA-only
intervention crops transparent margins of cone light textures while retaining lit texels,
their world placement and the light/shadow origin. Neither intervention removes a light.
The factorial comparison measures baseline, floor only, cones only, both, and restored.
Paired captures freeze simulation and game time; capture work is outside timed windows.
Production headlamp code has not been changed by the texture experiment.

Before publication: inspect paired images, compare pixels, run gameplay and protected-file
checks, export and review the exact DEV package, and verify published bytes. The physical
iPhone outcome remains unverified until the user tests a published candidate.

## Engine references

Godot's Compatibility renderer selects a light list using each CanvasItem's combined
bounds; its fragment shader then loops over that list. Partitioning a large item can
therefore exclude lights earlier without changing the illumination of its pixels.
This implementation reference is the upstream `master` snapshot consulted during the
investigation, not proof of a specific iPhone driver's behavior:
[canvas renderer](https://github.com/godotengine/godot/blob/master/drivers/gles3/rasterizer_canvas_gles3.cpp),
[canvas shader](https://github.com/godotengine/godot/blob/master/drivers/gles3/shaders/canvas.glsl).
[PointLight2D texture offset and scale](https://docs.godotengine.org/en/stable/classes/class_pointlight2d.html)
describe the separate texture-placement controls used by the bounded cone experiment.

## First paired comparison

[Run 34251578087](https://github.com/Corpax88/Ever-Deeper/actions/runs/34251578087),
source `f3461f8dd109e21e4d7a6b975fe27eb8a177bc07`: all four native jobs passed.

| Area / framebuffer | Baseline | Floor chunks | Tight cones | Both | Restored |
|---|---:|---:|---:|---:|---:|
| Hub / 844×390 | 16.08 | 18.42 | 17.67 | 20.85 | 16.09 |
| Hub / 2328×1260 | 1.96 | 2.36 | 2.18 | 2.70 | 1.96 |
| Mossvein / 844×390 | 16.02 | 16.42 | 23.60 | 25.99 | 16.14 |
| Mossvein / 2328×1260 | 1.69 | 1.77 | 2.53 | 2.83 | 1.69 |

The original 256×256 cone texture contains nonzero alpha inside a 127×103 rectangle
including one transparent border pixel. Cropping leaves the lit texels and shadow origin
unchanged; the texture offset compensates for the removed margins. Paired Mossvein
images differ by at most 1/255 per channel for cones and 2/255 for floor chunks; restored
images are byte-identical in decoded pixels. Hub has a small animated region that also
changes in the restored control; static differences are at sampling precision. Both
areas' native baseline and combined images have been visually inspected.

A second paired test adds an early discard of fully transparent pixels on the root world
material, before its lighting loop. It preserves every nonzero-alpha pixel and the
standard lighting function. This addresses unnecessary lighting of transparent margins
in the authored station and cave-edge textures. Runtime adoption is pending measurements
and paired image review. Shader COLOR already includes the sampled texture by this point:
[CanvasItem fragment COLOR](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/canvas_item_shader.html).

## Transparent discard rejected

[Run 34252458972](https://github.com/Corpax88/Ever-Deeper/actions/runs/34252458972),
source `bcb1a3a4c7381cd4652dc049e53ab7d0951ded6d`, passed all four jobs. Discard alone
was slower than baseline; adding it to floor+cone improvements gave no consistent gain.
It is not adopted. The next test partitions station drawing and cave terrain rows into
bounded CanvasItems, reusing the existing native drawing functions and exact ordering.
Terrain top and edge passes retain their original row/column order to preserve overlaps.

## Selected implementation

[Run 34253613410](https://github.com/Corpax88/Ever-Deeper/actions/runs/34253613410),
source `9b05d90414345f853ceed92e0bb72ab0b44eef66`, passed all four native jobs.

| Area / framebuffer | Baseline | Floor + cone | Floor + sections | All three | Restored |
|---|---:|---:|---:|---:|---:|
| Hub / 844×390 | 16.98 | 21.99 | 21.78 | 24.27 | 16.96 |
| Hub / 2328×1260 | 2.01 | 2.75 | 2.60 | 3.03 | 2.01 |
| Mossvein / 844×390 | 12.46 | 18.79 | 13.44 | 22.73 | 12.56 |
| Mossvein / 2328×1260 | 1.72 | 2.88 | 1.88 | 3.27 | 1.72 |

These are Mesa software-renderer measurements, not estimates of iPhone FPS. At the
reported phone framebuffer size they show approximately 50% and 90% higher FPS.
All baseline/candidate pairs at both sizes were inspected. Mossvein differences are
at most 2/255 per channel; both restored controls are exact. Hub differences above
2/255 remain confined to the small elevator animation, which also changes in controls.

The selected DEV6 code uses all three improvements and no transparent-discard shader.
Headlamp generation now retains only Rect2i(128,77,127,103), with the original scaling
and a compensated texture offset on every style/range refresh. The node stays at the
original helmet shadow-emitter position. Exact Godot 4.7.2 light/viewport source was
checked for offset handling and shadow bounds; the cropped shadow radius still covers
all nontransparent cone texels. Protected headlamp hash and the current gameplay
assertion are intentionally updated for this change; historical assertions are retained.

The final DEV6 workflow exports both flavors, runs the ten current gameplay cases and
both flavor gates, compares paired native renders of the affected worlds and lighting
states, then runs the actual 120-second probe and real touch cancellation in Chromium
at DPR3. Publication is pending those exact-package gates and visual inspection.


## Exact DEV6 package review completed

Package source: cdfd85360fe8707225ded2e0a52ef3870a5f4ec4.
[Final package run 34256408421](https://github.com/Corpax88/Ever-Deeper/actions/runs/34256408421)
passed all ten jobs: build/current gameplay and both flavor checks, seven native groups,
and Chromium hub/Mossvein at DPR3. Candidate artifact: 10068112526.
The two earlier package attempts corrected QA-only assumptions about post-victory
Deepheart entry and Starfall's absence of authored drill gates; no runtime fix was needed.

35 paired native comparisons and all preview/browser images were inspected. Coverage
includes all four Depth 2 profiles, mined/corner/permanent terrain, the hub, all five
headlamp styles, surface, four Depth 1 profiles, Deepheart and Endless layers 1 and 12.
Static differences are normally at most 2/255 per channel; a few isolated pixels reach
3-5/255 at maximum range/styles. Larger hub differences are its elevator animation,
which also changes in baseline controls. No visible quality change was found.

Image inspection showed the initial three gate-location fixtures had fallen back to the
entrance. Therefore [supplemental run 34257483120](https://github.com/Corpax88/Ever-Deeper/actions/runs/34257483120)
uses the identical PCK with an external harness and asserts the gate is actually inside
the viewport, its segments are visible, and mining records one persistent gate strike.
All six intact/struck gate pairs were inspected and passed. The harness and its workflow
are required alongside the package suite; Starfall has no such gates in authored data.

The two browser runs each completed seven original-duration stages (120.80626s hub,
120.824965s Mossvein), restored all graphics and skills, and passed real touch cancellation.
Both retained a 2532×1170 drawing buffer at DPR3. These are software-renderer results,
not a physical iPhone FPS guarantee.

The exact nine-file size/SHA256 manifest and artifact identities are in
[DEV6 review](../../../.github/dev-lighting/review.json). Engine JS/WASM, audio worklets,
art/icons, production settings and save APIs remain unchanged. The protected headlamp
hash is the sole intentional protected-source change. No publication is considered
complete until the publisher verifies all 18 public files and preserves LIVE 0.46.9.
