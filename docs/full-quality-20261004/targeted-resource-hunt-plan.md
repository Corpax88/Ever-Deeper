# Review proposal: rich veins for a tracked mod goal

Status: root reviewed and authorized implementation on2026-10-04. Phase1 generator/save authority is implemented in a separate checkpoint; world integration, visual inspection and timed balance validation remain gates. The proposed completion time is not a measured result.

## Player experience

After restoring Deepheart, track an unclaimed resource mod at its podium, then explore new ground in The Deep. Three small buried deposits per newly bound geology band contain that chosen material. The ordinary five Deep materials, relics, caches and events remain. Digging removes the covering rock first; the correct existing ore asset appears, then a later mining action extracts a valuable physical drop. Existing hero, mod and Vortex collection rules apply.

Support the **seven currently implemented material mods**: Rootiron, Burrowsteel, Prismite, Phase Crystal, Singularity, Deep Alloy and Echo Crystal. Gold/Resonance already has the sale route. Collection-only podiums make no new unlock promise. Do not change the established100,000 goal, paid early-game recipes, ordinary node HP or the first-playthrough resource yields.

Source hint: “The Deep · track this goal for rich veins in new ground,” with the original mine route still visible. A nearby buried deposit may use the matching existing ore-wall hint and the established nearby-discovery text style. It must not expose an intact node sprite through its covering terrain. The currently tracked resource should be recognizable after excavation without a new menu or anonymous generic crystal.

## Deterministic identity and persistence

1. Add one optional bounded `treasury_seam` descriptor to each saved Deep band, containing a whitelisted material ID and an explicit balance revision. A band binds once, while a valid goal is pinned; repinning never changes a stored descriptor. Do not bind a previously excavated/claimed band, so this cannot create new ore inside an old corridor. Existing saves require no reset or epoch change.
2. Reserve node indices24–26 (current ordinary generation uses at most0–16, existing claim mask supports0–30). Derive positions and base amounts solely from world seed + absolute band depth + slot + saved balance revision, using a separate RNG so existing node/site/relic coordinates and IDs do not change. Pick valid covered cells near the three established main-room rows; reject overlaps with ordinary ore, sites, relics or permanent boundaries.
3. Bind once when genuinely fresh bands are generated while the valid goal is selected. Three-band preloading may bind the next two bands; explain “new ground” rather than claiming an immediate reroll after changing a pin. Store the descriptor before allowing mining. If no valid placement exists, retain the binding and generate fewer deposits; never search a new random seed on reload.
4. Extend the existing RunState node-claim authority narrowly: a legacy material is claimable only in a reserved slot with a matching saved descriptor, correct deterministic cell and bounded amount. Ordinary node claims keep their original whitelist. Mark the existing claim bit and create the existing persistent loose drop atomically. Never credit cargo at excavation/reveal.
5. Extend terrain/drop save sanitization only for these whitelisted bound deposit drops. Keep the current node masks and `n24`–`n26` drop IDs; no new freeform reward channel. Reload, rebase, leave/re-enter, pause and double strikes must conserve the exact amount. Existing pending drops remain collectible after a different goal is pinned or the mod is claimed.
6. Successful mod claims already clear their pin. Do not create fresh bound deposits when delivered + held material already reaches100,000; already bound deposits remain stable and collectible. Untracking is not a mechanism for removing or resetting ore.

Implementation owners: a small `treasury_seams.gd` catalog/generator; optional band descriptor/drop sanitation in `endless_terrain_state.gd`; RunState binding/claim authority; additive generation and existing art lookup in `endless_descent_world.gd`; source hint in `treasury_goals.gd`. Keep this separate from Corebreaker's change.

## Initial balance hypothesis

Use three deposits with a deterministic **350–450 base units each** per fresh band. Ordinary yield multipliers and Prospecting apply once at the existing extraction boundary. That is roughly1,200 base units/band, or2,400 with Crownseeker: approximately84 bands without Crown or42 with it for a100k goal. One band is44 vertical metres. This is a hypothesis to test, not a promised completion time.

Target a purposeful **15–35 minute hunt for one new mod with endgame gear**, including discovery, actual mining, pickup and a return to donate. Compare Crusher, Crown and an earned alternative mod. If measured completion is far outside that range, tune the saved balance revision's base yield rather than changing early-game prices or the user's100k target. Ensure the player sees meaningful progress every few minutes and still makes choices between faster excavation and doubled ore.

These real units can be sold after victory; that is consistent with the existing economy. A capped/invisible “treasury-only currency” would complicate inventory and violate the physical-resource expectation, so it is not proposed. First-run tool/gate pacing is protected by the victory condition.

## Acceptance gates

- New save/pre-victory: no new deposits, yields or unlocks. Old completed save: existing terrain/nodes/drops and full maps unchanged.
- Seven resource IDs use their approved matching node art, scale and drop art; reveal-before-extract remains true for ordinary mining, Crusher, Resonance, Chainbreaker, Corebreaker, Laser, Ricochet and mole.
- Deterministic same seed/band/revision output; no original RNG drift. Pin change, unpin, claim, reload and band revisit do not transform or renew a deposit.
- Descriptor missing/malformed, invalid slot/cell/material/amount, duplicate claim, save/reload while dropped, menu pause and stream rebase all preserve entitlement and quantities.
- Actual target-mobile images: intact wall hint, freshly revealed material, mining impact, loose-drop collection and podium progress. Compare to the approved matching ore art.
- Timed seeded hunts and current mobile draw/frame measurements before final yield tuning. No overall9.5/10 claim from a successful script or fixture.

## Critic's current judgement

This repairs a demonstrated acquisition problem while preserving the player's collection premise and returning the hunt to the game's strongest endgame mining space. It is preferable to globally increasing all ore yields or adding eighteen generic mods. Main risks are save identity, silently binding unloaded future bands, modest additional visible-node work and a target that is technically reachable but still dull. The gates above directly address those risks; quantity tuning requires real play timing.
