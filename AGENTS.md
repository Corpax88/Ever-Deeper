Latest user-requested continuation: [corrected Worn candidate j](docs/TESTMILJO-HANDOFF.md).
Runtime source e32a03e620913a76f3bee9083b2e9b1d66eef972 fixes fractional limb lengths.
Exact export j is retained; held mining passes, final controls/visual review remain incomplete. No publication.
Read this short current handoff before the older history below.

Latest handoff requested by Mats: [20 September Worn browser candidate](docs/TESTMILJO-HANDOFF.md).
Exact exported candidate and actual browser evidence are saved; eight impacts worked, but the browser suite timed out. Not published.
Read this newest handoff before the historical recovery entries below. Preserve v28/study20 and the remaining visual/control gates.

Current recovery: [20 September continuity and retained source](docs/premium-polish/continuity-20260920.md).
Workspace pruning removed the latest uncommitted tests and fixes; do not count them as saved.
Approved study20 and21 are retained. Ordinary Flow20 gameplay remains disabled. Published baseline is DEV13.

Latest completed preview: [21 exact transition seams](docs/premium-polish/hero-transitions-21-20260919.md).
Two narrow transitions pass actual-game ordered-frame review; all232 mechanics rows match baseline.
Mats approved the study20 loop. Preserve it; broader phases/directions/tools remain open. No DEV/LIVE adoption.

Latest completed hero checkpoint: [20 held-mining flow](docs/premium-polish/hero-flow-20-20260919.md).
Long authored holds reduced; fresh gameplay and independent sequence review pass for this narrow preview.
Mats accepted its visible flow. Wider coverage remains open. FPS paused; no DEV/LIVE adoption.

Previous hero checkpoint: [19C transitions](docs/premium-polish/hero-transitions-19-20260919.md).
Bounded stationary/rapid-restart/exact walk-exit image pass; no9/10 or production adoption. FPS paused.

Current animation review: [Local independent critic workflow](docs/premium-polish/hero-local-review-20260919.md).
Optional external sign-in must not block authorized local investigation and correction. Preserve the existing visual/gameplay release gates and clearly label frame-sequence review limitations.

Current saved work: [premium-polish continuation](START-HER.md).

Current work: [premium-polish recovery](docs/premium-polish/HANDOFF.md).
Test setup: [environment handoff](docs/TESTMILJO-HANDOFF.md).

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
