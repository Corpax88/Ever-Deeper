# DEV15.15 compact skill level notifications

User requested a visible but unobtrusive level-up notification, similar in purpose to Valheim. Reuse the approved Skills icons/font, do not cover the hero or interrupt input. Target DEV only; preserve LIVE1.0.1. User visually approved DEV15.14 hero mining animation on 28 September; retain it unchanged.

Implementation source on `codex/skill-level-up-20260928`:
- `scripts/state/run_state.gd`: emit `miner_skill_increased(id, level)` only when earned XP crosses the next cumulative threshold, emitting the highest new level once for multi-level awards. No event from deserialize/reset. The existing level cache is retained below the next threshold instead of erased every movement tick; thresholds use the existing progression sum, 25*n*(n+3). XP amounts, cap, saves and rewards are unchanged.
- `scripts/ui/skill_level_toast.gd`: existing skill SVG/font, small upper-centre transparent notice below occupied HUD controls, 0.3s fade-in / 2.1s hold / 0.6s fade-out. Noninteractive controls only. Different skills queue; repeat increases in one skill coalesce to latest level. Menus hide and pause the notice. Reset/load clears pending notices. Processing is disabled while idle.
- `scripts/ui/achievement_toast.gd`: install the new notice alongside the existing achievement UI. Existing achievements unchanged.

Build uses exact approved `hero-candidate`, run36355460990/artifact10944315256/source4811f56ca5b524980cebe4ded68f3bcfe2389488. Validates all baseline file hashes and every PCK resource digest, retains hero motion, audio fix, graphics preferences and all other assets. Explicit raw remaps include unchanged main source to resolve its preload. Version becomes1.0.0-dev.15.15. Main remains a publication carrier, not canonical game source.

Targeted Mac WebKit check uses actual held mining to cross level1 and verifies impacts continue during the visible notice. It then checks timed dismissal, simultaneous skill merging/queue, menu hide/resume, skill icon loading, load suppression and one highest-level event at cap100. Captures all four skills and level100 in the real game. No broad FPS suite or physical-iPhone claim. Evidence and publication results follow after review.

Initial source3b717a0a2b4bcf95b7ffa6a31dca74b53dacc81d/run36376278461 passed event/input lifecycle checks, but the screenshot revealed overlap with the gold counter. It was not published. Source08af3b8526b88ba2764fa36860d52d7e0eba5bbe uses the live HUD layout rectangles to place the notice just below occupied top controls; layout is recalculated only on a new notice or viewport resize. The focused check also asserts no HUD rectangle overlap.

Accepted candidate: source08af3b8526b88ba2764fa36860d52d7e0eba5bbe, validation36376489306, artifact10950299830. All eight focused scenarios passed with no runtime error. Five actual game captures inspected (four skills plus level100); HUD clearance confirmed. Publish workflow pins candidate digest and manifest, preserves all LIVE/Worn bytes and verifies all27 public files.
