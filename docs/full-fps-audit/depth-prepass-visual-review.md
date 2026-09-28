# Depth-prepass candidate: independent visual and pass-state review

Reviewed completed source `1c3f5c552cff462cb0da74041e85e16762a524ce` evidence in `depth-prepass-evidence-webkit` and `depth-prepass-evidence-chromium`. Read both reports and actual GL rows. Visually inspected all seven candidate native poses in each browser, plus the ordinary candidate gameplay screenshot from each browser. Independently decoded and hashed all 42 native PNG files. No new test or workflow launched.

## Verdict

The one-line startup flag passes the visual and renderer-mechanism gates covered by this experiment. The images are neither blank nor clipped, and the eliminated pass is now positively identified as the native hero's depth-only prepass. This is not an FPS or publication approval: timing interpretation belongs to the overall review, and no physical-iPhone result is established here.

## Actual images

Each native PNG is 400 × 400 with the complete hero and Ember tool where visible from that facing. Helmet, face, glasses, torso, backpack, arms, legs and boots remain properly rendered; the selected mining phases are genuinely different poses. These are unobscured native-viewport images, so the companion no longer hides the self-shadow areas as in the previous atlas experiment.

There are seven distinct PNG hashes, one for each pose. For each pose, all three stages in both browsers have identical PNG bytes and decoded RGBA pixels. Thus all candidate and repeated-state comparisons are exactly zero independently of the report's comparison code.

Nontransparent area is 25,798–28,550 pixels per image, not an empty canvas. The used extents leave at least 52 pixels of border clearance; no tool, feet or helmet touches the viewport boundary. The ordinary 1552 × 840 gameplay captures also contain the complete surface, UI, portals and hero/companion. No gross scene rendering regression is visible.

Coverage is four idle facings and three selected mining phase/facing combinations with Ember equipment. This does not prove every frame of continuous animation or every item configuration, and the ordinary moving screenshots are not exact full-scene pixel comparisons.

## Actual native pass state

Both browsers use masked renderer `WebKit WebGL`, with Apple/Metal unmasked device identification. All six stages retain a 400 × 400 native viewport, 2× MSAA, one stable rig generation, active native updates, and the 4096 directional shadow atlas.

The 400 × 400 MSAA framebuffer contains these observed states:

| State | Depth-only pass | Opaque color pass |
| --- | --- | --- |
| Baseline | Color mask false; depth write true; depth test true; GEQUAL (518); draw buffer NONE (0) | Color mask true; depth write false; depth test true; GEQUAL; COLOR_ATTACHMENT0 |
| Candidate | Absent | Color mask true; depth write true; depth test true; GEQUAL; COLOR_ATTACHMENT0 |

Rasterizer discard and transform feedback are false for these native framebuffer draws. The depth-only submission in each baseline has exactly the same element count as its color pass and separate 4096 shadow pass. Candidate color-to-shadow element ratio stays exactly 1, while depth-to-shadow changes from exactly 1 to 0. Repeated baseline in WebKit restores the depth pass; repeated candidate in Chromium keeps it absent.

Per frame, this removes one 106,057-triangle native geometry submission without lowering resolution, modifying the model, reducing shadow resolution, changing the approved pose bank or freezing the hero. It does not remove GPU skinning or the 4096 shadow pass. Triangle submission reduction is not an FPS percentage, and saved geometry may trade against early-depth rejection; no performance conclusion is drawn in this visual/pass review.
