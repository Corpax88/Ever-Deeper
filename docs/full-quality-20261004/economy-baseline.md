# Authored economy baseline — 4 October 2026

Read current tracked `data/ever_deeper_v0381.json` via `git show HEAD:...` because the working checkout is sparse. SHA-256 `40dd813648ad30a6e69711af4929b5361ed9e151b438e09ee61f129758d20d51`. Confirm package identity before balance changes.

## Treasury material supply

The established target stays **100,000**. Depth 2 `_break_rock` yields `(1 + Bernoulli(0.56)) × 2 + Bernoulli(0.5)` for Deepcore + Crownseeker + Prospecting 100: expected 3.62, maximum 5. Ordinary reusable source counts below exclude one-time pocket deposits; opened drill-gate seams retain renewable ore at the original count. One-time rewards provide a small initial offset.

| Mod material | Renewable sources | Respawn | Ideal expected hours for 100k | Maximum-luck supply hours |
|---|---:|---:|---:|---:|
| Rootiron / Twin Auger | 70 | 19s | 2.08 | 1.51 |
| Burrowsteel / Bore Rush | 20 | 24s | 9.21 | 6.67 |
| Prismite / Laser | 57 | 20s | 2.69 | 1.95 |
| Phase Crystal / Ricochet | 18 | 28s | 11.94 | 8.64 |
| Singularity / Vortex | 21 | 50s | 18.27 | 13.23 |

These are **idealized steady-state supply ceilings**, not playtest durations. Formula: `100000 × respawn / (node_count × yield × 3600)`. They assume every renewable source is broken at the instant it respawns, with no travel, aiming, mining, collection or return time. Actual play is slower. The Deep produces none of these five materials, so its strong mods and increasing node yields cannot relieve this grind.

Recommended design direction: add an earned post-Deepheart source for the *chosen tracked material*, using real buried deposits or a clearly signaled event with deterministic saved yields. Keep the 100k display/stack and early progression prices. Avoid globally multiplying pre-victory ore, which would erase intended tool and gate pacing. A resource-specific hunt needs clear source text and real timed tests before tuning quantities.

## Corebreaker at current endgame power

Deep nodes have 950–1022 HP. Deepcore base power is430; Forge level5 multiplies by2.75. Before Forge, Crusher's3.2 multiplier already produces1376 damage. Fully upgraded power is3784 for Crusher,1276 for Comet and1183 for Crownseeker: every node dies in one ordinary hit for every variant. Charging three seconds to strike that same node up to three times therefore adds no final-loadout benefit; this is broader than the earlier documented Crusher-only limitation.

Recommended narrow improvement: retain three piston strokes and the existing charge indicator, but let unused strokes continue through a short straight rock front after the original target dies. Each stroke should use normal power, respect walls/band limits, and preserve newly revealed ore until a later player attack. This makes Corebreaker a deliberate deep boring burst rather than duplicating Chainbreaker's screen-wide chain or increasing all node HP. Validate against actual Forge0/5 gear, save/rebase/release, and the approved visual motion before publication.
