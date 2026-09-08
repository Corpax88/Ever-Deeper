# All pet skills: sustained FPS investigation

The native tests found and reproduced a Teamwork bug in the hub, but did not reproduce the user's delayed iPhone FPS collapse. Do not call the phone issue solved.

## Reproduced bug and fix

With Teamwork learned, MoleCompanion._think converted world.get("external_mine_held") using bool(). HubWorld has no such property; bool(null) throws. The unmodified runtime failed every think step in the hub when Teamwork was learned. In the dedicated off/on/restored-off test, errors were 0 / 342 / 0 over the three 105-second trials. This begins immediately, rather than specifically at 30 seconds.

The fix checks that the world supports companion digging before reading mining state and safely compares the optional value with true. All 22 corrected matrix jobs finished without script errors, including Teamwork-on hub. The native Teamwork hub FPS was 20.56 / 20.47 / 20.55 off/on/restored, so there is no material skill FPS penalty in this corrected fixture.

The clean fix is [draft PR 10](https://github.com/Corpax88/Ever-Deeper/pull/10). It is not deployed. Main and DEV remain unchanged by this investigation.

## Method and limits

- Ten skills plus all-skills, each in developed hub and Mossvein Depth 2: 22 jobs, three states each, 66 trials.
- Every trial: 60 wall-clock seconds idle, then 45 seconds of exercised behavior. Five-second buckets include wall FPS, p95/p99/max, simulated seconds, node/object/memory/draw counters, and pet physics/think/path/loot/ore CPU timing.
- Other skills remain learned when isolating a target. The all case toggles all skills together. Lantern and Fetch are built in and have no purchase-level off switch: the QA controls hide only the pet lamp and bypass only automatic fetch decisions respectively.
- Native Linux llvmpipe at asserted 844x390, Dummy audio, normal save/checkpoint behavior, isolated disposable saves, Light Lab and Wardrobe level 4. This is not physical iPhone or Safari GPU testing. Do not compare raw FPS between runners.
- Idle simulated time exceeded 60 seconds in every corrected matrix trial; these tests genuinely crossed the 30-second simulation threshold as well as the wall-clock threshold.
- Hub lacks loot/dig/ore/guide APIs. Skills remain learned there, but unsupported actions are reported as unavailable; they are not claimed to have executed successfully.
- The active all-skills sequence intentionally changes commands and, for Ore Nose, the chamber/view. Its early/late ratio is not a stationary-scene time test.
- Ore Nose active testing exposes a real ungated deposit in a disposable 7x7 chamber. Passive scans use the original scene. The initial run lacked a sniffable target, which is recorded rather than counted as successful active coverage.
- Active digging required a separate coverage follow-up: command acceptance alone was insufficient. See the follow-up result below.

## Findings

No large delayed collapse appeared in the 60-second idle traces. Corrected idle late/early FPS ratios ranged about 0.978–1.044 across all states. This is inconsistent with reproducing the user's roughly 50-to-14 FPS fall on these runners, but cannot exclude a physical-device or browser-specific issue.

Pet lighting has a sustained rendering cost. In the corrected hub Lantern test, off/on/restored FPS was 20.45 / 15.51 / 20.24, roughly a 24% loss while lit. The hub Long Beam test was 18.51 / 17.33 / 18.69, roughly a 7% loss with the longer beam. Mossvein Lantern was 16.56 / 11.91 / 16.44. These are steady costs, not observed delayed cliffs. Mossvein Long Beam has enough between-trial variation that this run does not isolate a reliable effect size there.

The other skills did not reproduce a stationary delayed FPS collapse. Pet CPU costs in the corrected idle runs were only a few milliseconds per wall-clock second. No runaway path search was observed in these particular fixtures. This does not test every possible map position or obstructed route.

## Evidence

- Baseline QA source: d4545834b949c388f2471d70b0fcd07f095a5449; [run 34195825731](https://github.com/Corpax88/Ever-Deeper/actions/runs/34195825731). 11 hub jobs correctly fail on the runtime error. The first Mossvein Fetch job failed downloading Godot; the corrected matrix covers it successfully. Raw baseline contains 21 completed reports.
- Corrected QA source: f5c14c19eb13efd60e63b3bd07a8ef00580427f6; [run 34196562560](https://github.com/Corpax88/Ever-Deeper/actions/runs/34196562560), all 22 jobs completed without script errors.
- Clean fix source: b63451366a153f6eb211385bb4bae14478726a22; [run 34196683167](https://github.com/Corpax88/Ever-Deeper/actions/runs/34196683167), all ten current gameplay cases pass; invariants: 1,139 protected files, 51 QA entries.
- [Full FPS table](summary.md), [machine-readable summary](summary.json), [corrected error counts](after-error-counts.json), [baseline error counts](before-error-counts.json).
- before-hub.json.gz, before-mossvein.json.gz, after-hub.json.gz and after-mossvein.json.gz preserve the complete JSON reports compressed with gzip. Load with Python json.load(gzip.open(path)). These include all five-second buckets; Actions artifacts also retain logs and screenshots.

## Active digging follow-up

[Run 34197279497](https://github.com/Corpax88/Ever-Deeper/actions/runs/34197279497) passed both jobs with zero script errors. Earthshaker dug 0 / 15 / 0 tiles off/on/restored; Teamwork dug 0 / 1 / 0. Active on-state late/early FPS ratios were 0.995 and 0.997 respectively. The final summary table substitutes these two validated runs for the original two incomplete active fixtures. Complete follow-up reports are in active-dig.json.gz. The QA fixture requires actual dug-count growth to pass. The Teamwork fixture keeps the player's swing pending so the pet gets an opportunity to land its own assist; this fixture adjustment is not a production change.
