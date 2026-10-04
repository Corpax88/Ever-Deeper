# Running achievements repair

Quick Step and Roadrunner were obtainable only through removed Wayfarer speed-upgrade shops. Fresh players could not earn those two entries.

The same achievement IDs now unlock at earned Running levels 1 and 10, respectively. Legacy movement-speed purchase levels still qualify, and existing achievement records/timestamps are retained. Level-up events trigger the existing batched evaluation so a player does not need an unrelated resource change to receive the achievement. Only the two corresponding authored descriptions change in the display array and matching by-ID index; art, tiers, record schema, namespace and every other game-data field are unchanged. `source_manifest.json` updates only `game_data_sha256` to the new exact data hash; the startup integrity assertion and all source/count metadata remain intact.

Focused regression: `tools/review_running_achievements.gd`. It earns XP through the real training method, tests both threshold boundaries and automatic level-up notification, verifies no retired purchases are required, reloads preserved old timestamps and checks old purchase eligibility. Run with a disposable `XDG_DATA_HOME`; it writes achievement records only in that isolated directory. Runtime verification is pending the exact candidate test.
