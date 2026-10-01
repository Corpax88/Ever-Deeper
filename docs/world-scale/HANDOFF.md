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

## Validation and continuation

Canonical gameplay source d7c42c367513ede867afefa34c795959fe1d536b on codex/world-scale-20261001. Local tree1ac23c3b846c84fdfeb2c1db000b926fb77d3f5b; Mac QA36835005359 tests the final candidate. Main is only a publication carrier.

Native Godot4.7.2/Xvfb/Mesa: input +404 premium-core checks passed.29 treasury layout checks,24 sector/stage captures,27 final world/lifecycle captures and8 actual held-mining before/after captures inspected. Held input depletes surface,depth1,depth2 andDeep nodes. No physical-iPhone/FPS claim; FPS work remains parked.

First Mac run36834082669 passed125 gates, then hit a QA-only Deep placement assumption. Final isolated fixture exposes a genuine buried node before placement; production payloads unchanged. Camera fixture now approaches every bay inward, avoiding the outside-room fallback. Final matrix covers all27 resources at1000/2000/3000 and eight sectors each at999/10000. Existing invariant debt “QA flag order or arguments changed” remains explicitly unpassed.

Evidence bindings under .github/world-scale. Native-to-final QA-only package differences are documented in qa-fixture-parity.json. Preserve18 LIVE/Worn files and existing DEV save identity. Standing user authorization covers uploads/QA/DEV publication; LIVE separate.

Final MacQA36835005359 succeeded:256 browser gates, input/404 core and ordinary WebKit.140 captures inspected, including97 treasury tier/sector views, allworld lifecycle states and6 ordinary startup/save views. Exact Mac manifest equals candidate-reviewed. Renderer Mac Chromium ANGLE Metal Apple Paravirtual,DPR2. Evidence11148718680, candidate11148573783; full digests in accepted.json. Evidence transport exceeded connector timeout, so completed evidence was repackaged as full-resolution quality95 JPG with original PNG hashes (transport36836020106/artifact11149486228), without changing/retesting the game. All140 derivatives hash-verified locally before review.

DEV15.37 is published and all27 public hashes verified. Publication4c1a734050726bc14d4baba45d836b50dd86e507/run36836568643; receipt11150070032, rollback11149815728 preserves15.36. LIVE9/Worn9 retained. Canonical gameplay source d7c42c367513ede867afefa34c795959fe1d536b on codex/world-scale-20261001. No pending jobs or permissions. Main is publication carrier; do not rebuild historical runtime or repeat accepted unchanged QA. Details docs/world-scale/HANDOFF.md.

Test https://corpax88.github.io/Ever-Deeper/dev/ after refreshing to15.37. Visit treasury and the surface/mines; no save reset required. Physical iPhone feel remains user feedback; no FPS certification.
