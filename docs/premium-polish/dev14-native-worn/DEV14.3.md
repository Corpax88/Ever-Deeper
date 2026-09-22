# DEV14.3: upgraded pickaxe motion

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

## Reviewed candidate

The exact exported candidate passed core gameplay, all eight pickaxes in four
directions, actual contact damage, native viewport capture and steering checks,
Apple WebKit startup, and eight15-second sustained Mac render windows.
Independent actual-image and sampled-sequence review scored8.5/10 with no
new tool/body/grip/material/clipping blocker. This is narrow DEV acceptance,
not overall final visual9/10 or continuous-motion/physical-device certification.
Historical40-pose and32-direction local evidence covers an earlier lost scratch
candidate and was not used to approve this export.
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
export passed that regression and fresh rendered gameplay/visual review;
old failed-package captures did not approve the corrected package.

The existing max_reach_error diagnostic includes rejected transition search
probes; final displayed poses still pass the unchanged finite/segment gate.

## Immutable final-candidate review

Game source: `1632526b0cb675e5efd5709b0e55a6ab7ef970d9`.
PCK: 251484324 bytes, SHA256
`69a3b032e324a865b4ba064756ab23e3f71beb3336df7705430436e37e74df5e`.
Export run35704702742 passed the isolated package, 1856 synthetic transition,
1263 gameplay, 125 touch, input-release and DEV-save-flavor checks.
All eight tools × four directions, Endless Iron, actual contact damage and
ordinary control paths passed in Mac Chromium at844×390/DPR3.

That recorded run failed its first sustained Worn window at44.58 browser rAF FPS.
It remains failed. Video, full screenshots and actual400px native PNGs from that
exact package are retained for inspection; earlier failed packages do not approve it.

Validation-only commit`49668d1139dd44118f333c775b4b4c02881e7722`,
run35706535761, reuses the original export and core results by exact artifact
identity and all nine file hashes. It does not rebuild the game. Only the harness,
reuse verification and validation workflow differ from the game source.
It removes video encoding during measurement and reruns the complete rendered
equipment/control suite, all eight15-second >=50rAF-FPS windows and ordinary
Apple WebKit startup. The unchanged threshold must pass before publication.
Source and validation commits remain separate in reports and publisher checks.

Run35706535761 passed build/browser. Mac Metal Chromium151 at844×390/DPR3,
without recording, produced56.27–59.32rAF FPS across all eight15-second windows;
individual stalls reached184ms. This is not a guarantee of stable frame pacing.
The recorded44.58FPS result is retained honestly as a failed diagnostic run;
removing video encoding was the only measurement change, but the separate Mac
runner means it is not a controlled attribution of the whole difference.
Normal WebKit startup, New Game, pause/reload of the save and confirmed
replacement by another New Game passed with no fixture arguments or reported crash.

Publication is prepared for the exact nine reviewed DEV files; deployment and
27 public hash checks must complete before this release is described as published.
See the eventual publication receipt in `.github/dev14/evidence/`.
