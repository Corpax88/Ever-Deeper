# DEV15.37 — hero-relative world scale

1 October 2026. Mats approved the concept sheet at 09:52 Oslo: larger treasury exhibits and readable world resources relative to the unchanged hero. Implement from canonical DEV15.36 source977bca363d0b8f35286fd881f81d94c8ad874e49, never historical main.

## Implementation

| Family | Previous presentation | Candidate |
|---|---|---|
| 27 treasury alcoves | 100px texture box | 250px visible silhouette |
| 81 treasury upgrade PNGs | 52.8–67.2px single forms; smaller multiple copies | 156–188px single forms, bounded multi-form arrangements |
| Loose cargo, surface + depth1/2 | 80px ordinary /92px rare | 32px ordinary /38px rare, visible silhouette |
| Treasury stream | 27–36px texture box, inconsistent padding | 30–36px visible silhouette, same mixed cadence |
| Standalone surface/depth2/Deep nodes | 92–101px texture box | 136×124px visible envelope, drill-gated +6% |
| Depth1 embedded ore | Stretched inside48px grid cells | Proportional visible fit inside original grid footprint |
| The Deep wall ore hints | 40px texture box | 46px visible envelope inside64px terrain cell |
| Deep loose ore / cache reward | 32px texture box /76px reward | 32px /38px visible silhouette |

Measured152 authored PNG silhouettes offline at alpha>=16. resource_scale.gd caches immutable bounds; no runtime pixel scanning. No texture pixels changed. Existing hero, camera zoom, tools, material identity, grid size, mining speed, rewards, save schema, mixed-stream ledger and resonance drill retained. World mountains/portals already visibly larger than ordinary nodes and are retained. Surface node foot ellipse now48×19 to track the larger visual base without changing strike targets. Grid-bound nodes preserve terrain collision contracts.

Treasury ring and floor boundaries expanded to4000×3200 to hold27 substantial exhibits without overlap. Floor UV scale retained through repeat; wall segment count128 avoids stretched pieces. Labels remain metallic blue beneath each bay. Pedestal collisions enlarged, entry and central plate retained, depth sorting and particle/label z ranges remain under4096.

## Validation status

Local runtime restored: Godot4.7.2 official Linux; Xvfb task-local Ubuntu packages; Mesa software rendering. Native current_scene explicitly set in external capture driver (first world-transition attempt exposed missing fixture scene; production code unchanged). Candidate-v2 input +404 premium-core checks passed,24 treasury captures inspected plus world lifecycle captures. Final candidate-v3 adds larger surface collision base and side-on QA positions. Final native/browser review and DEV publication pending; no physical-iPhone claim.

Workspace /workspace/scratch/1527d6992ff5. Build .github/deep-treasury/build.py against immutable baseline artifact11056132610/run36617600791, downloaded and hash-verified. candidate-v3 is latest. tools/review_world_scale.gd native; .github/world-scale/review.mjs Mac real-touch/visual matrix and .github/workflows/world-scale.yml. Native recovery tools/runtime outside git. Full evidence and immutable publication receipt must be recorded before marking complete. Source branch codex/world-scale-20261001. Standing explicit Ever-Deeper public source upload/QA/DEV publication authorization applies; LIVE separate.

Next: inspect final native views and complete Mac renderer/input/save/node lifecycle review. Then publish exact accepted candidate with existing immutable publisher, preserving18 LIVE/Worn hashes. Never claim the concept is a game screenshot or that native checks certify iPhone performance.
