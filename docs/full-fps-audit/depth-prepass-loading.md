# Startup-only depth-prepass QA switch

The existing web launch can read a PCK-root `override.cfg` before constructing the GLES3 renderer. A QA-only package addition is sufficient; editing `project.binary` is unnecessary.

Proposed resource content (not added to any game package by this audit):

```ini
config_version=5

[rendering]
driver/depth_prepass/enable=false
```

## Exact Godot 4.7.2-stable loading path

All sources below were read from the official `godotengine/godot` repository at tag `4.7.2-stable`.

1. `platform/web/js/engine/engine.js:196–206`: `startGame()` prepends `--main-pack` and the configured main pack, defaulting to `${executable}.pck`. The existing exported game configuration uses executable `index`, no custom main pack, so this is the relative name `index.pck`.
2. `main/main.cpp:1864–1870`: web accepts `--main-pack` and stores that relative argument unchanged.
3. `core/config/project_settings.cpp:689–704`: mounts the pack, reads `res://project.binary` (binary has precedence over project.godot), then reads `p_main_pack.get_base_dir().path_join("override.cfg")`, i.e. `override.cfg` for this launch.
4. Important detail: that relative filename still finds the PCK resource. `core/io/file_access.cpp:160–170` tries `PackedData::try_open_path` before filesystem access. `core/io/file_access_pack.h:123–129,245–251` simplifies the path and strips an optional `res://` prefix. Both `override.cfg` and `res://override.cfg` therefore address the same root PCK entry.
5. `project_settings.cpp:980–988`: INI section and key are combined and written with `set(section + "/" + assign, value)`, replacing the loaded/default setting.
6. `main/main.cpp:2107` loads these project settings during `Main::setup`; line 2936 subsequently calls `setup2`; lines 3565–3567 create and initialize the RenderingServer.
7. `drivers/gles3/rasterizer_gles3.cpp:368–369` constructs `GLES3::Config` after OpenGL initialization. `drivers/gles3/storage/config.cpp:202–217` reads `rendering/driver/depth_prepass/enable` once into `use_depth_prepass`, then optionally disables it for matching vendor strings. A GDScript `ProjectSettings.set_setting` call after startup does **not** update this cached renderer field.

## Gates / caveats

- Override loading is conditional on `OVERRIDE_ENABLED` and `application/config/disable_project_settings_override=false`. `SConstruct:271,1098–1099` enables it by default. The inherited actual engine WASM contains the `override.cfg` path; no disable setting is present in the inspected inherited project.binary. Still assert runtime setting and actual draw behavior in the candidate; do not treat a file addition alone as proof.
- Check for an existing `override.cfg` before adding; preserve it if present. None exists in the inspected inherited package. Check for a custom `application/config/project_settings_override`, which is loaded later by `ProjectSettings::setup:870–882`; none appears in the inspected inherited project.binary.
- This exact root-override reasoning relies on the existing relative `index.pck` main-pack name. It is not a claim about arbitrary absolute filesystem main-pack paths.
- Inspect `ProjectSettings.get_setting_with_override("rendering/driver/depth_prepass/enable")`; require false in the off build.
- Prove the render mechanism in the GL inventory: native 400×400 geometry draws should fall from four to two per frame while the two 4096×4096 shadow draws and their 106,057 triangles remain unchanged. Global primitive counters are not a substitute for the per-FBO inventory.
- Require identical frozen rendered PNGs plus unchanged native gear, animation/pose evolution, all Light2D state, DPR, native viewport size/MSAA, shadow settings, and resource hashes. FPS/GPU gain still needs actual evidence; depth prepass removal is a candidate, not automatically lossless or a proven phone fix.

No game source, build package, workflow, DEV publication, or LIVE file was changed by this inspection.
