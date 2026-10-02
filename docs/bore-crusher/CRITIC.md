# Independent Crusher / Bore Rush review

2026-10-02. Scope: approved Crusher head rotation, two-handed forward hold and modest body lean during Bore Rush. Preserve the original asset, ordinary animation, gameplay and saves.

## Verdict

**8.5/10 — visual/code scope accepted, no remaining visual blockers in reviewed native captures.** Final browser evidence is verified; approved for DEV publication after the normal immutable-package publication checks. This is not a physical-iPhone or FPS acceptance.

## Review rounds

1. Source / preliminary presentation: requested a fixed shaft and grips with head-only rotation, original asset retention, smooth release and no pose bleed when switching gear. Flagged instantaneous reset to the unrotated mesh and fading Crusher pose on another tool. Both issues were corrected before final review.
2. Earlier candidate runtime: inspected render3's 48 full scene captures (eight bearings, four Rush phases, normal and released poses), with enlarged direction crops, and all ten transition captures. Independently read 56/56 native checks and 5/5 transition checks. The source revisions after this runtime only alter the browser QA fixture, per the owner's retained-resource comparison; final browser confirmation remains pending.

3. Actual impact/turn correction: browser gameplay exposed a real disconnected-rig regression that the cleared-floor matrix missed. Candidates 5 and 6 remained rejected when focused tests reproduced rapid-turn and displayed-position mismatch. Candidate 7 (source `74d63df43fbc2a6054280a384a34e2eb9b9f810b`) suppresses the ordinary swing overlay during Rush and anchors the braced tool to the displayed torso heading AND translation, not the logical target pose. The rigid validation guard is retained. Independently verified 6/6 focused checks including 22 actual terrain impacts and four forced impact/turn directions, with all five actual images inspected. Final native matrix is 56/56, and final transitions are 5/5; inspected sixteen enlarged final direction samples and all ten final transition images. Final native total: 67/67. **Third-round native/code verdict remains 8.5/10, no remaining native blocker.**

## Findings

- Original curved purple/gold Crusher geometry remains recognizable. Rotation leaves the shaft, ferrules and both hands fixed; no detached head, frozen head fragments or viewport clipping visible in reviewed phases.
- Hero holds the tool in front with two connected arms. Lean is subtle and appropriate; authored feet continue their gait. Rear view naturally occludes most of the tool, without a new protruding fragment.
- Entry and release samples show the pose moving into and out of the brace. Head returns to its original angle before the ordinary mesh is restored. A nearly edge-on head briefly reads as a thin line, expected for this curved pickaxe rotating around its shaft, not a missing-mesh defect.
- Mid-Rush Comet switch, return to Crusher and laser state retain appropriate tool identity; no Crusher pose residue found in the scoped assertions/captures.
- Mesh partition is prepared on equip, not the first mining frame. Original asset triangles/materials are retained and the original mesh resumes outside Rush. The partition is asset-specific and must be re-reviewed if Crusher geometry changes.
- No mining, movement, rewards or save logic changed in the three production scripts reviewed. Final native travel and actual terrain-impact checks pass. Earlier Mac/browser failures and native rejected candidates are retained above. Final Mac browser report independently verifies 75/75 checks, including Crusher pose, travel, boost and release cases. Five affected actual browser captures inspected: correct visible braced silhouette and no detached limbs/head.

## Evidence

- `review-directions.jpg`: enlarged crops of two Rush phases for all eight directions, from final render7.
- `review-transitions.jpg`: ten final transitions7b entry/release/gear-switch/laser captures.
- Raw source evidence at session root: `render7/`, `transitions7b/` and `impacts7/`; earlier evidence is historical.
- `review-impacts.jpg`: five actual mining/forced-impact frames from impacts7.

Phone readability and subjective animation feel remain Mats's test; do not claim performance improvements or physical phone validation.

## Final browser evidence addendum

Run `36981607422`, source `74d63df43fbc2a6054280a384a34e2eb9b9f810b`, DEV15.46. Independently read browser/report.json (passed=true, 75/75), core/results.json (both core cases passed), and ordinary/report.json (normal startup, no fixture arguments, completed observation, physical_iphone=false). Browser and ordinary reports use the same PCK SHA256 `80a3db2b0f2a161a2b610241ab73314805ea126a54d3a314a946f437c63b0154`; independently hashed local candidate7/index.pck and matched it.

Inspected five affected browser images in `review-mac.jpg`, alongside final native/transition/impact evidence above. **Final third-round verdict: 8.5/10; no remaining blocker in this scoped change. Approved for DEV publication.** No phone or FPS claim.
