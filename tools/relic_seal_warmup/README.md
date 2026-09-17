# Relic-seal shader: isolated mechanism study

Base runtime: 9d52cb37a0a7162f0950a93610fa5ce5a4489171.
No Main hook, existing helper, world, shader, production texture or workflow is changed.
The new helper is dormant unless the explicit diagnostic loads it. This is not a build
or publication request.

## Why this next question

Actual Mac WebKit run 35266337303, attempt 1, preserved the completed original target:
its exact lit-attributes source pair linked before ordinary menu navigation, with no
later matching compile/link through the recorded endpoint. A different program, 45,
was linked at event 446 and queried at event 447 during real held mining. Its
getProgramParameter host span was 271.52 ms inside a 333.68 ms callback; the next
callback interval was 390.28 ms. This is inclusive host wall time, not exclusive
compiler/GPU time. Sources 89/90 semantically match lit_relic_seal.gdshader:

- vertex UTF-8 SHA256 c1056810b36616462e0c36f3bbb7350fb1beadabf74d85d2c755ccf901355a94
- fragment UTF-8 SHA256 36fcf3d0b83644ceef4cfe809ae7e954f2082839b6e458e378c9d569d9cea699
- UTF-16-source-hash pair fingerprint e7069294d2d83ce2192b182328148e3ac135e0b9186affb1151092b2978f6868

The unchanged world _add_site_pad uses the matching shader. That is source-based
compatibility, not recorded first-draw/node attribution. The separate 200.32 ms
callback with zero selected-resource overlap remains unexplained. Do not retarget
or rerun the completed original request.

## One narrow helper

Use the same preloaded Shader and original emberdeep-seal-mark texture as the
original factory, through a Sprite2D rectangle and a distinct temporary
ShaderMaterial. Preserve sprite aspect ratio inside a 16x16 isolated World2D.
Use the original factory's resonance color and strength, default pulse, one actual
PointLight2D, UPDATE_ONCE, ordinary post-draw queue_free and signal cleanup.
Nothing is drawn into the game viewport. No new art or shader code is generated.
The one-attempt static guard and headless skip are not proof of warming or a
guarantee to precede every input event.

## Concrete native diagnostic, not yet run

probe_helper.gd uses the exact original 9d52 PCK:
221023248 bytes, SHA256
6b0f5583b4fecfea416e8bf1d67d4a477be41b8eb3aef38a4dd60e1c006ee2a0.
Main is the unchanged compiled original and runs its existing lit-triangle helper.
The new seal helper is installed from Main.ready, after original synchronous _ready,
so no candidate Main hook is exercised.

Before loading the new helper, call the actual original compiled
EndlessDescentWorld._add_site_pad into a detached test parent. This is explicitly
test-induced factory evidence. Capture its shader/texture IDs and WeakRefs, compare
with the helper, require distinct material IDs, then free the factory pad, parent
and material synchronously before any awaited draw. They cannot serve as resource
keepers during cleanup. The normal original world/script stays alive. After ordinary
queue flushing, require the helper nodes, light texture and own material gone,
and the same shared shader and original texture still alive. This does not identify
which script/resource cache retains those shared resources or establish GPU reuse.

Run exactly two fresh native controls, lit then no_light. In the second disable only
the helper light after ready, before first draw. Compare all native target pixels:
same alpha/exterior, nonempty original texture, and actual unsaturated color response
to the light. Inspect the two root-image pairs without treating early images as
ordinary no-helper startup parity. Readbacks are untimed and may stall rendering.

Use the unchanged authenticated tools/run_rendered_isolated.py, one renderer at a
time, a new empty project and isolated output/userdata per control, --main-pack
<exact PCK>, --fixed-fps 60, --script <absolute probe>, then --output=<absolute>,
--helper=<absolute new helper>, --variant=lit or no_light. Preserve the existing
3424134400-byte image-start and 1.5GB reserve requirements. Require real engine exit0,
the exact SEAL_HELPER_DIAGNOSTIC_COMPLETE marker once, no runtime errors, all actual
checks, closed delayed hashes and independent original-image review.

## Later gates remain open

Before any Main integration/export or additional WebKit request, review actual
mechanism evidence independently. A later exact compiled-hook observation must
avoid test-owned resource keepers; normal fresh/saved startup, input/release/save
and all existing regressions remain necessary. Revalidate the exact full GLSL pair
and all export bytes in WebKit; native pixels do not establish the shader variant.
Only a separately designed controlled timing comparison can assess gameplay benefit
and moved startup cost. No displayed 50 FPS, physical-iPhone, full-premium or
publication acceptance follows from this preparation.
