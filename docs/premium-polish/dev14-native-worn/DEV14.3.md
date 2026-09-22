# DEV14.3 candidate: upgraded pickaxe motion

Mats reported that DEV14.2 fell back to old animation with upgraded equipment.
The ordinary native gate accepted only Worn. DEV14.3 extends the same approved
hero and motion to Iron, Runed, Moonglass, Ember, Crusher, Comet and Crown.
Drills keep their existing presentation. Gameplay, saves and LIVE are unchanged.

## Assets and provenance

The native v9 tool archive is retained as
`libfile_2a51e98cb7a48191af9d21ac69c3c495`.
`tools/hero_v28/original_pickaxes/original-tool-parity.json` records independent
construction from the exact original source functions, compared with all eight
archived .blend tool meshes in their original tool-bone rest frame. Maximum
coordinate difference is 2.4e-7; topology, winding, corner UVs, material graphs,
image pixels and material assignments match. Polygon ordering is canonicalized.

Only original equipment functions are executed. The approved body, skeleton,
lighting and motion are loaded unchanged from the pinned published Worn payload.
For upgrades, build preparation removes exactly 2256 fully tool-bound triangles
from the existing optimized mesh, retaining 84397 triangles and every body
vertex attribute. Original tool surfaces are baked into portable albedo, normal
and metallic/roughness textures, preserving source UVs and procedural coordinates.
CI verifies exact recipe/artwork hashes and mesh layout against the native parity
receipt. Float fingerprints remain diagnostic because Blender can change final
UV rounding bits between opening an archived scene and a fresh process.

This source build uses the already authenticated GitHub connection. It needs no
new user sign-in and routes no binary/base64 through conversation tools. Generated
assets remain in immutable build artifacts. Native source files were not redesigned.

## Validation and remaining release gates

Local parser checks passed for equipment, integration and build preparation.
The exact exported candidate still requires current gameplay, rendered mobile
review, Apple WebKit startup, sustained Mac rendering and independent acceptance.
Historical 40-pose and 32-direction local evidence covers the earlier lost scratch
candidate only; it is not final acceptance of this reproducible rebuild.
Physical iPhone FPS and the old reported startup crash remain unverified.

## Continuity and authorization

Scratch pruning removed the earlier unpushed candidate code and asset files.
Original sources and previous visual evidence were restored; the replacement
source build and integration are reconstructed and must receive fresh final QA.
Mats explicitly approved public upload and publishing after gates ("Alltid").
That permission persists. Do not ask for another login or repeat approval.
DEV14.2 remains published until an exact DEV14.3 candidate passes the release gate.

## Fast-tool transition correction

The first graphical candidate completed Worn, Iron, Runed, Moonglass, Ember,
Crusher and initial Comet damage checks, then rejected a disconnected arm during
Comet cancellation (~0.087-second cycle). A deterministic pose-only reproduction
also failed with the original runtime. The runtime adapter now bounds only an
infeasible transition's incoming velocity extrapolation, reducing extrapolation through bounded search. Authored poses, base task solver, timing,
contact ownership, tool and hand relationships remain unchanged. It neither
clamps individual limb endpoints nor relaxes rejection tolerances.

The correction passed 1856 synthetic contact/cancel geometry cases. The final
export runs that regression too; fresh rendered gameplay/visual review is still
required and old failed-run captures cannot approve the corrected package.

The existing max_reach_error diagnostic includes rejected transition search
probes; final displayed poses still pass the unchanged finite/segment gate.
