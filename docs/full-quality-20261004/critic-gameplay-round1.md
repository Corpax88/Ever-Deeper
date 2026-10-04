# Gameplay and progression audit — round 1

Scope: canonical DEV15.54 source `be3a698e0ad8bedb91e877b9932a7bb05b80684a`, inspected 4 October 2026. This is source evidence, not a substitute for a complete playthrough or measured progression times. No defensible overall 9.5/10 rating yet; moment-to-moment feel and economy remain unscored without current playtest evidence.

## Priority findings

| ID | Severity | Evidence and consequence | Suggested change and validation |
|---|---|---|---|
| G1 | High | `scripts/world/drill_modes.gd:69–99` cancels ordinary mining and performs laser work without setting the mining animation; `scripts/progression/miner_training.gd:30` charges stamina exclusively from `mining_visual_active`. A stationary laser can recover stamina while damaging rock/ore. | Account for actual laser target work independently of animation. Verify real laser hits drain stamina; empty aim, release, menus and scene changes rest correctly; keep beam/hero animation unchanged. |
| G2 | Medium | `scripts/state/treasury_goals.gd:28–34,78–88`: claiming the tracked reward neither clears its pin nor changes `hud_goal`; a completed, already claimed mod still says “Return to your podium.” `guide_director.gd:67` lets this override the useful next objective indefinitely. | Clear the matching pin after successful claim, or return a completed/untracked result for claimed mods. Verify claim/save/reload restores the normal next goal, while an unrelated pin stays. |
| G3 | High economy risk; duration unmeasured | The common goal is 100,000 (`treasury_stack.gd:3`). Five bindings require Depth 2 resources (`treasury_goals.gd:5`), while `_break_rock` starts at 1 unit before bonuses (`rootwound_world.gd:1181–1187`). The Deep generates only five different late resources (`endless_deep_layout.gd:11`; `endless_descent_world.gd:914–950`), so improved endgame excavation does not help earn these five mods. | Keep the user-approved 100,000 target. Measure actual nodes/minute and respawn supply for each binding, then improve purposeful acquisition routes or endgame ore events if the grind dominates. Need actual GameData and timed play; do not claim a specific duration from this source alone. |
| G4 | Medium, existing design limitation | 27 podiums (26 materials + currency) expose only 8 real mod rewards (`treasury_state.gd:7–10`, `treasury_goals.gd:5`). Other panels deliberately say COLLECTION (`treasury_goal_panel.gd:178–190`). This is incomplete relative to the user's 26-resource/26-mod ambition, not a false unlock in current UI. | Retain honest collection labels. Plan distinct missing rewards after existing eight are enjoyable; do not invent generic mods to inflate coverage. Validate every claimable goal has a preview, real mechanic and persistent unlock. |
| G5 | Medium, inherited balance limitation | Corebreaker charges for three seconds then hits one ore node three times (`five_drill_mods.gd:153–162,240–250`). Ordinary Deep nodes have only 950–1022 HP (`endless_descent_world.gd:950`). Prior accepted `docs/five-mods/HANDOFF.md` explicitly acknowledges Crusher already one-hits them and receives no benefit. | Measure current fully upgraded tool power against real node HP. Give the charged mod a meaningful distinct benefit for the actual endgame loadout without adding artificial HP or silently changing the approved design. Compare time-to-clear and visible effect against ordinary mining and Chainbreaker. |
| G6 | Medium usability risk | All carried materials and wallet gold are automatically offered by `treasury_room.gd:151–169`; `TreasuryState.land` irreversibly debits them. The normal sell route protects required progression material (`run_state.gd:855–912`), but treasury does not. Unbuilt workshops receive relic supplies, yet bought upgrades and companion skills still compete with these donations. | Preserve the approved continuous simultaneous flight. Playtest whether the donation zone and consumption are understood before first entry; if not, explain donation before stepping onto it and consider a user-controlled reserve. Do not remove the approved all-resource spectacle by assumption. |
| G7 | High | `_update_loose_drops` in `endless_descent_world.gd` hardcodes 140px attraction; `five_drill_mods.gd` hardcodes 256px for Vortex. Neither uses the Treasure Chamber's earned +72 pickup radius, despite `commerce_catalog.gd:316–320` advertising it. | Preserve the current base radii, then apply the authoritative earned bonus to both paths. Verify a real drop beyond the base radius moves only with the upgrade, walls still block and Vortex retains its advantage. |

## Strengths established in source

- One transaction owner supplies guide/shop costs; protected selling and persisted deliveries reduce progression dead ends (`progression_goal.gd`, `run_state.gd`).
- The Deep preserves exposed-ore separation during Resonance and Chainbreaker, giving discoveries a visible second mining step.
- Mod selection is exclusive, previewed and saved; ordinary movement remains with the player controller.
- Relics lead to concrete Hub construction, then workshop upgrade goals; collection pins have real resource sources.
- Menu rest preserves stamina recovery while suppressing motion/mining training.

## Required playtest coverage before an overall rating

Fresh save through first sale, two tool upgrades and first gate; one complete Depth 2 drill loop; Deepheart-to-first-relic onboarding; all eight mods using earned unlocks and real late-game gear; targeted 100,000 goal acquisition; treasury donate/claim/leave/reload; pet mining and pickup during each relevant world. Existing QA-created states are useful regression evidence but cannot establish the duration or enjoyment of this whole progression.

## G1 implementation checkpoint

Implemented explicit laser work accounting in `drill_modes.gd` and consumption by `miner_training.gd`. A valid mining target now drains existing stamina without enabling a pickaxe animation. Live hold, selected mode, active world and enabled controls invalidate stale work before the next render update. Ordinary mining, animation and save schema are unchanged.

`tools/review_laser_stamina.gd` exercises the real runtime owners for rock damage/drain, empty aim, immediate release and toggle, menu rest/no XP, inactive world and reset. `git diff --check` passes. Runtime execution remains pending restored package/QA; this is not yet a passing gameplay gate. Root owns checkpointing/publication.

## G2 implementation checkpoint

Successful mod claims clear only their own pin before the existing save transaction. Save cleanup retires an old claimed-mod pin; stale in-memory state no longer overrides the next useful guide objective. Already claimed mods cannot be re-pinned. Their panel explicitly shows disabled MOD UNLOCKED instead of a nonfunctional TRACK GOAL. Unrelated pins, unclaimed goals and collection-only goals remain available.

Regression entry: `tools/review_treasury_goal_completion.gd` checks actual claim, duplicate rejection, unrelated pin preservation, save/load, legacy normalization, guide fallback and both panel states. Runtime/render validation remains pending; root checkpoints each logical change.
