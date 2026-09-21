Current candidate: DEV14.2 steering and render-cost fixes are reviewed; publication is requested by `.github/dev14/review.json`. Confirm the new publication receipt before treating it as public. Exact game source is bee888fe36d6b8285e1198384d40694d3154956a, passing candidate run35616856586. Continuous steering no longer restarts unfinished turns; the same hero uses a derived indexed LOD preserving skin, materials and motion. Mac DPR3 windows averaged53.60–59.76 rAF FPS, with stalls up to400ms; this is not stable physical-iPhone FPS certification. Preserve LIVE/trial bytes and the DEV save namespace. See docs/premium-polish/dev14-native-worn/DEV14.2.md.

Current verified release: ordinary [DEV14.1](docs/premium-polish/dev14-native-worn/HANDOFF.md) is published at https://corpax88.github.io/Ever-Deeper/dev/ (menu version 1.0.0-dev.14.1).
Publication run 35610110028 passed and all 27 public file hashes are verified. Exact game source is 6d6e1b8d98ecae6661b514fff92e28447715dd33 on codex/hero-loop-flow-20260918; main holds publication and evidence. The same hero is loaded from a prepared PackedScene; animation is retained. Mac Chromium/WebKit checks passed; the physical iPhone crash is NOT confirmed fixed and the native Simulator attempt was inconclusive. Preserve the DEV save namespace and LIVE bytes. The current handoff supersedes older checkpoint and pending-publication statements below. Do not repeat exports/uploads/tests for this unchanged candidate.

# Ever Deeper project rules

## Visual release gate

These rules are mandatory for every visual change, in every chat and for every agent.

1. An approved mockup is the visual acceptance target. Preserve its material quality, silhouette, depth, lighting, palette, and integration with the game.
2. A mockup is concept art, not a production asset. Build the result with proper production assets and integration.
3. Do not replace an asset-led design with procedural polygons, generic shapes, placeholders, stretched crops, or a lower-detail approximation unless Mats explicitly approves that exact change first.
4. Before publishing, capture the final build at the target mobile viewport and compare it visually with the approved mockup. Source review, parser tests, headless startup, and FPS tests do not count as visual verification.
5. Check every affected visual state, including normal terrain, corners, barriers, permanent walls, transitions, and relevant biomes or depths.
6. If the final build cannot be rendered and inspected, stop. Do not publish and do not describe the work as finished.
7. Publish only after both visual fidelity and gameplay checks pass. Never infer visual quality from successful code or automated tests.
8. Any exception requires Mats's explicit approval before implementation or publication.

## Asset definitions

- Asset: one production PNG with transparency, no text, no background, and no mockup composition.
- Mockup: a concept sheet used as a visual target.
- Sprite sheet: real animation frames, not a collage of concepts.

## Finding and verifying code

Start with README.md and docs/code-map.md, then read the named owner of the change.
The root Godot project is authoritative. Historical JS code and release patches are not
current runtime source. QA startup belongs in scripts/qa/qa_launcher.gd and named suites.
Keep gameplay/save changes separate from structural cleanup. Run tools/qa.py and
check_invariants.py as described in docs/verification.md; report known legacy failures
honestly. Do not remove debug/save compatibility APIs based only on textual reference counts.

