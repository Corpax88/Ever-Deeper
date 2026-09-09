# Independent critic — improvement round 1 of at most 4

Date: 2026-09-09. This is a development review, not 1.0 approval.
Reviewed the integrated working tree based on commit
`3a6ddd7d8cf0678d92756cb2c3d53c14c4d1826a`. Final exported-package inspection
remains a separate gate. Scores reflect observed evidence only.

| Category | Score / 10 | Evidence and limit |
|---|---:|---|
| Gameplay loop | 8 | Real held mining and player collision cross streamed geology without shaft actions. All five generated relics are recovered, placed and built; real mining continues beyond the fifth. Long-form pacing and final rendered feel remain untested. |
| Progression feel | 8 | Real paid campaign transactions reach Deepheart; live resource requirements agree with state, including pending sale value and delivered materials. Tool speed-cap defect is corrected, with strictly faster observed runtime cadence at each level. Rendered strength feedback and pacing remain unverified. |
| UX | 8 | Same-signal rendered counters, clear pickaxe resource, canceled mining touch, menu isolation and repeat Tunnel Home requests pass. Native mobile presentation is not yet inspected. |
| Visual premium | Unverified | Approved hero/wardrobe assets are retained. Source and headless tests cannot establish visual fidelity. Final candidate PNGs/motion must be inspected. |
| Performance | Unverified | Active terrain is bounded to three bands / 2640 cells. Last physical iPhone evidence remains DEV9 52.1 FPS, not stable 60. No numeric score is assigned to an unmeasured candidate. |
| Code quality | 8 | Deterministic geometry and compact per-band journals have clear owners; real transaction, migration and integrity gates exist. Large world/state scripts and compatibility paths still need final package regression coverage. |

No overall 9/10 or final 1.0 approval is justified yet.

## Defects identified and corrections

1. **Legacy active-save depth loss:** a legacy depth-3 local y-coordinate was
   restored into band 2 of the new window. Corrected in RunState location
   migration; the test now restores the actual scene before checking band 3.
2. **Carried relic save depth clamp:** transporting a relic deeper than its
   discovery band was clamped back on reload. Corrected transport sanitation.
3. **Detached relic relocation:** normalizing a detached relic silently moved
   its saved transport depth back to the discovery band. Corrected; rejected
   Tunnel Home now preserves the actual location and cargo.
4. **Invisible paid speed gains:** Comet's Deepcore cycle hit the minimum clamp
   before every Tool Forge speed upgrade; later Prospector levels did likewise.
   Corrected by clamping the authored base cycle before applying upgrade speed.
   The core runtime probe verifies strict improvements at levels 0–5:
   Crusher 0.680→0.425 s; Comet 0.240→0.150 s; Crown 0.28336→0.1771 s.
5. **Goal/minimap collision:** preliminary rendered Hub inspection showed the
   new goal covering the existing map. Both now consume one responsive layout;
   the map preserves its dimensions immediately to the left of the goal.
6. **Largest recipe covers context action:** the actual Deepcore recipe has
   four materials plus gold, not four total rows. At project content scale 1.1
   its fifth row overlapped the iPhone context button. The largest mobile
   recipe now omits only the action subtitle, preserving title and all full-size
   resource rows. Independent actual-control geometry passes for both four-
   and five-row recipes at 844×390 and 956×440. Final PNG legibility is pending.

The generation owner also corrected a resource-identity risk: replaying dug
terrain must not change the original ore placement candidate list. Real reentry
checks now retain remaining node IDs, positions, kinds and amounts.

## Passed evidence

| Gate | Checks / result | Evidence |
|---|---|---|
| Fresh paid progression | 240, passed | `qa-results/one-point-zero-state/` |
| Five-relic continuous world | 515, passed | `qa-results/one-point-zero-round1-fixed/one-point-zero-world.log` |
| Legacy active and completed saves | 260, passed | `qa-results/one-point-zero-round1-fixed/one-point-zero-migration.log` |
| Live HUD, cost, touch and maximum-recipe geometry | 357, passed | `qa-results/one-point-zero-ui-geometry/one-point-zero-ui.log` |
| Existing overhaul | 859, passed | `qa-results/one-point-zero-round1-fixed/overhaul.log` |
| Existing touch and endgame | Passed | `qa-results/one-point-zero-round1/` |
| Input, onboarding, layout, portrait, developer tools, Crusher | Passed | `qa-results/one-point-zero-current-gates/` |

World coverage includes generated deposits and cache rune activity, exact
one-claim accounting, remaining-node identity after regeneration, finite rope,
physical pedestal distance, 199+1 workshop costs, no duplicate build, absolute
position/cargo/complete-Hub restoration and continued real mining past band 12.
Material fixtures accelerate gathering time; these are not human pacing tests.

The final integrated source pass at this round's close passed **all 13 active
cases** in one invocation. Results: `qa-results/one-point-zero-source-final/`.
No known critical gameplay/save defect remains in the exercised paths. The
default `tools/qa.py` gate now selects these 13 cases; historical `endless`
remains explicitly callable. The frozen exported package still requires its own
complete run and visual inspection.
The targeted UI case was rerun after the two observed layout corrections,
passing 357 checks. This post-source-pass addition checks real PanelContainer
children and the live map rectangle, not just proposed layout metrics.

## Intentional legacy contract changes

- The visual driver still checks an exact version; the expected version changes
  from 0.46.9 to the actual 1.0 candidate. Version mismatches remain failures.
- Endgame retains all campaign assertions. Its single clear-walking connectivity
  predicate is replaced by BFS through actual floor and ordinary mineable rock,
  requiring a safe spawn and reachability of every generated ore, site and relic.
  Permanent rock is excluded. Real held-mining traversal separately verifies it.
- Overhaul retains pre-contact, impact, eventual break, save/reentry, resource
  identity and protected bedrock checks. Its fixed three-strike wall assertion is
  intentionally replaced by actual upgraded tool damage. Chunk-local save
  indices and absolute coordinates replace old single-floor indices.
- Resource identity means ID, kind, amount and absolute cell. Mutable HP and
  depletion can legitimately change when Crusher hits nearby deposits; deposit
  duplication and reentry depletion are checked separately by the new suite.
- The original `endless` suite remains available unchanged as historical
  floor/elevator coverage. Its whole-floor exhaustion, shaft contexts, free
  walking route and fifth-shop-only checkpoint no longer describe 1.0. The
  new world/migration suites retain its applicable resource, cache, rope,
  workshop and save protections.

## Remaining acceptance work

Run the frozen candidate's exact-package gate, inspect it at mobile resolution
and judge motion/audio.
Obtain stable sustained physical iPhone evidence before approving 1.0. DEV
candidate testing and final LIVE/1.0 acceptance must remain distinct decisions.
