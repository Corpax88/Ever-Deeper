# The Deep: 1.0 implementation handoff

Status: implemented on the shared DEV branch; no publishing or commits performed by this agent. Native parsing and targeted gameplay checks pass. Visual review, the complete journey suite, and physical iPhone acceptance remain release gates.

## Runtime contract

- `EndlessDescentWorld` keeps `load_depth`, `configured_depth`, resource/relic signals, and the physical rope. Depth IDs now identify internal geology bands, never player-selected floors.
- Walking/mining across a band automatically updates RunState and rebases a three-band local window. Normal play exposes no shaft buttons or `depth_change_requested` transitions.
- `world_rebased(offset)` fires after terrain, player, camera motion cache, view compensation, rope points, previous rope positions, carried relic, and impact positions have moved together. Main translates the companion via this signal.
- `depth_metres()` and `deepest_metres()` expose continuous distance. `stream_snapshot()` gives bounds and origin-shift diagnostics. `save_stream_position()` records exact local position/window for normal checkpoints.
- `prepare_tunnel_home()` stores the exact window/position and returns `RunState.tunnel_home_endless_descent()` result (`ok`, `carried_relic_id`). The attached relic remains carried for the existing physical hub placement.
- On return, `load_depth()` recognizes the saved anchor and restores the same dig site. Tunnel Workshop reduces the existing Tunnel Home preparation from 1.25 seconds to 0.45 seconds.

## Mountain and persistence

`endless_deep_layout.gd` generates seeded natural rooms, branches, mineral deposits, and wavy ordinary-rock bands. Digging is necessary to advance, and all interior rock is mineable; only the outer mountain sides and its top boundary are permanent bedrock. Neighboring storage bands share deterministic passage coordinates. There are always three active bands, 40 by 66 cells (2,640 cells), with bounded node/site/hazard lists and four short Crusher effects.

`endless_terrain_state.gd` records 880 excavation bits per changed band as 220 hex characters, plus vein, cache, and discovery masks. Generated terrain never goes into saves. The sparse persistent journal grows with places actually changed; active geometry and visual work stay bounded. Leaving an area preserves each unmined vein instead of exhausting the entire floor. Atomic `claim_endless_resource_node` and `claim_endless_rock_cell` transactions reject replayed claims, including stale in-memory visuals, before awarding materials.

Vein placement uses immutable generated geometry before excavations are replayed, so mining cannot reshuffle deposits. Resource claims carry their actual band ID even across a visible seam. Ore embedded in rock uses the existing approved node artwork and gives deterministic material rewards; depth increases yields and rarer finds. After the fifth relic, material mining and depth records continue indefinitely within practical integer limits.

Existing schema-2 saves remain accepted. Active old vein/cache masks and old per-floor excavation coordinates survive. A legacy local player position is explicitly embedded in the correct band of the new window, avoiding silent depth regression. Carried relic transport may move either direction and remains consistent after save/load. Detached rope state and its saved endpoint survive reload; the same physical relic offers ATTACH ROPE without being collected or rewarded again.

The five relic IDs, milestone bands `[1, 3, 5, 8, 12]`, workshop IDs, 200-material construction costs, and purchase authority remain intact. `lift_workshop` is retained internally for compatibility and displayed as Tunnel Workshop.

## Physical upgrade effects

- Tool Forge: power `1 + 0.35 × level`; swing speed `1 + 0.12 × level`; mining reach `1 + 0.10 × level`.
- Ordinary Deep rock has 520 HP. An unattuned Deepcore Drill takes two strikes; Forge level 1 reduces this to one. Node HP is 950–1,022, preserving meaningful equipment differences.
- Crusher preserves the existing 5×5 footprint, with 72% adjacent and 48% outer splash power. Rewards are batched and existing CrusherDebris handles feedback. Comet retains its speed and Crown doubles rewards.
- Treasure Chamber adds 72 pixels to the existing pickup radius and retains its 25% cache-yield bonus.
- Light Lab preserves approved light formulas (8% range and 6% energy per level).
- `RunState.workshop_effects_at_level()` is the shared preview authority, including `tunnel_duration`.

## Verification completed

- Godot 4.7.2 editor import: no parse/script errors.
- Shared `--qa-one-point-zero-state`: 240 checks, zero failures at the first integration checkpoint.
- Targeted real world probe: walking 20 pixels across depth 2→3 preserved exact absolute displacement and rebased window 1→2. Headless CPU generation measured 4.1–4.6 ms in this environment, not a device FPS result.
- Targeted persistence probe: excavation followed by regeneration left all vein positions unchanged; active cells remained 2,640; Tunnel Home → serialize/deserialize → resume restored the exact dig position.
- Duplicate/stale-node probe: an already-claimed node struck from stale runtime data grants no additional materials.
- Detached relic probe: save/reload retains detached state and endpoint, then the normal ATTACH ROPE interaction succeeds without duplicate collection.
- Forge cadence probe, every level 0–5 strictly improves real timing: Crusher 0.680→0.425s; Comet 0.240→0.150s; Crown 0.28336→0.1771s. Authored cycle bounds are applied before upgrade speed, avoiding a false speed preview on already-fast equipment.
- `git diff --check` passed for owned runtime files.

The unchanged legacy endless suite expects shaft contexts, free connected routes, whole-floor exhaustion and lift checkpoints. Those expectations conflict with the authorized 1.0 design; they have not been weakened. The independent QA agent owns replacement journey/stream/migration evidence and final scores.
