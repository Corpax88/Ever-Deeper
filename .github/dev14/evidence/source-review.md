## 9989805 graphical follow-up — Hub cache fix corroborated

All 20 original browser5 PNGs reviewed. Hub now visibly holds Worn; report agrees with pickaxe level 1, drill level 0, gear Worn and one active native rig. No new confirmed still fidelity/clipping blocker. Pause releases native rigs. Full graphical acceptance remains pending actual post-resume movement because the existing observer reads Surface's nonexistent `active` property. Hash-bound visual findings: `evidence/dev14-browser5/independent-review.{md,json}`.

## 9989805 cache follow-up — source accepted, rendered fix pending

Reviewed current controller `prepare_visual_cache` and visual refresh/publication flow. Invalidating `_visual_state_initialized` before preparation is necessary: preparation can refresh the visual to Deepcore while controller's prior Worn levels still satisfy `_update_visual`'s skip condition after Worn restoration. The next publication now refreshes actual equipment. The f898 Hub still and report corroborate the stale gear; they cannot verify this subsequent fix. No new concrete source blocker found in this narrow change. Final graphical acceptance awaits corrected-package evidence.

# Source follow-up — feature override correction

Checkpoint `f89856308f0e088c0ab5b98fad772d4c73fcd8e0` changes the native initialization lookup in `player_visual._ready` to `ProjectSettings.get_setting_with_override("native_worn/enabled")`. The inspected local line retains the DEV feature and non-headless guards. This resolves the mismatch between the false base setting and the enabled DEV override. The previous independent source review missed this lookup defect.

Inspected `player_visual.gd` SHA256: `94aff1c0471d1c492ea5c7e5e25b18b8bff6bff069ddd5f76aaa1f98c48beb3c`.

The parent reports that checkpoint `34be8ca` passed exported headless gameplay (1257 gameplay and 125 touch checks, plus input/flavor). Those checks do not establish that the native renderer activated. Its pending graphical run cannot certify the corrected native path. No new export or test was run by this critic. Final native-rendering and visual acceptance remain pending actual images from the corrected candidate.

---

# DEV14 independent source review — closed

**Current decision: no remaining concrete blocker identified in the bounded source review of checkpoint `55f0a84c2182c5386f8222151a470d7852e4a2c7`.** This supersedes the open findings in the historical iterations below. It is source acceptance for the reviewed integration fixes, not publication or final visual approval.

The final inspected impact branch restores the saved aiming plan only for an older swing or when the current mode is no longer mining. A same-swing earned retarget therefore keeps its actual contact target through recovery. The other reviewed fixes retain real world timing, distinguish Surface mining owners from mutable node targets, preserve recovery when no next node exists, publish successful Surface impacts before retargeting, read the actual damage target, rebase retained contours after movement, and safely clean up an uncreated viewport. Existing gameplay damage rules and save namespace remain outside this presentation change.

Final inspected local SHA256s:

| File | SHA256 |
|---|---|
| task_motion.gd | `2b287dc69d5623d645946545931cef48675dccb21c7365fd7ec4db952fc0dde3` |
| player_controller.gd | `4f743b75db02b97c61170c8cd975bb17d6613dd812ada60557cf251bda3e359c` |
| legacy_mining_context.gd | `9549c9fc0bd9b59b170630179289bf051bda042cf030c1f5c2de2f5c08ed1962` |
| native_worn_visual.gd | `f9dae5a20e6c73379c31f2819fdc27c164948091a367ad4bcc498a3fe22133ea` |
| surface_world.gd | `0078665582a82f1646aa62895f3326fb01748c54372dbbc3b0588c9299f81e35` |

**Limits and next step:** source inspection cannot establish unclipped poses, ordinary-speed continuity, all-direction visual fidelity, equipment reentry behavior, physical iPhone behavior or FPS. Use the parent's targeted QA and actual DEV14 graphical capture next. No successful CI/export/game run is claimed here; the earlier pipeline stopped before export/game testing, and the reported extractor correction was not independently executed by this critic. No source mutation, duplicate suite/export or publication was performed by this critic.

---

The following review iterations are retained as historical evidence; their open decisions are superseded by the current decision above.

# DEV14 initial independent code review

**Decision: changes required before final integration approval.** This is a focused source review of the first ordinary `/dev/` implementation, not visual approval. No source mutation, export, game suite or publication was performed.

1. **P1 — Preserve the ordinary world's actual swing and impact packet.** `native_worn_visual.gd:84–98` fabricates a 0.68-second cycle and detects new legacy swings only from sampled progress wrapping. Mossvein's owner instead freezes the actual cooldown/heat/rush duration at `_start_swing` (context lines 885–898; barriers explicitly use 0.60), and its impact call at line 988 never establishes a presentation target. The wrapper sets `target_valid` only in its local dictionary, leaving the controller's `impact_target_valid=false`; consequently `task_motion.gd:319–328` skips the earned contact pose. A slow frame crossing the first hit or a restart/turn between renders can therefore display the wrong pose/aim despite correct damage. Publish target, swing identity, continuation, real duration and strike phase from each existing world's swing owner without changing mechanics. Pass the phase on **every** `set_mining_visual` call: its default −1 overwrites the valid phase in `player_controller.gd:221` even after `begin_mining_presentation`. Also preserve real remaining-hit seconds when remapping phase: the current deadline becomes `0.65 × (0.42/h) × (h−p) × C`, rather than `0.65 × (h−p) × C`. Smallest verification: first hit, held-cycle wrap and a quick cancel/turn/restart using one ordinary-world clock, including its existing speed modifier.

2. **P1 — Rebase retained impact contours after player movement.** `_surfaces` returns points relative to the current player (`native_worn_visual.gd:74`); lines 101–103 cache and reuse that array solely by target-position equality. When an earned hit is retained through movement/cancel, the new plan receives `impact_target_position − current_player_position` but contour points computed at the previous player position. With a nonempty contour the solver aims at those stale points, displacing contact from the live ore by the intervening player motion. This specifically undermines the old-impact handoff supported by `task_motion.gd:321–344`. Keep contours in target/world coordinates, or rebase cached relative points before use. Smallest verification: an actual hit and movement/cancel before the next rendered update, with the retained target and final contact compared in the same coordinate frame.

3. **P2 — Make failed-start cleanup tolerate an uncreated viewport.** `Rig.configure` can reject metadata or an asset hash before creating its viewport (`native_rig.gd:59–94`). `_start` then invokes `_fail`, whose `suspend` unconditionally dereferences `rig.viewport` (`native_worn_visual.gd:30–35,47–58`). That path raises a second error before freeing/resetting the rig and can repeat each update instead of returning cleanly to the atlas. Guard viewport validity separately from rig validity, while always completing cleanup. Smallest verification: a deliberately rejected configure result in a small fixture; no game package re-export is needed to establish the null guard.

The copied `task_motion.gd` and `contact_surface.gd` are byte-identical to `tools/hero_v28/runtime_pilot` originals. The copied rig differs only by the inspected outfit material/mask support. Equipment selection remains gated by the existing loaded `active_gear`; switching away suspends the rig, returning recreates it, and outfit shader changes do not mutate RunState. The existing development save namespace and normal main scene are preserved. DEV feature gating and displayed DEV14 version are explicit. No save-writing or world-reset path was found in the added presentation layer.

**Remaining visual uncertainty:** the unchanged fixed-size rig viewport and finite/limb checks do not establish that complete tool/limb poses stay inside the image. No clipped pose is asserted from code alone. The planned actual DEV14 capture must inspect turned/extreme poses and equipment reentry; stills cannot establish continuous motion or FPS.

Reviewed file identities (SHA256; local initial snapshot):

- `scripts/player/player_visual.gd`: `0b5af663954df305051b6dd64c027769f2790a1e65f0cd1c57753a5cbfa6a35f`
- `scripts/player/native_worn_visual.gd`: `26e8fe53c72ad3b5ae805afef3e85ab4820899d37f7d077a60c62244da3b6513`
- `scripts/player/native_worn/runtime_motion.gd`: `c3d99eef97ecd133cf2592aaf4603c0c91e2562013f7490f80110d964d795654`
- `scripts/player/native_worn/task_motion.gd`: `8c3e464e2f2959ca6b313c6d688df46cd7f8e40e3c09385286971aae9a4aef86`
- `scripts/player/native_worn/native_rig.gd`: `81d7c330622e471d983e30b97069376ef295fc8abf223c7c7e78149f14df4e98`
- `scripts/player/native_worn/contact_surface.gd`: `1b9bb74efe3f4ba56bddd8c2d97e783955c6fa6bcfb675d91a33b798ee97df21`
- `scripts/player/native_worn/native_surface.gdshader`: `da92cb0eb4256466189b9b5397888e35c06c657a7d92232010fd45a25214f659`
- `project.godot`: `e3374a5a9e3aacb9adff5b0f8a1b60f9c82a7104fdcdc1bf4cd5cd68a2aa3c08`
- `export_presets.cfg`: `814ff4523631c9f2e5ec91464df30016e95ced798289291a79e0b9086a263ce0`
- `scripts/ui/premium_menu.gd`: `a053209c0064d253cb6fd004f22e61b505617a95a1a503699be9353b099679d7`


# Revision 2 — setter integration review

**Decision: three concrete integration blockers remain in this snapshot.** The earlier stale-contour and null-viewport defects are corrected: cached impact points now rebase by `last_surface_origin − player.global_position`, and cleanup checks viewport validity. The solver now remaps pose phase separately from its mechanical-time deadline. The legacy setter establishes context before copying retained impact fields and preserves a valid context hit phase when its optional argument is −1.

1. **P1 — Background Surface setters restart an ongoing native swing each frame.** `_update_mobile_surface_resources` runs nearby resource owners as well as the active one (original Surface lines 2005–2039). At Moonglass Mountain, anchor `(1665,635)`, Moon Bloom's `(2000,595.3333)` is within the 560×640 focus. Its inactive `_update_moonglass_resource` calls `set_mining_visual(false)`; the active mountain subsequently calls `true`. The new controller resets `_legacy_context_active` on every false (235–237), so the subsequent true starts a fresh serial (244–248) despite the real swing elapsed increasing. `task_motion` then resets transition age each update, preventing the transition from advancing normally. Distinguish the actual active swing's cancellation from another deposit's background publication. Smallest regression: hold mining at Moonglass Mountain while the nearby Moon Bloom updater also runs; require one serial per real cycle and advancing transition age.

2. **P1 — Two Surface strike owners still publish no earned impact.** Original `_mine_moonglass_resource_once` (2427–2459) and `_mine_timed_surface_resource_once` (2825–2897) change HP/shell and hit counts, but neither invokes the recoil/impact setter. The revised adapter reads only pose setters, so `_mining_impact_serial` never records these successful strikes and the task solver's guaranteed contact presentation is skipped. Publish a presentation-only impact from each successful strike owner before it mutates target indices; blocked/invalid attempts must not count. Do not infer earned hits from crossing a phase threshold. Smallest regression: one successful normal-node hit, one shell hit and one blocked attempt; match actual damage events to presentation serials.

3. **P1 — Retain the committed target through recovery.** Both Surface node strike functions replace their mutable target index immediately after breaking a node. The next setter reads that new index and `same_target=false` starts a new presentation swing even though the gameplay elapsed has not wrapped. At post-hit progress, the new transition's remaining-hit deadline collapses to 0.001 seconds. This can redirect the recovery toward the next deposit before the real next swing. Rootwound has the same acquisition problem: `_hit_terrain`/`_hit_rock` set `target_dirty`; its next `_process` updates the target before the still-active recovery setter. An empty Rootwound kind also falls into the adapter's terrain branch and converts invalid cell `(−1,−1)` into a finite aim target. Retain target identity/position until the actual swing rollover or cancellation, and validate empty kinds/negative cells when acquiring a new target. Smallest regression: break a node with another target nearby, then with no remaining target; require the earned-contact/recovery target to remain unchanged until real rollover/cancel.

Original-world evidence was inspected at `48bdf168cf46a02ab82520e0050cb2a111d77d84`, including the actual Rootwound and Deepheart scripts and Surface hit/update methods. The relevant scene names match the adapter routing. The parent has acknowledged the Surface impact and target-retention fixes; those promised edits are not counted as verified here. No export, gameplay suite, publication or candidate source mutation was performed by this critic. Rendered clipping, normal-speed continuity and equipment reentry still need the planned DEV14 capture.

Revision-2 file identities (SHA256):

- `scripts/player/legacy_mining_context.gd`: `5a7b7279f2504dff8e83e46fa73ce1e2f5257aa3fbe11f78f1494ec8f519ffe1`
- `scripts/player/player_controller.gd`: `89068f5495215d1a526cde041ce7f5bae91867f5d64227f1f095248aa336a383`
- `scripts/player/native_worn_visual.gd`: `f9dae5a20e6c73379c31f2819fdc27c164948091a367ad4bcc498a3fe22133ea`
- `scripts/player/native_worn/task_motion.gd`: `6e49ef2fbf1cc58c5800ee0e4d82bc69a7a6e4ee647adbcd6e5b181bc47d0a89`


# Revision 3 — checkpoint 6e39ce85edef63aaa7adc33fd91d9fc6bc8e989d

**Decision: one concrete code blocker remains; the rest of the prior findings are closed by source inspection.** The no-next-node path now retains actual elapsed/activity and the existing committed target. Surface owner identity is separate from mutable node identity, so a different owner can begin a new swing even without an elapsed decrease. Successful Surface strikes publish a real impact before retargeting, and legacy earned impacts now read the actual damage target. The earlier contour rebasing, null cleanup, mechanical deadline and background-publication corrections remain present. This is not final graphical approval.

**P1 — A same-swing pre-hit retarget still resumes the obsolete recovery plan.** When a legacy swing begins at A and gameplay retargets to B before its hit, the controller now correctly records `animation_impact_target=B`. However, `task_motion.gd` saves the A contact plan, plans and displays B for the earned contact, then unconditionally restores the saved A tool/yaw/screen (impact block around 327–340). The event still has the same swing serial. If the player has stopped by impact and the short entry transition has finished, `old_contact=false` and no transition is rebased. On the next update `new_swing=false`, so `aimed(phase)` immediately resumes A. The one corrected contact frame is therefore followed by recovery toward an obsolete target.

Smallest fix: retain or explicitly rebase the earned B contact/recovery plan when the impact belongs to the current swing; restore a different pending plan only for an actually older swing or cancellation. Preserve the existing gameplay clock and damage behavior. Smallest regression: begin at A, move/retarget to B and stop before the hit, then inspect the earned-contact update and the next two recovery updates. Require actual target B and continuity into B's recovery, with no extra gameplay hit or cycle.

The checkpoint identity is supplied by the parent; the relevant current local controller/context/task code was inspected. The planned source CI and actual DEV14 captures have not been claimed as passed. No duplicate test, export or publication was performed by this critic. Clipping, ordinary-speed motion and equipment reentry still await the actual rendered evidence.
