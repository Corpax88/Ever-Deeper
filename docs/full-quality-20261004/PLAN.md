# Ever-Deeper full quality review — 4 October 2026

User mandate: review the whole game with a critic team, improve toward an overall 9.5/10, save progress after every logical change, and remove obsolete code where justified.

## Canonical base

Published DEV15.54 source `be3a698e0ad8bedb91e877b9932a7bb05b80684a`, `Corpax88/Ever-Deeper`. Main is a publication carrier, not current runtime. Immutable export: artifact11284088414, run37151451383. PCK327687342 bytes, SHA2567637ed10116bca208f841c11ea8d9359f4057b925fe2bc20bc1cda9ec267f56d. Work branch `codex/full-quality-20261004`.

## Review method

Independent gameplay/progression, mobile UX/art, and reliability/performance critics inspect source and actual current/candidate captures. A QA engineer restores broad graphical coverage. Root integrates, checkpoints and verifies each change. Changes preserve approved assets/hero and player saves. Runtime fixes and structural cleanup have separate commits. Only tested immutable candidate bytes can reach DEV.

Quality rubric: gameplay/controls25%, usability20%, progression/content15%, visual/audio15%, reliability15%, performance10%. A score is an evidence-based assessment, not a test counter or a promised rating. Unknown dimensions stay unknown; no critical bug may be hidden by averaging. A full9.5 claim requires broad play coverage, repeated independent review and real device evidence for phone performance. Simulator/Mac results do not establish physical iPhone results.

## Initial priorities

1. Restore actual graphical current-runtime probe and missing first-run/menu/world/map/treasury coverage.
2. Save reliability: dirty-state loss if disk write fails.
3. Mobile mod-card layout and real fullscreen expanded map.
4. Laser stamina accounting independent of presentation animation.
5. Visible goal source/action guidance on small screens.
6. Reconcile Ricochet complaint with actual tool state. Earlier idle/held/release/travel and moving-turn tests pass; scene-reload fixture remains inconclusive, not a reproduced gameplay defect.
7. Evaluate remaining progression/content, sound feedback, touch, saves, transitions and performance from real evidence.

## Persistence and delivery

Checkpoint each logical change on the work branch. Keep critic findings, changed-file/test mapping and remaining limits here. Update docs/TESTMILJO-HANDOFF.md at milestones; preserve LIVE and rollback packages. Standing GitHub and tested DEV authorization is already granted. Do not manufacture approval or final ratings.
