# DEV15.7 phone report analysis — 24 September 2026

## Outcome
The first real iPhone report was received and all 36 windows read without truncated cells; every report identity matched the summary, which was rechecked after pagination. Private raw telemetry remains in the private receiver. This note records aggregate engineering findings only.

7097 frames over 177.896 seconds: weighted 39.894 FPS. Window averages 37.059–43.079 FPS; 22 frames exceeded 33.34ms; worst interval 173ms. First approximately 60s: 39.089 FPS, final approximately 58s: 40.830 FPS. This recording does not show a progressive decline. All windows are Emberdeep depth 1 with Ember gear. The wholly idle 130–135s window remains 42.94 FPS. No world transition is present.

Canvas stays 2328×1260 at DPR3 (2,933,280 pixels). Reported video allocation stays roughly 659–661MiB, nodes 1325–1351, draw calls 140–279. These are snapshots, not total physical memory or evidence of a leak. Four shadow-enabled lights and two pet lights persist, while visible lights vary 4–6. There is no intervention identifying current light, shadow or hero cost.

## Confidence and monitor limitations
Sustained frame cost and isolated stalls are separate targets. Persistent cost while idle favors investigating rendering; it does not prove GPU saturation. Previous physical DEV5/DEV6 hub interventions in ../light-cost/README.md recovered 60 FPS with all lights off; pet-only and shadow-only interventions had small effects. Those older different-area results prioritize lighting but cannot identify the present depth-1 bottleneck.

The session recorder samples Performance.TIME_PROCESS repeatedly each frame. Some reported window means exceed measured whole-frame duration, and a late window has cpu_max 139ms but max frame 30ms. Treat the monitor as sampled engine statistics, not aligned per-frame CPU timings. Do not subtract it from frame time to invent GPU time, or attribute a spike to autosave. Future diagnosis should instrument actual save/build/upload phases directly with monotonic spans and record timestamps.

## Concrete code finding and preferred solution
Canonical source abc42ca5db531270510802bf7dab4f3f0936d06d; source branch codex/telemetry-dev15-7-20260924. Read AGENTS, code map, verification, current handoff, recorder, world and floor owners.

scripts/world/mossvein_mine.gd sets lit_floor_chunks.composite_pass=false. Its draw_floor call supplies an opaque biome underlay, a tinted texture with alpha 0.94, and transparent wash. FloorChunk._draw therefore draws underlay and texture separately, both with normal lighting. Existing composite_pass is a texture+wash implementation and still separately draws the underlay. Merely switching it on does NOT remove the two lit layers.

Preferred first controlled candidate: implement an explicitly optional underlay+texture floor composite for this path, preserving texture coordinates, alpha, tint, underlay and exposed-region culling, so one light evaluation replaces two. Validate framebuffer clipping/blending differences in bright highlights; combining before lighting is not guaranteed pixel-identical. Preserve the existing two-pass reference and toggle only this path in identical-state A/B/A measurements. Keep it only if it materially helps and actual paired images retain the approved appearance. Do not change approved assets or animation.

This is a candidate, not an implemented or verified fix. More aggressive reduced internal world resolution is a second experiment if lighting remains dominant; keep UI sharp, test resize/input and original restoration, and review quality before adoption. An older dynamic canvas experiment produced resize errors (../render-probe/README.md), so do not revive it blindly or patch engine JavaScript.

## Smallest next experiment and gates
1. Run actual Emberdeep depth-1 baseline/candidate/restored with the same camera/seed/state and framebuffer, including warmed gameplay and true mining. Capture paired unmined/struck/mined floor edges and maximum-light cases across affected depth-1 biomes.
2. Separately measure isolated lights-off, shadows-off and pet-lights-off controls if the candidate has no clear benefit. Existing user AUTO FPS TEST supports hub/depth2 only and does not establish current Emberdeep depth1 cause.
3. Add precise stall-event spans only where needed; preserve opt-in report transport and private storage.
4. Publish DEV only after required exact-package visual/gameplay checks; preserve LIVE, Worn, saves and all approved hero resources. A new physical-phone report decides acceptance. Mac FPS is not proof of phone recovery.

No runtime changes, exports, tests or publications were performed for this analysis. Existing verified Mac workflow is documented in dev15-7/HANDOFF.md and the game-test-environment skill; no unchanged package retest was needed for a read-only analysis.
