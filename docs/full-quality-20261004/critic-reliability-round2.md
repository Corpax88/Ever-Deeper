# Reliability critic — round 2

## Result and scope

The confirmed write-loss and cross-expedition state faults now have focused runtime evidence. Six native probes pass 118 assertions in isolated save roots. The exact final integrated package, actual four-skin Ricochet browser lifecycle and physical-device performance remain separate acceptance gates. A 9.5/10 score for the whole game is not supported by this evidence alone.

Provisional scoped reliability/code rating: **9.0/10**, improved from the initial 7.5/10. This is an implementation-side review, not a substitute for independent final package acceptance.

| Verified behavior | Native assertions | Package scope |
|---|---:|---|
| Failed expedition writes remain dirty; retry succeeds without another mutation; stale timers cannot consume a later run's dirty state | 33 | Exact candidate1 `4fca6f8`; PCK `6ae03b7870593a88b3f15d77a5d6cb615ea36942b2b22445db5f8514d0cc96b7` |
| Actual new-game/menu write errors cannot advertise a committed save; automatic recovery clears the error | 11 | Same exact candidate1 |
| Real DEV command, earned podium, pause/release/travel and New Game tool lifecycle | 10 | Same exact candidate1; no rendered appearance claim |
| Actual Running 1/10 events unlock the formerly unavailable achievements; old timestamps/purchases remain compatible | 11 | Exact DEV15.54 plus achievement service, four description leaves and matching source-manifest hash |
| Lifetime achievement temporary-write faults, automatic retry, stale callback, corrupt-primary fallback and repair | 23 | Final quiet-parser overlay; PCK `1771603f9504d3a62af3fec570bccfb7fb529a6af8812029bea9e2acad611d12` |
| Real worm boost persists during ordinary pause/travel but New Game clears tasks, cooldowns, counters and worms in all six loaded companions | 30 | Exact candidate1 plus three companion owners and only the New Game hook; PCK `15038153c35dbec5dca1a948272c35fd49456ce167ef99d8eeb5d0d981f8b4e3` |

Reports and exact overlay receipts are retained under `reliability-native-evidence/`. The achievement recovery log is clean even for deliberately truncated JSON. The companion probe explicitly confirms the ordinary menu actually opened; automated startup mode would otherwise suppress that route.

## Additional confirmed lifecycle fault

The original candidate1 consumed a real worm, opened the menu and started New Game. The new world seed retained **19.983 seconds** of the old twenty-second speed boost. The same reused companion nodes also retained cooldown/task/counter state. The new explicit reset API addresses that boundary, without resetting on ordinary travel or pause. Lifetime achievement timestamps and audio preferences are verified unchanged.

## Further read-only audit

- Expedition records retain bounded binary length checks, SHA-256 validation and previous-good-generation recovery. Unsupported dictionary imports reject before clearing active state.
- Treasury resource debit and credit share one synchronous authority; delayed presentation does not own the balance mutation.
- The terrain journal retains excavation and claim masks. Loose-drop identity is separate from pickup presentation, so reload recovery does not rely on transient sprites.
- Inactive native hero rigs suspend their viewport and release the rig. The shared fallback gear loader drains owned asynchronous requests at main-scene shutdown. No resource-lifecycle optimization is proposed without a measured fault.
- Exact-package assembly verifies retained resource payloads. This demonstrates asset preservation, not frame-time or visual-quality acceptance.

## Remaining acceptance limits

The earlier 337 Ricochet checks are not four-skin evidence: their own snapshots all reported `original`, because the fixture failed to establish appearance prerequisites and ignored the selection return. The corrected fixture requires a genuinely built/upgraded Tool Forge, accepted selection and matching saved skin for every case.

The corrected Mac Apple Metal run now passes **275 assertions with 42 captures**, source `911962378a803fa8e2058a5bf1c07b05426ae42d`, QA PCK `223867028acb48a904ad405348199e0dd86d332d23c3befa19fd5538485a55d2`. Six representative frames and their state documents were inspected. The Comet and Deepheart turn frames show the braced Ricochet, with both the fallback sprite and old native pickaxe hidden; earned reload reports saved Deepheart/Ricochet, and unequip reports restored `ember` gear. Travel/reload/unequip frames clip the hero at the top boundary (player y approximately25), so those frames cannot certify the final restored appearance. QA has been asked to capture an interior saved position while preserving this boundary observation. This is verified state persistence plus partial visual acceptance, not a claim to have reproduced/fixed every form of the user's complaint.

Lifetime achievement failures now retry and retain a good generation, but their dedicated error field does not feed the expedition save-status hint. The new warning/recovery UI is tested for RunState writes. Neither mechanism can recover both generations being removed or a browser origin being evicted.

No physical-phone smoothness or sustained FPS claim is made. Existing historical source-gate debt remains distinct from current focused regressions; accepted new gates must not be described as a pass of every legacy test.
