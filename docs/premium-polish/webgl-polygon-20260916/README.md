# WebGL solid-polygon repair study

The exact `774f889` browser package captures all 19 shop fixtures, but fails
the strict graphics gate starting with the first-to-second fixture transition:
`bindBuffer: element array buffers can not be bound to a different target`,
followed by `bufferSubData: no buffer`. Independent visual inspection finds no
obvious corruption in these stills; that does not clear the graphics failure.

## Mechanism and bounded replacement

Official Godot 4.7.2 creates a mesh index buffer as `GL_ELEMENT_ARRAY_BUFFER`,
then `mesh_surface_update_index_region` binds it as `GL_ARRAY_BUFFER`. Repeated
`Polygon2D` draws with unchanged vertex/index counts call that update. This
matches the observed errors; the controlled browser comparison remains the
required live confirmation. Exact source references:

- [Mesh buffer creation and update](https://github.com/godotengine/godot/blob/4.7.2-stable/drivers/gles3/storage/mesh_storage.cpp).
- [Polygon2D repeated mesh update](https://github.com/godotengine/godot/blob/4.7.2-stable/scene/2d/polygon_2d.cpp).
- [RGBA8 mesh color packing](https://github.com/godotengine/godot/blob/4.7.2-stable/servers/rendering/rendering_server.cpp).

Only three solid, untextured uses change to a common `FlatPolygon2D` CanvasItem
draw command: the player's six-point shadow, the static-lamp bake's black quad,
and the Deep hazard's 36-point fill. Geometry, authored colors, placement,
layer order, lighting and inherited modulation remain intact. The local draw
color deliberately reproduces mesh RGBA8 clamp/truncation before drawing;
otherwise the float-color draw path could alter the original opacity.
OccluderPolygon2D, native artwork, Line2D and parallax's Polygon2D bounds reader
are unchanged. No custom engine build or global WebGL argument rewrite is used.

## Native raster check

`native-parity.json` retains all 15 fresh reference/candidate comparisons at
actual 1696×780 on llvmpipe. Every full decoded RGBA image is exact and the tested
shape changes visible pixels against the empty scene. Coverage includes the
shadow's ordinary/scaled/mirrored/modulated and lit forms, opaque bake quad,
four normal and four empowered hazard opacity states, and a lit hazard. Each
pair explicitly hides and shows both variants and requests another redraw.
Process exit 0 and `FLAT_POLYGON_REVIEW_FINISHED` are both verified. This is a
focused shape/raster test; it is not whole-game or physical-device approval.

## Browser comparison

`premium-web-polygon-review.yml` reuses the immutable failed control package
from run 35073997927 and exports the candidate using the same official engine
and templates. Both run the same first two real shop fixtures at CSS848×390,
DPR2 and actual canvas/GL1696×780. File hashes are checked before launch.
The control's graphics error remains a failing job; there is no waiver.

Optional buffer diagnostics observe object identity and bind arguments without
rewriting calls or consuming GL errors. They are not a performance mode.
The browser driver now preserves a console journal and initial package/renderer
identity as progress occurs, so a cancelled run retains those observations.
Successful completion still requires the existing explicit marker, screenshot,
actual framebuffer and error checks. Browser results are pending at this save.
