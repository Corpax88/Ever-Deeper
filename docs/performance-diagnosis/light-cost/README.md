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
