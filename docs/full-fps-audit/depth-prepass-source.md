# Native hero: possible unintended WebGL depth prepass

This is a distinct, source-backed hypothesis, not a demonstrated FPS root cause. No runtime or project file has been changed.

## Observed work

The completed native GPU WebKit audit has the same four triangle draws into the 400 × 400, 2× MSAA native framebuffer with shadows on or off. In 61 frames, both modes submit 38,816,862 indices: 212,114 triangles per frame, twice the actual 106,057-triangle body-plus-tool geometry. The framebuffer receives separate depth/stencil and color clears each frame. A further fullscreen triangle resolves/composites this native image. The separate directional shadow framebuffer submits the same geometry once more when enabled.

These are actual GL submissions, not an inference from Godot counters. However, the trace did not record color masks or shader programs, so the two native geometry submissions are not yet directly labelled by pass.

## Exact-source explanation

Godot 4.7.2 `servers/rendering/rendering_server.cpp:3715–3716` enables `rendering/driver/depth_prepass/enable` by default, with `disable_for_vendors="PowerVR,Mali,Adreno,Apple"`.

`drivers/gles3/storage/config.cpp:202–216` checks that list against `glGetString(GL_RENDERER)`. The shipped artifact's `index.js` directly forwards that query to `GLctx.getParameter(7937)`, the masked WebGL renderer string. It does not substitute the unmasked debug renderer. Although `report.json` records the unmasked `Apple GPU`, the retained `console.log:3` already records the engine's own device string: `Using Device: WebKit - WebKit WebGL`. `drivers/gles3/storage/utilities.cpp:450–458` obtains these names directly from `GL_RENDERER` and `GL_VENDOR`. Therefore the Apple exclusion does not match this actual WebKit runtime; this part is observed, not merely hypothetical.

`drivers/gles3/rasterizer_scene_gles3.cpp:2710–2746` performs the enabled depth prepass by clearing depth/stencil, disabling color writes, and rendering the entire opaque list. Lines 3926–3929 deliberately omit depth-prepass draws from normal draw counters. This explains how GL can contain an extra full hero pass absent from those counters. The candidate is consistent with the doubled geometry, separate clears, and unchanged doubled geometry when shadows are off.

A single shadowed directional light does not itself require base-plus-one color passes: the loop at lines 3321–3333 is `MAX(1, positional_shadow_passes + directional_shadow_count)` and can combine the first shadowed light with the base pass. Therefore the earlier extra-additive-pass suggestion is not the strongest explanation here.

Separately, `drivers/gles3/storage/mesh_storage.cpp:1335–1341,1356–1358,1565` proves the 124,069-point native draw against the system framebuffer is skeleton transform feedback under `GL_RASTERIZER_DISCARD`, not fullscreen fragment overdraw.

## Startup-only evaluation

The setting is copied once into `GLES3::Config::use_depth_prepass` by its constructor (`config.cpp:54,202`). `RasterizerGLES3` creates that configuration in its own constructor (`rasterizer_gles3.cpp:238,369`), called by `RenderingServerDefault::_init()` through `RendererCompositor::create()` (`rendering_server_default.cpp:240–250`). `Main::setup2()` initializes the rendering server at `main.cpp:3565–3567`; only afterwards does `Main::start()` instantiate the SceneTree and load autoload scripts (`main.cpp:4013,4362,4500`).

Thus a GDScript `ProjectSettings.set_setting()` before the first 3D scene is still too late. It changes the settings dictionary but not the renderer's cached boolean. `GLOBAL_DEF_RST` explicitly marks the setting restart-required (`core/config/project_settings.h:258,262`). No public RenderingServer depth-prepass setter is exposed in the exact class documentation. A real comparison needs fresh engine startup using the changed `project.binary`/project configuration.

## GL signature to verify

All states below refer specifically to the native 400 × 400 MSAA framebuffer, not the separate shadow framebuffer or transform-feedback POINTS pass.

| Pass | Color writes | Depth write | Depth function | Draw buffers |
| --- | --- | --- | --- | --- |
| Expected baseline depth prepass | false, false, false, false | true | `GL_GEQUAL` (518) | `GL_NONE` (0) |
| Expected baseline opaque color pass | true, true, true, true | false for `DEPTH_DRAW_OPAQUE` | `GL_GEQUAL` (518) | `GL_COLOR_ATTACHMENT0` (36064) |
| Expected candidate opaque color pass | true, true, true, true | true for `DEPTH_DRAW_OPAQUE` | `GL_GEQUAL` (518) | `GL_COLOR_ATTACHMENT0` (36064) |

The prepass setup is at `rasterizer_scene_gles3.cpp:2726–2746`; the color pass restores the color mask and color attachment at 2748 and 2771–2773. Per-material depth-write state at 3313–3317 uses `!Config::use_depth_prepass` for the opaque color pass. Both paths use reverse-Z with a zero depth clear and `GEQUAL`, not an equality-only main pass. The no-prepass path clears depth/stencil at 2778–2782 before color; therefore the number of clear calls alone cannot distinguish the two paths.

Opaque stencil-writing materials force a prepass even with the setting off (2712–2713). The native body shader uses `depth_draw_opaque`, has no stencil directive and does not write custom depth. Do not use an overdraw-debug mode to disable the prepass for an acceptance test, since it changes shader behavior and visuals.

## Minimal candidate and proof gate

If the trace confirms the extra pass uses color writes disabled, a single startup project override under `[rendering]` is the candidate:

```ini
driver/depth_prepass/enable.web=false
```

This keeps atlas size, shadow quality, hero mesh, textures, motion, lights, viewport resolution and MSAA unchanged. It is restart-required: changing ProjectSettings after the renderer starts is not a valid A/B test, and there is no equivalent public runtime setter identified.

The smallest useful test is the existing native fixture in two otherwise identical exports with only this setting differing. Record the masked renderer and actual GL color-mask state; require native triangle submissions to fall from four draws to two while shadow work and pose/update counters remain unchanged. Compare ordinary frame time without GL wrappers, plus fixed-pose and mining visual parity. Removing an extra pass is not by itself proof of faster frames: lost early-Z rejection may offset saved vertex work. A physical-phone FPS claim still needs the phone.

Do not launch another workflow or modify DEV/LIVE without the parent's coordination.
