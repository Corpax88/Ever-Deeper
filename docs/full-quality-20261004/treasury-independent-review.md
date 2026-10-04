# Treasury resource hunts — independent persistence review

**Result: pass for save identity, conservation and existing-world compatibility at the reviewed scope. No production defect found in this review.** The reviewer did not author the seam generator, authority or world integration. This is not acceptance of the proposed 15–35 minute balance target or of rendered mod interactions.

Reviewed `treasury_seams.gd`, the RunState binding/claim/pickup authority, `endless_terrain_state.gd` sanitization and `endless_descent_world.gd` generation/strike/drop integration. Read the author's 40 save-layer and 84 real-world assertions, including the clean phase2 native log. Independently executed **27 additional assertions** against exact phase2 PCK SHA-256 `53a63ee0db2fb13ef2b2cc666907e75ea5998c7b37c3311b292f662216489267` on native Godot 4.7.2. The independent log is clean.

## Independently exercised

- Generated an actual pinned Phase Crystal deposit and committed its descriptor before extraction.
- Excavated real covering terrain and extracted through `_strike_resource`, using Crown's real multiplier and a controlled actual Prospecting roll. The physical drop contained precisely `base × 2 + 1`; cargo remained unchanged until pickup.
- Obstructed the real temporary save path. The failed checkpoint retained both original disk generations and the in-memory pending drop. Repinning, marking the original mod claimed and regenerating the window could not change its identity or quantity.
- Removed the obstruction and waited for automatic retry without another mining action. Disk reload preserved the deposit. Actual world pickup credited the saved amount once; repeat pickup, a second checkpoint and a second reload did not renew it.
- Rejected alternate spellings such as `n024`, boolean/NaN revisions, infinite/out-of-range/repeated cells. A corrupt seam loses only its unauthorized seam drop: valid ordinary rock drops are retained.
- Loaded a pre-feature document with a future preloaded ordinary journal. Both the journal and previously reached unjournaled bands stayed unchanged when a new goal was pinned.

The executable is `tools/review_treasury_seam_integrity.gd`; reports, clean log and immutable package receipt are in `evidence/treasury-independent/`.

## Code-grounded checks

Reserved slots 24–26 do not overlap ordinary generated slots 0–16. IDs include absolute band depth, and placement cells stay within the existing 40×22 journal. Separate seeded RNG objects prevent new deposits from consuming the ordinary generation sequence. A stored descriptor or invalid-descriptor tombstone wins over later pin changes.

Extraction validates the descriptor, exact material/cell, allowed amount and excavated cell before changing the node bit. Marking the bit and creating its physical drop share a state batch. Pickup removes the pending drop before crediting cargo; reload sanitization requires both the claim bit and excavation bit for a seam drop. Existing ordinary materials keep their original route and claim behavior.

The current single revision is explicitly validated. Any future balance revision must preserve older saved revision descriptors; changing `REVISION` alone would deliberately fail closed and is not a safe migration plan. No such revision change is part of this reviewed candidate.

## Remaining gates

Actual mod/mole interactions are being extended by the gameplay owner. Target-mobile appearance, readable nearby hints, performance and timed hunts remain their own gates. Three-band preloading may bind future deposits before the hero enters their band; this is the documented “new ground” contract, not an immediate reroll on changing the tracked goal.
