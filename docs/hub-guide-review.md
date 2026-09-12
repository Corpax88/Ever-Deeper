# DEV6 Hub guide author review

Runtime source: `d60922cb13a4ad521ef5d1721434574e097fdc7f`.
Validation run: `34716507336`. Candidate artifact: `10304559817`.
This is a bounded author review of the Hub guide correction, not an independent
critic assessment or final 1.0 approval. Provisional DEV readiness: 8/10.

## State and compatibility review

The Hub runtime snapshot was captured before `tutorialSeen` was set. A later
checkpoint or exit could restore the stale flag and reactivate `hub:first_visit`.
Successful entry now completes the visit in the same RunState transaction.
The one-time welcome still uses the pending state captured before entry.
Construction snapshots cannot erase completed visit or tutorial flags.

Older saves with a recorded visit recover their tutorial flag during normal
sanitization. Unvisited saves still receive the introduction, and a saved player
restored inside the Hub completes it. Normal reset clears the flags for a new
run. There is no save-schema, equipment, price, asset or lighting change.

Regression coverage drives actual main entry, checkpoint, exit and reentry;
checks the immediate first-drill goal; commits deliberately stale runtime state;
then reloads completed and previously stuck saves. It also checks that the
building tutorial stays complete and that equipment and gold survive recovery.

## Automated evidence

All six required jobs pass. Fourteen active cases pass for source and again for
the exact DEV package. Small WebKit checks pass 882 gameplay and 195 touch
assertions. Both audio browsers pass, with no script/console errors in their
reports. Hero motion validates twelve mining combinations. All 1,139 protected
files retain their expected identities. PR source check 34716785737 also passes.

Local headless runs encountered intermittent dummy-renderer null-texture errors;
unchanged isolated reruns passed. The remote full source and packaged checks
passed without that error. No test assertion was removed or weakened.

The exact candidate ZIP digest is
`e901952e02da251cd8cb571b1131520fce590f5cf34266df596d8dce70161e96`.
PCK SHA-256 is
`02e8d59d1c1f2ddf53de4128763559b59ec89aaabc78b41ba907720d32de37a0`.

## Visual review

The author inspected all six affected native captures at 844x390 and 2532x1170:
before Hub entry, after entry/checkpoint, and after exit. The first visit shows
its introduction; the next two states show Burrower Drill, Mossvein Depth 2,
Rootiron and Ambercore requirements. The surface arrow points toward Mossvein
after exit. Text and counters fit their panel without overlapping the minimap.
A supporting small WebKit first-mine image retains the normal mining HUD.

The native artifact reports 618 passing assertions and 56 journey captures;
seven companion captures and 75 light-receiver stages also pass. The original
raw report still says `visual_review_pending: true`; this subsequent author
inspection is recorded separately in review-index.json with seven image hashes.
Only those seven images are claimed visually inspected. Existing authored
materials and geometry remain intact; all protected asset hashes are unchanged.

## Scope and release

No critical issue has been reproduced in the tested paths. Accelerated fixtures
and software rendering do not verify human pacing or physical iPhone FPS. The
provisional score applies only to this bounded DEV correction, not the full game.
Known legacy QA failures remain documented in verification.md.

Mats explicitly authorized uploading the fix and publishing DEV after release
checks. Publication must use the reviewed immutable candidate, preserve all
nine LIVE 0.46.9 files, back up current DEV5 and verify all eighteen public files.
The baseline pins discovery-publication-receipt.json. No new LIVE release is
approved by this review.
