# Source-only proposal: pre-use one proven shader specialization

**Proposal only. No implementation, build, request, renderer run, warm-up or
production adoption is authorized by this document.** The completed identity
diagnostic remains unchanged. This is a possible next bounded experiment for
review, not an FPS fix already established.

## Falsifiable claim

Program 45 introduced the original `lit_visible_pixels` material's lit
`USE_ATTRIBUTES` specialization during mining. Its two compile-status calls plus
link-status call occupied 349.02 ms inside one callback. Earlier startup programs
had rectangle and primitive specializations of the same shader family, but not
that attributes specialization. No exact pair was recompiled during this run.

Hypothesis: a single real, lit polygon draw using the exact shared ShaderMaterial
before player control can populate the same version/variant/specialization cache,
moving that first-use work into startup. It does not remove the compile cost,
explain the unrelated 240.70 ms callback, or promise sustained 50 FPS. The
specific first gameplay draw could be Crusher dust/cracks or wall damage; its
node identity is still unknown and is not needed to test the captured pair.

## Minimal isolated candidate

Use a separate study worktree with exact DEV11 control and assets. Prefer a
study-only pre-main bootstrap, a tiny helper and one main-scene setting override.
The original gameplay scene and all its owners stay byte-identical. This avoids
adding an awaited render inside the live main scene's current synchronous startup:
`main._ready()` initializes persistence/UI, deactivates worlds and opens the menu;
it does not currently have a verified render-await/input-readiness boundary.
In particular, awaiting after UI installation could expose the DEV control or
advance persistence/menu callbacks before the existing modal is established.

The bootstrap must retain the original Main PackedScene and the exact shared
`LitDrawSections.VISIBLE_PIXELS_MATERIAL` resource through transition. It must
not duplicate the material, recreate shader text, call `set_code`, or create a
different material/Shader RID and merely assume driver code caching is enough.
The candidate will need an identity assertion showing the original material and
shader resources remain the ones assigned by real LitDrawSections after Main
loads. Standard SceneTree scene transition ownership must be used; do not build
a second running Main or change its root-relative paths.

The helper renders once in a separate 16×16 `SubViewport`, with its own `World2D`,
3D disabled and the same 2D HDR/MSAA settings as the main viewport. Its texture is
never displayed by a main-window CanvasItem. A small opaque polygon fully inside
the target uses the original shared material. A real enabled `PointLight2D`
with a non-null, nonzero texture, overlapping bounds, positive energy, matching
item mask and an inclusive Z range must affect that polygon. No shadow or effect
setting in the game changes. The intent is the exact lit attributes variant,
not a culled draw, zero-alpha object, default-material draw or `DISABLE_LIGHTING`
variant. A real light is required even when the offscreen color looks irrelevant.

Set `UPDATE_ONCE` after nodes/resources are ready and await the actual
`RenderingServer.frame_post_draw` boundary. Godot's
[viewport owner](https://github.com/godotengine/godot/blob/4.7.2-stable/servers/rendering/renderer_viewport.cpp#L835)
explicitly renders active `UPDATE_ONCE` targets independently of whether their
texture was used, provided both dimensions exceed one; it then disables that
target. The game already uses an
[UPDATE_ONCE/post-draw pattern](https://github.com/Corpax88/Ever-Deeper/blob/8f5680defb9083bbe1e044d39a10612f2186e7f3/scripts/lighting/static_light_field.gd#L158).
These are source preconditions, not proof that a new candidate actually rendered.

Destroy the offscreen viewport, temporary polygon/light and transient texture
before exposing Main's normal input/menu readiness. Do this once per process,
never per tile, depth, camera move or menu reopen. Do not alter world light masks,
physics/process modes, shaders, main framebuffer contents, saves or gameplay.
No cache clearing, shader recache loop, renderer flag or extra GL query is needed.

## Proof required before any timing comparison

The bootstrap adds startup work and necessarily advances engine frame counters.
Do not describe absolute frame timing as unchanged. The required invariant is
that the gameplay state and accepted input sequence from the first ready frame
are unchanged: no inserted, dropped, replayed or reordered gameplay events.
The additional time before readiness must be reported explicitly.

1. Review the exact small diff and all autoload behavior before implementation
   acceptance. A bootstrap does not prevent autoload processing. Assert there
   are no warm-up calls to RunState, persistence, world generation, player or
   companion methods, input injection or random-number APIs. Record state/save
   bytes and relevant processing/input flags around the warm-up boundary. Any
   state mutation, premature interactive control or unaccounted save activity
   rejects the candidate.
2. In an isolated frozen A/B/A2 fixture, compare exact main-window pixels and
   gameplay/save state for fresh and existing-save startup, continued play,
   initial mining contact and normal menu reopen. Bind camera, animation/effect
   ages and inputs to the same gameplay frame after readiness. Keep the DEV10
   menu physics guarantee. The temporary viewport must leave no input-owning
   control, light, CanvasItem or live per-frame updater behind.
3. Prove the offscreen target actually draws. A diagnostic-only readback after
   post-draw may show a nonzero lit polygon, with a no-light control demonstrating
   real light influence. Keep that readback outside any timed gameplay window.
   A `frame_post_draw` callback alone is not sufficient evidence of target use.
4. Use the reviewed bounded shader-identity recorder in a diagnostic capture.
   The complete original source hashes 89/90 from this run must appear during
   pre-input warm-up, with the exact lit `USE_ATTRIBUTES` prefix. A fresh local
   program ID is expected. No additional program with that exact pair may first
   link during the subsequent matching mining route. Keep one-context, original
   forwarding, capacity, clock, restoration and exit gates. If only another
   specialization appears, stop; do not adjust light/renderer flags in a timed
   trial until source review explains it.

The retained shader source hashes are backend-specific. On another renderer or
engine build, bind its own original control output before comparing; do not
equate a different GLSL text to this target by name alone. This proposal's first
scope is the measured Mac WebKit/export configuration.

## Possible later measurement, only after review and parity

If the gates pass, a separately authorized serialized A/B/A2 on the established
Mac runner would measure the same actual 60-second trusted-input route with
fixed initial game state where practical. Record preparation/export hashes,
startup-to-ready latency, the warm-up span, full callback chronology and shader
associations in all arms; include B's complete startup cost. Keep the same
instrumentation in controls. No speedup claim follows from this single existing
diagnostic or from simply observing the expected cache entry.

Reject if the target pair still first links during gameplay, if main pixels or
accepted input/save semantics differ, if resources survive the one-shot helper,
or if a purported improvement is only control drift. A missing comparable hitch
in controls is inconclusive. Any report must distinguish moving known first-use
work earlier from improving sustained callback cadence, and retain the unrelated
unattributed hitch. No automatic additional run is proposed.
