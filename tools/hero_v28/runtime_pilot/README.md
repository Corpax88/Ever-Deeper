# Worn native rig feasibility pilot

This is an isolated architecture candidate. It is not production artwork or an
approved replacement. It derives every visible surface from the approved v28
Blender scene and the original Worn equipment. No face proxy is built.

The inventory found 629 visible mesh objects, 634 material partitions, 32 unique
materials and 3,130,548 evaluated triangles. The face itself has 1,156,484 base
triangles. The 602,400-triangle facial groom is also already base geometry.
Disabling subdivision therefore cannot make a mobile runtime asset by itself.

`export_runtime.py` provides separately reviewable preparation and bake stages.
Preparation records source identity, derives a bounded LOD from the actual
meshes, retains the original 17-bone rig and writes exact native pose samples.
The high-detail source remains inside the prepared Blender file for material
transfer. The bake transfers original base color (including facial attributes),
roughness, metalness, normal detail, local occlusion and the original cloth mask
into a shared 1024 atlas. It does not bake a screenshot onto a new character.
All original materials and high-detail source geometry remain intact.

The nominal geometry budget is 120,000 triangles, with explicit per-part floors
and protected small eye surfaces. The actual result is reported, never assumed.
Each component retains its source name, source count and resulting count.

Before running the expensive stage, checkpoint the source. Example:

```sh
blender --background /absolute/approved-v28.blend --threads 2 \
  --python tools/hero_v28/runtime_pilot/export_runtime.py -- \
  --native-tools /absolute/native/v9/hero-blender/v9 \
  --output /absolute/worn-runtime-candidate --prepare-only

blender --background /absolute/worn-runtime-candidate/prepared.blend --threads 2 \
  --python tools/hero_v28/runtime_pilot/export_runtime.py -- \
  --output /absolute/worn-runtime-candidate --bake-only
```

The initial memory estimate is 17.3 MiB for three RGBA8 1024 textures and one R8
cloth mask including mipmaps; actual import formats must be measured. Geometry
at 120k triangles is a few MiB, depending on splits and imported skin attributes.
A 200px color/depth target is approximately 0.31 MiB before buffering and MSAA.
These are storage estimates, not FPS evidence. The merged actor should have one
material surface and one viewport-compositing draw; lighting passes, skinning,
viewport updates and the real hub workload must be measured.

Acceptance requires five original native PNG pose comparisons at 200px, a real
hub/controller clip with arbitrary and repeatedly interrupted transitions, and
an A/B rendering-cost measurement. The pilot must retain the approved face,
silhouette, material response, both grips and planted contacts. A successful
glTF export, reduced polygon count or headless test cannot approve it.
