# Source trace and bounded optimization hypothesis

The actual measurement establishes two slow **LINK_STATUS host queries**. It
does not measure exclusive compiler or GPU work. This follow-up is source review
only: no second session, altered package or runtime implementation exists.

## Original engine call path

The exact Godot 4.7.2 GLES3 source has the observed six-call order in
`ShaderGLES3::_compile_specialization`:

| Operation | Original source |
|---|---|
| Create a new program object | [shader_gles3.cpp:307–308](https://github.com/godotengine/godot/blob/4.7.2-stable/drivers/gles3/shader_gles3.cpp#L307) |
| Compile vertex shader and read COMPILE_STATUS | [323–325](https://github.com/godotengine/godot/blob/4.7.2-stable/drivers/gles3/shader_gles3.cpp#L323) |
| Compile fragment shader and read COMPILE_STATUS | [371–373](https://github.com/godotengine/godot/blob/4.7.2-stable/drivers/gles3/shader_gles3.cpp#L371) |
| Link program and read LINK_STATUS | [427–429](https://github.com/godotengine/godot/blob/4.7.2-stable/drivers/gles3/shader_gles3.cpp#L427) |
| Accept the valid specialization | [465–469](https://github.com/godotengine/godot/blob/4.7.2-stable/drivers/gles3/shader_gles3.cpp#L465) |

The first actual trace has that sequence at records 50–55; the second at 127–132.
The status query starts only 0.04 ms after each recorded link returns. This is
consistent with that engine path. It does not prove which material/variant invoked
it or which lower-level work occupied the status call. The other LINK_STATUS read
in `_load_from_cache` is under a non-web branch; the [WEB_ENABLED branch returns
false](https://github.com/godotengine/godot/blob/4.7.2-stable/drivers/gles3/shader_gles3.cpp#L547).
The engine's binary cache save is also disabled for web. That says nothing about
an internal browser/driver cache, which this probe did not inspect.

For canvas draws, [`RasterizerCanvasGLES3::_render_items`](https://github.com/godotengine/godot/blob/4.7.2-stable/drivers/gles3/rasterizer_canvas_gles3.cpp#L705)
selects the material shader version and batch specialization, then calls
`version_bind_shader` at line 721. The [inline bind owner](https://github.com/godotengine/godot/blob/4.7.2-stable/drivers/gles3/shader_gles3.h#L183)
looks up the `(version, variant, specialization)` entry. A missing entry is
synchronously compiled and inserted; an existing valid entry is reused with
`glUseProgram`. The asynchronous-default branch is an inactive `if (false)` TODO.
New versions initialize defaults in [`_initialize_version`](https://github.com/godotengine/godot/blob/4.7.2-stable/drivers/gles3/shader_gles3.cpp#L703).
[`version_set_code`](https://github.com/godotengine/godot/blob/4.7.2-stable/drivers/gles3/shader_gles3.cpp#L721)
clears the old version, so preserving the original resource/version matters.

This makes first use of a missing specialization a plausible source of these
two sequences. It is an inference from matching source and event order, not a
sampled call stack or proof of a specific game owner.

## Reuse: known code versus unrecorded identity

No program/shader/texture handles, bound texture IDs or GLSL text were retained.
The records therefore cannot distinguish two different shader variants from
recreation of equivalent code, nor 169 new texture images from repeat uploads of
the same images. A claim of repeated identical resources would be fabricated.
The aggregate 9.60 ms of 2D image calls is too small to explain the two large
callbacks as observed upload-call wall time; queued work or uncovered calls
remain separate possibilities.

Actual DEV11 application owners already share shader resources:

- [`_deep_floor_material`](https://github.com/Corpax88/Ever-Deeper/blob/8f5680defb9083bbe1e044d39a10612f2186e7f3/scripts/world/endless_descent_world.gd#L2668)
  caches materials by stratum index and assigns the same preloaded
  `lit_biome_floor.gdshader`; band/colour changes update parameters.
- [`_add_site_pad`](https://github.com/Corpax88/Ever-Deeper/blob/8f5680defb9083bbe1e044d39a10612f2186e7f3/scripts/world/endless_descent_world.gd#L1101)
  creates distinct materials sharing the preloaded relic-seal shader.
- [`LitDrawSections::_configure`](https://github.com/Corpax88/Ever-Deeper/blob/8f5680defb9083bbe1e044d39a10612f2186e7f3/scripts/lighting/lit_draw_sections.gd#L91)
  reuses the preloaded visible-pixels material for standard lit artwork and
  preserves explicit world materials.

Their existence is not a mapping to either long query. Caching materials again,
changing floor blending or reorganizing draw primitives is not justified by this
capture. The shader specialization key also depends on primitive/lighting features;
loading a resource alone does not prove that every later draw specialization exists.

## Smallest plausible same-pixel intervention

**Conditional candidate: initialize only the proven missing canvas specializations
before interactive Deep play, retaining the same Shader resources and render
states.** This moves a first-use wait to initialization; it does not make the
shader simpler or eliminate total work. It is distinct from changing meshes,
batch order, textures, lights or blending.

Before implementing that candidate, the two slow programs must be mapped to
their actual shader source/variant and existing game draw owners. The current
capture lacks those identities, so there is no justified exact warm-up fixture
yet. Source code and event order are not enough to pick a material arbitrarily.
There is also no evidence that a generic preload call would populate the required
specialization; a representative real draw is what reaches the bind path.

The current [`_enter_endless` owner](https://github.com/Corpax88/Ever-Deeper/blob/8f5680defb9083bbe1e044d39a10612f2186e7f3/scripts/main.gd#L2807)
loads the depth and immediately activates its world; it does not contain an
asynchronous shader warm-up phase. Adding such a boundary would change arrival
latency and input readiness and requires explicit design review.
The measured [DEV target path](https://github.com/Corpax88/Ever-Deeper/blob/8f5680defb9083bbe1e044d39a10612f2186e7f3/scripts/main.gd#L576)
also loads its selected depth and activates consecutively. A future initialization
experiment must cover that real route as well as ordinary entry.

If the missing pair and a suitable initialization boundary are identified, a
bounded experiment could render only those unchanged materials with their exact
primitive/lighting specialization in the same WebGL context before interaction.
Retain the Shader resources, remove temporary draw nodes before gameplay, and
change no world, RNG, mining, save, light, material or animation state. Reject if it creates different programs,
changes pixels/state, moves an unexplained stall into play or lacks an actual
warm-cache reuse proof. Record any extra loading latency explicitly.

The acceptance plan would require exact frozen A/B/A2 pixels and state at entry,
first mining, damage and relevant lighting boundaries, then a reviewed actual
Mac triplet that includes loading cost and sustained play. Both controls and raw
long intervals must be retained. A disappearing host wait is the falsifiable
prediction; the third unattributed hitch and ordinary >20 ms intervals remain
separate unresolved costs. **No such run or implementation is authorized here.**
Do not remove status checks, change renderer/driver flags or weaken shader
semantics to bypass the wait.
