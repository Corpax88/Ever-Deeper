# Captured program 45: original material and specialization

This trace applies to the single identity run 35232918221. It identifies the
original shader family and the newly observed specialization. It does not claim
a recorded CanvasItem, exact first draw, biome, or exclusive GPU/compiler cause.
All game links below bind exact production source `8f5680d…`.

## Directly observed code and history

Program 45 links source/shader IDs 89 and 90 at event 446 and is queried at event
447. No preceding link exists for that program ID. The original pair was absent
from the complete startup capture and does not recur as another exact pair.
The lit attributes prefix begins with `USE_ATTRIBUTES` and `FRAGMENT_CODE_USED`;
there is no leading `DISABLE_LIGHTING` or `USE_PRIMITIVE` define. The source
contains the sole custom fragment operation: discard exactly zero-alpha color.
There is no custom vertex body or material-uniform block.

That custom operation matches the project's unique
[lit_visible_pixels shader](https://github.com/Corpax88/Ever-Deeper/blob/8f5680defb9083bbe1e044d39a10612f2186e7f3/shaders/lit_visible_pixels.gdshader#L5),
referenced by the original
[shared material](https://github.com/Corpax88/Ever-Deeper/blob/8f5680defb9083bbe1e044d39a10612f2186e7f3/shaders/lit_visible_pixels.tres#L3).
This is a source-family attribution, not a WebGL object-to-Godot RID query.

| Program | Source IDs | Leading specialization flags | Observed when |
|---|---|---|---|
| 40 | 79, 80 | `DISABLE_LIGHTING` | Before timing |
| 41 | 81, 82 | `DISABLE_LIGHTING`, `USE_PRIMITIVE` | Before timing |
| 42 | 83, 84 | None of those three flags | Before timing |
| 43 | 85, 86 | `USE_PRIMITIVE` | Before timing |
| 45 | 89, 90 | `USE_ATTRIBUTES` | During timing |

`map_source_family.py` compares both full shader stages, removing only those
three define lines from the prefix before `FRAGMENT_CODE_USED`. Every other
byte is identical for these five programs. Their normalized UTF-8 hashes are
`d48445db9a2f1df9d6c83d7040dced157d5ac96c2e2b43484aabbdec02c1b283`
and `cd51164c1fd94a7210ec11b4974120f51dbac25a5f017e35ab9f8d7447871506`.
This comparison is narrower than deleting all defines or assuming similar
materials share code. None of the 45 unmodified exact pairs is duplicated.

## Original app and engine owners

[LitDrawSections](https://github.com/Corpax88/Ever-Deeper/blob/8f5680defb9083bbe1e044d39a10612f2186e7f3/scripts/lighting/lit_draw_sections.gd#L91)
assigns the shared material to standard lit sections when no explicit or
inherited world material applies. It preserves each section's lighting mask.
The endless world uses these sections for terrain and existing Crusher impacts.
The shader is also assigned to a Deepheart pedestal; no node identity was
recorded, so the mapping does not turn that general reference into a measured
draw claim.

Godot's [canvas renderer](https://github.com/godotengine/godot/blob/4.7.2-stable/drivers/gles3/rasterizer_canvas_gles3.cpp#L1091)
sets `USE_ATTRIBUTES` for `CommandPolygon`; its mesh/particle paths can also
select that flag. The same owner enables `DISABLE_LIGHTING` when neither an
applicable positional light nor a directional light is present
([light selection](https://github.com/godotengine/godot/blob/4.7.2-stable/drivers/gles3/rasterizer_canvas_gles3.cpp#L871)).
Program 45's prefix therefore matches the lit attributes specialization, while
the earlier rectangle/primitive specializations do not cover it.

Original compatible draw owners are concrete:

- [Wall damage](https://github.com/Corpax88/Ever-Deeper/blob/8f5680defb9083bbe1e044d39a10612f2186e7f3/scripts/world/endless_descent_world.gd#L2766)
  draws a positive-width antialiased polyline within a standard terrain section.
- [Crusher debris](https://github.com/Corpax88/Ever-Deeper/blob/8f5680defb9083bbe1e044d39a10612f2186e7f3/scripts/world/crusher_debris.gd#L16)
  draws six circles and four positive-width polylines in an
  [impact section](https://github.com/Corpax88/Ever-Deeper/blob/8f5680defb9083bbe1e044d39a10612f2186e7f3/scripts/world/endless_descent_world.gd#L2609).
  The actual before-save records Crusher with drill level 3.

The primary [polyline owner](https://github.com/godotengine/godot/blob/4.7.2-stable/servers/rendering/renderer_canvas_cull.cpp#L980)
allocates `CommandPolygon`; the
[circle/ellipse owner](https://github.com/godotengine/godot/blob/4.7.2-stable/servers/rendering/renderer_canvas_cull.cpp#L1467)
does likewise. Those are compatible first-use triggers, not separately measured
draw identities. The sampler intentionally did not wrap per-draw or gameplay
calls, so it cannot choose between them.

The [specialization cache](https://github.com/godotengine/godot/blob/4.7.2-stable/drivers/gles3/shader_gles3.h#L183)
looks up version/variant/specialization and synchronously compiles a missing
entry. The [source builder](https://github.com/godotengine/godot/blob/4.7.2-stable/drivers/gles3/shader_gles3.cpp#L159)
adds the specialization defines before common and custom code. The
[compiler/linker owner](https://github.com/godotengine/godot/blob/4.7.2-stable/drivers/gles3/shader_gles3.cpp#L307)
builds the two stages, attaches them, links and then queries status. This agrees
with the captured association sequence and supports a missing-specialization
interpretation. The host waits can include driver work or synchronization;
they do not establish exclusive compiler or GPU duration.

Primary decoded source snapshots, URLs and SHA256s are retained in the evidence
bundle and `postrun-source-bindings.json`. Their fetched content is hash-bound;
the recorded primary Git blob calculations are not independent Git-tree proofs.

## Consequence and limits

The result justifies considering targeted first use of this exact material's
lit attributes specialization before player control. It does not justify shader
replacement, removing alpha discard, turning off lights, polygon/mesh rewrites,
blanket re-caching or a steady-FPS claim. The observed status cost is finite and
rare in this route; shifting it would add startup work. The 240.70 ms callback
with no selected overlap remains a separate unresolved problem. The earlier
resource run's program identities cannot be reconstructed retroactively.
