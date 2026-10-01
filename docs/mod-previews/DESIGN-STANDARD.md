# Mod previews — approved visual standard, 1 October 2026

Mats approved `approved-concept.png`, then explicitly required the **Pappa Hammer from the Skills section**, not the Blender gameplay model. The reference is `assets/ui/skills/miner-mole-portrait-v1.png`. This is the visual acceptance standard for future mods.

## Required composition

Copper-edged dark iron panel with silver riveted corners; resource/treasury eyebrow; large ice-blue mod name; dominant wide illustration that shows the actual effect; one short sentence; thin gold progress bar with exact delivered count below; gold primary claim button; quieter track and close buttons; source hint at the bottom. All text and controls are live UI, never baked into the illustration. Maintain clear spacing at mobile landscape widths, pause gameplay while open, and resume on close.

The figure must match the Skills portrait: friendly round face, brown eyes, square black glasses, full brown beard, stocky dad build, yellow-orange helmet/headlamp, cream shirt and brown leather overalls/gloves/boots. Use the actual reference PNG in image generation; never approximate from the Blender model or memory.

Each new mod needs its own approved meaningful effect illustration and concise truthful description. A production asset is one transparent PNG, no text/background/mockup. The scene backdrop is a separate existing game texture. `approved-concept.png` is reference only; do not crop it into production UI. Original generated asset PNGs and the approved concept are kept unmodified in Git.

## Ownership and states

`mod_preview_catalog.gd` holds presentation entries; `treasury_goal_panel.gd` provides the reusable layout. `TreasuryGoals` retains claim, enable and pin authority; `RunState` retains saving. Catalog art must never grant a reward. Only Resonance is defined now; do not invent effects or rewards for other materials.

Verify empty/partial/ready/claimed-on/claimed-off, pin/unpin, return-to-game, persistence and an unspecified material. Compare actual final game captures to the approved concept on 844×390, 667×375 and 932×430 layouts. Keep physical-iPhone performance claims separate from native/Mac browser evidence. Future entries must preserve this visual hierarchy and the correct Pappa Hammer identity.

## Asset provenance

Built-in imagegen using the exact Skills portrait plus the approved corrected concept. Resonance prompt: same reference character bracing the drill in both hands, blue-gold mining wave and shattered ore rocks, wide transparent illustration, no text/UI/background. Gold-button prompt: empty authored beveled gold plate matching the approved claim button, transparent, no text/UI. Game uses a runtime atlas region to omit transparent padding around the button; the PNG is unmodified.
