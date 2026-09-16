# Premium polish continuation — 15 September 2026

Read [the verified 16 September continuation](RESUME-20260916.md) first. It preserves the fourth milestone, adds a reviewed Deep cache optimization and records the current remote-saving block.

Latest work: [fourth milestone](iteration-four-20260915/README.md). Deepheart visual review reaches 9/10 for that room; the whole game is still WIP. Production hero atlases are unchanged and sustained 50 FPS still fails. Earlier sections below are chronological history, not the current remaining-task list.

This continues the verified recovery source `03b7bcf9fcc1b2d64828331a343a016a711db238`. It is work in progress, not a release or 9/10 acceptance.

## Recovered and proven this turn

- Complete remote source/tree checked before editing; baseline invariants and all 14 existing source cases pass.
- Approved v28 Blender source recovered and its SHA-256 matches `94304c12a042b168c0d655dc0ceacffe2efb08997039a7a26c1ed0cc1770bc91`; all eleven v9 equipment originals recovered separately. Never commit these originals/photos in the public code payload.
- Godot 4.7.2 / authenticated Xvfb / Mesa llvmpipe restored. 31 new actual baseline images and 31 core candidate images captured without runtime errors. Independent critic inspected surface, cave and hub pairs and found no new palette, hero or lighting regression. This is not Apple FPS evidence.
- Blender 4.5.3 opened the approved source and exported seven native Worn review poses. Those are baseline motion, not newly authored production animation.

## First implemented changes

- The Deep uses one committed swing clock for resource and wall hits; destruction no longer retargets at contact and truncates follow-through. Actual walking cancels; blocked joystick intent allows mining.
- Movement callbacks, displaced origins and regenerated stream windows invalidate committed targets. Explicit input-direction changes retarget a new wind-up; the visual stays aimed at its committed stone.
- Hero, outfit and headlamp updates no longer construct shop option catalogs on every tick. Cloth uniforms update only on outfit changes. Light Lab level, preview/reset and direct fixture changes remain visible immediately.
- Workshop-level reads avoid eagerly constructing fallback save dictionaries.
- Render wrapper treats script/parse/assertion errors as failure even if Godot exits zero.

## Evidence and limitations

`core-review-20260915/` retains baseline, intentionally failing regression, correction and actual-render reports. The first complete candidate run exposed a held-direction reacquisition regression; it is fixed and both expanded core and the continuous-world journey were rerun successfully. The final complete run passed 14 of 15 cases; dev-tools reported a dummy-renderer null texture. Its isolated repeat passed. This transient remains recorded; all 15 named cases now have passing runs.

New `premium-core` reproduces the original cadence/moving-hit failures, and verifies two adjacent resource hits, two terrain breaks, real blocked input, turning, move-then-stop, release, live outfit shader parameters and non-forced same-style lighting upgrades/reset.

Independent code and visual critics have not certified overall 9/10. Main remaining issues: native walk/mine transition posing, meaningful longer GPU/device tests (including autosaves), compact mobile HUD, credible shop scales, hub composition and terrain joins. Current production sprites remain v28. No new build published.

## Second working milestone: measured rendering and composition

The branch has real five-minute Mac sessions at source `7b6640c1a931be02174afbf3aec4facf929bdf05`, Actions run `35018422347`. All were functionally successful with autosaves and companion present. **None passed the strict sustained 50 FPS gate**: hub 56.8–59.7 average FPS with p95 reaching32.2ms; Ember21.0–35.1/p95 up to86.2ms; Deep13.8–16.6/p95 up to115.7ms. The original hub fixture did not set victory, so built workshops were hidden; the next fixture explicitly completes victory and builds them before entering. Workflow green only indicates functional execution; inspect `meets_50_fps` separately.

Current changes, still WIP:

- Deep contiguous floor strips composite the existing floor/wash once and retain stable world UVs. This removes the old per-cell checkerboard. Source seed4608 / terrain hash1339482333 / same player and camera:490→197 draws, frozen render GPU25.16→19.72ms on local llvmpipe. This is diagnostic software rendering, not device acceptance.
- D2 skips floor hidden beneath opaque stone, retaining floor beneath open cells, resources and translucent rims. Seed4608 / terrain hash4231644570 is identical before/after. Frozen GPU25.45→19.80ms. HUD also changed, so the whole difference cannot be attributed to floor culling.
- Adjacent identical caster spans are merged without changing their solid union. Critic's static lit-floor sample was pixel-identical; no measurable speedup is claimed.
- Mobile goals use a two-column grid for larger recipes. Actual four/five-resource recipes and exact counts pass layout checks. Companion portrait uses shared HUD geometry; status and context controls avoid overlap.
- Assay, forge and Wayfarer use the original full art at revised scale/anchors. Wayfarer's approach and collision now meet the front of the stall.
- Hub workshops have individual visible-size budgets and shared feet anchors, contact shadows and overlapping stone aprons. Finished-site boxes/dots are removed. Hero/companion/workshop depth follows feet. Wall spans use their painted bounds. This remains under critic iteration, not final visual acceptance.
- New source harnesses capture actual interaction approaches, five-cost recipes, sustained sessions, reversible rendering ablations and native motion state. The old movie configuration crops1280×720 despite a1696×780 root; do not use it as UI evidence.

`session-review-20260915/` contains the source-bound Mac reports, controlled diagnostic reports, current layout/collision QA and explicit protected-file intent. Current affected suites `premium-core`, `one-point-zero-ui`, `one-point-zero-world` pass. Production hero atlases are still v28, unchanged.

## Remaining blockers / next work

1. FPS still fails. Cache unchanged terrain draw commands separately from animated shops/resources/effects; preserve immediate damage/reveal/respawn/rebase updates. Retest the next immutable branch source on Mac.
2. Occluder scan ±13cells misses the far edge of Light Lab5 range. Derive caster coverage from actual emitter ranges/transforms, including pet, rather than inflating a rectangular global scan.
3. Native motion still cuts between walk/mine and briefly recovers while moving. The current walk has substantial planted-foot sliding. Author physical locomotion and contact-aware transitions with the recovered native sources; update render fingerprint and atlas schema before production.
4. Continue critic-guided hub composition, nearby labels and ground integration. Pre-refinement critic scores: surface7.5/10, hub4.5/10, HUD7.5/10. No overall9/10 acceptance.
5. Complete current source/packaged gates and longer excavated/UI/biome workloads, then exact exported mobile captures. Physical iPhone heat/battery/Safari acceptance remains separate. Do not deploy WIP or describe this polish as finished.

## Third working milestone

See `iteration-three-20260915/README.md` for retained evidence, rejected trials and current blockers. Stable terrain command caching, actual light-footprint caster coverage, real counter collision, wrapped Guide and complete workshop captions are implemented. One presented mining contact now survives automatic retargeting. Native motion has a real115-frame Worn/right pilot; numeric geometry checks pass but its running support/pose-bridge velocity/rotor recovery remain unapproved. Production atlases are unchanged. Current critic composition: hubabout7/10, surfaceabout7.5/10.

The second Mac source b4bf5e completed Actions35022974768: fully built hub48.0–56.8 averageFPS, Ember22.9–36.9, Deep18.6–25.0 across30s windows. All functionally passed and all failed the strict sustained50FPS gate. `session-review-20260915/mac-composite-*.json` retains the exact source-bound results. No release or deployment has occurred.
