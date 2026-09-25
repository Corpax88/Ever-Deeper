Latest total-package result:676e122/run36116139795 completed. Both48checks/12windows;45.000→47.513FPS(+5.58%),34.335→38.402(+11.85%). Strongdrift, worker1slowframes205→259 and321mscandidateoutlier; no consistentstutterfix/phoneclaim. See ../integrated-perf/HANDOFF.md.

# Integrated CPU/native candidate — correctness passed, full FPS comparison pending

2026-09-25. Current source981dfb6dbc361c54c7e1fbc799cbc5a886d0d597, run36115911966 completed all six core cases and native/ordinary browser gates. Public DEV15.9 remains c63aabd. No physical phone claim or release acceptance.

Production code is identical to94f3302051b6f8662c3606a3695697094795b5c4/run36115344347;981 only preserves the dev14_review QA inheritance path in the pack.94f3302 retained evidence: native artifact10854598922 (192820372bytes), startup10854349631 (14509148bytes), both exact byte-size and ZIP-verified. Native184checks,26 exact full-image pairs,42PNG covered by16 independently viewed SHA-identical image groups;61 inventories checked. Automatic3 synchronization pairs before any QA override,8 in-place tool changes retain generation8 and incrementupdates; drill reentry/world transitions/pause/resume pass. Startup is observation, not a report with a passed field:51 context samples, two expected navigations, all6 actual images independently inspected, saved game/new-game confirmation/gameplay visible, no recorded errors or context loss.

Packing recovery: firstd1a01e9 failed compiled native dependency alias.86ae743 remapping unchanged player_visual only moved error to its callers.94f3302 retains raw native source at canonical path with self-remap (engine4.7.2 resource path mapping is single pass), removes unnecessary player_visual change; all core/browser gates pass. Whole-package FPS first9dd26bf/run36115604760 exposed the same alias problem for inherited dev14_review.981 retains that canonical QA path too. Original resource bytes and engine/assets stay unchanged except explicitly replaced remap entries and appended sources.

Valid whole-package comparison676e122/run36116139795 in progress: exact original export, without revision bookkeeping, versus981 candidate. Two Mac Apple/WebKit workers, balanced ABBA/BAAB fresh contexts,30s held-mining warmup +3x15s windows/block, original4/candidate3 sync pairs. Windows in blocks correlated; per-call wrappers have equal cost but candidate has fewer calls. No UI consolidation; no GPU-time claim. Preserve all drift/caps/outliers, interpret block aggregates and inspect end images.

Native-startup-independent-review.json binds94f3302 evidence only. A later successful workflow is not permission to relabel earlier screenshots. No publication/phone retest yet.

## Earlier recovery checkpoint (historical)

# Integrated CPU/native candidate — validation in progress, not public

2026-09-25. Combines the retained production occupancy-revision patch with guarded native empty2D-canvas removal. No UI consolidation. All original engine/assets/resources kept; explicit script-remap append only, original resource digest checks required. Version remainsDEV15.9 because this is an isolated validation package, not a release.

First source d1a01e9c167f380edeac91a6353f5e36d98426b1/run36114467481 passed pack verification (1391 original resources untouched) but all six core cases stopped on a preload resolution error in original player_visual.gdc: native_worn_visual_integrated.gd could not resolve. No browser gate ran. Candidate10854755588; build10854440920,4105bytes verified ZIP. Direct targeted check-only of that appended native script, source2acbee61/run36114710011, emitted no parse error. Do not claim this proves the helper alone caused or solved the loading error.

Bounded recovery86ae743f6e0930be33ae55e1a936cedfa16c4855 remaps only the immediate preload owner player_visual.gd to its unmodified raw source. This source was fetched from original export c63aabd3e3e5120579285ce6e8b0b59a75f2727a and compared byte-for-byte with the candidate source: identical13834characters. Existing compiled bytecode/resources remain preserved. If failure moves, follow the concrete dependency; avoid blind blanket rewriting.

Native lifecycle gate observes automatic production counts before any QA flag override and requires3 synchronization pairs per rendered frame. Explicit frozen reference/candidate/restored pairs require exact images and4/3/4 pairs across eight tools and worlds. Additional in-place gear sequence verifies unchanged generation and increasing update count; drill-to-worn, pause/resume and inactive-world ownership are tested. Six core cases and ordinary WebKit startup/save are required. No physical phone acceptance or published change.
