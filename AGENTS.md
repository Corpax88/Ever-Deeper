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
