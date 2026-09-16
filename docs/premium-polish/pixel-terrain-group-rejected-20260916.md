# Screen-pixel terrain CanvasGroup: rejected

The opt-in Deep pilot composited unchanged native terrain artwork at actual
framebuffer resolution, then applied the existing native lights and occluders
once to the composition. It used no texture downsampling, mipmaps, world-space
cache or additional SubViewport. It was never enabled in normal gameplay.

Actual rendered resolution was 1696×780. Seven frozen A/B/A image cases covered
the initial pose, a turned headlamp, Crusher damage, companion opening,
fractional camera movement, a 1536×864 resize, and the restored camera pose.
Every native A/A2 control and every alpha channel was exact. Candidate RGB
differed by at most one byte in six cases. The turned lamp had 14 pixels above
one byte: 13 near-saturated red highlights changed 253→255 and one dark edge
pixel changed by [3, 3, 2]. Exact pixel parity therefore **failed**. Whole-image
mean absolute RGB error remained below 0.077 byte; native texture gradients
were retained. These observations do not establish mathematical equivalence.

Only an explicit diagnostic flag permitted timing: maximum RGB difference
3/255, at most 0.002% of pixels above one byte, mean RGB difference at most
0.1/255, exact alpha, and exact A/A2 controls. This was not release approval.

Eight-second stages on Godot 4.7.2 / Mesa llvmpipe, with no concurrent rendering:

| Fixture | Native A FPS | Group B FPS | Native A2 FPS | GPU median A / B / A2, ms | Draws A / B / A2 |
| --- | ---: | ---: | ---: | --- | --- |
| Frozen scene | 48.28 | 36.77 | 48.46 | 15.61 / 21.11 / 15.76 | 171 / 134 / 171 |
| Moving camera, frozen actors | 48.24 | 39.22 | 47.58 | 15.58 / 19.85 / 15.63 | 167 / 129 / 167 |

GPU cost increased approximately 27–35% despite fewer draw calls. Native
restoration recovered performance. The added full-resolution composition and
coarser light receiver were not an improvement; individual contributions were
not separately measured. Reject this system choice and remove its runtime,
shader, harness and generated UIDs. Do not pursue small variations of it.

This is a local diagnostic, not sustained 50-FPS or physical-iPhone evidence.
The machine-readable report is `pixel-terrain-group-rejected-20260916.json`.
Original PNG pairs and logs were captured under
`/workspace/scratch/5a78be25fc28/evidence/pixel-group-diagnostic-timing/`.
