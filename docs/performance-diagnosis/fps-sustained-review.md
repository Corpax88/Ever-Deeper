# Sustained native workload evidence

All six runs passed the strict 180-second workload gate. Mining fixtures record actual mining and movement in every complete ten-second window; the completed Hub records actual walking. No runtime ERROR lines occurred. These are native software-renderer measurements at 2328×1260, not browser or physical iPhone certification.

| Scenario | DEV2 FPS | DEV3 FPS | DEV2 p95 ms | DEV3 p95 ms |
|---|---:|---:|---:|---:|
| Progressed Ember | 9.79 | 17.34 | 136.4 | 76.2 |
| Completed Hub | 14.67 | 17.79 | 78.7 | 68.1 |
| Post-fifth-relic The Deep | 7.70 | 11.53 | 154.6 | 105.7 |

Ember uses the progressed pickaxe-5 loadout. Both original gates start intact and are opened through ordinary held mining; no terrain is replaced and no measured movement is teleported. The route planner searches for naturally existing mineable blocks. This is a different progression stage from the earlier pickaxe-4 fixture.

Hub causality is uncertain: the DEV2 run had a large transient during approximately 40–73 seconds, including a 3115 ms frame, then recovered to ordinary rates overlapping DEV3. The aggregate difference must not be attributed wholly to the code. The Ember candidate improved p95/p99 but its single worst frame increased from 188.8 to 233.1 ms; all raw outliers are retained.

Identical seed, loadout and policy do not guarantee identical state at equal wall-clock times. Actual mining, movement, depth and memory counters are included. Static-memory growth includes retained raw samples and snapshots. TIME_PROCESS is not exclusive script CPU. Dummy audio does not verify sound quality.

report.json contains compact metrics and portable raw-summary paths. The raw archive contains every frame/window record, initial/final saves and logs. PNG bytes are excluded; its manifest retains their paths, sizes and SHA256 identities. manifest.json hashes every included file; packages are identified by SHA256 and are not copied into this archive. Superseded workload failures are archived separately and are not aggregated as accepted evidence.

Candidate runtime source: `42fffc163c940db2ab9df2e1924608e2d1659793`. The diagnostic driver was revised externally and tested against this unchanged PCK; copying it into the repository afterward does not change the tested runtime source.

To reproduce, obtain the exact PCK and Godot 4.7.2 binary, create an empty project directory and isolated output directory, then run python3 driver/run_rendered_isolated.py with --project EMPTY --godot GODOT --xvfb XVFB --output OUTPUT --resolution 2328x1260 --timeout 270. Pass Godot --main-pack PCK --script /absolute/driver/review_sustained_mining_progressed.gd, followed by user arguments --output=/absolute/OUTPUT --fixture=ember_d1|hub|deep_post5 --duration=180 --pack-source=/absolute/PCK. Use spaces between named options and their values as required by the Python runner.

Repository records: [raw accepted records](fps-sustained-evidence.zip), [compact results](fps-sustained-results.json), [separate failed fixtures](fps-sustained-failed-fixtures.zip), and [artifact hashes](fps-sustained-receipt.json).
