# Residual legacy cleanup — 17 September 2026

An independent audit traced runtime calls, string calls, signals, scene bindings,
save ownership and all 45 current achievement definitions. It found no reachable
legacy chest, belt or portable-base gameplay. The 44 previously recorded unused
asset deletions (22 PNGs and their import records) remain absent and unreferenced.
Echo coffers, relics, mineral caches, the five modern workshops, inventory,
trading and historical migration records remain legitimate current content.

This bounded follow-up removes two achievement conditions whose IDs are absent
from the current definitions, the uncalled private `_has_mobile_base_module`
helper, an unused surface interaction-radius constant, and the unreachable
`module:` hub-context label branch. The actual hub elevator, hoard, relic,
workshop and exit branches retain their behavior.

Five unused exported data keys are removed: `HUB_WORLD`, `HUB_GRID`,
`HUB_STATIONS`, `HUB_BUILD_COSTS` and `BASE_MODULE_INTERACT_RADIUS`. The audit also
checked GameData's variable-key reads; they do not address these keys. The source
manifest now lists the remaining 52 keys. All 45 achievement definitions and the
243 historical asset provenance records are retained. Save schema is unchanged.

Only the two deliberately edited data-file digests in `docs/unchanged-files.json`
are updated. All other protected baselines, including the known older
`player_visual.gd` mismatch, are retained. This is an explicit, reviewed removal
under Mats's cleanup instruction, not a weakening of the visual preservation gate.

New game-data SHA-256:
`40dd813648ad30a6e69711af4929b5361ed9e151b438e09ee61f129758d20d51`.
New source-manifest SHA-256:
`ec53a226c3296f510f54df5b5482c3024f023a4bcd8f683edd4935d405a52769`.

The existing world, migration and UI suites must pass on the resulting source
and exported candidate. At this checkpoint they have not yet been rerun after
these removals. The independent audit does not substitute for those gates.
