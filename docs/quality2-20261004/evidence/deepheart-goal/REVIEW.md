# Deepheart action text — scoped acceptance

The visible action now describes the current task inside Deepheart: **Hold MINE · open the seal**, then **Attune the core**. Before entering, or after returning to the Hub, it retains **Deepheart passage · Hub**. Canonical objectives and guide destinations are unchanged.

`ProgressionGoal.action_for_phase` supplies one text owner. State-driven HUD refreshes use `RunState.current_scene`; `main._progression_goal` supplies the active phase during the interval before a travel checkpoint is written. The explicit Treasury pin and started discovery activity retain their existing priority. No progression transaction, reward, balance, asset or save format changed.

The focused native probe passed **33/33** checks. It covers all four seal objectives and routes, core readiness, direct HUD refresh, phase changes before location persistence, first entry, Hub return/re-entry, ordinary progression and canonical victory. The reference mode reproduced the old text against the exact source53fa6ed candidate; its successful result means reproduction, not acceptance of that text. Seals are advanced through their canonical state operation; the separate Mac journey remains the real held-mining evidence.

All six native1334×750 captures were visually inspected at the intended667-wide presentation. The seal action is260logicalpx within316px, and the core action161px within316px. Text fits without clipping; the core no longer tells the player to visit the Hub. Existing chamber art, light and hero are preserved. This is Linux native rendering, not physical-iPhone acceptance.

| State | Before | After |
|---|---|---|
| First seal | `before/seal-mossvein-667.png` | `after/seal-mossvein-667.png` |
| Last seal | `before/seal-starfall-667.png` | `after/seal-starfall-667.png` |
| Ready core | `before/core-ready-667.png` | `after/core-ready-667.png` |

The six PNG originals remain under `/workspace/scratch/72d2364e7fd1/deepheart-goal-review/`, using the relative names above. `manifest.json` records each image's filename, verified absolute original path and SHA256. Documentation retains only text; duplicate PNGs were removed after verifying all originals. Final integrated images will be retained in the CI artifacts.

Exact source/package/image hashes, runtime, fixtures and results are in `manifest.json`, `overlay-receipt.json` and each `report.json`. The overlay includes root's concurrent context-layout/notice additions in main and its required PremiumHUD owner; these do not relocate Deepheart controls. Before package: `81e6b222db8db7f15387965d27846e3da72bcb92da0e9ac876c3caec7b7a2860`. After: `504877f37dfa4db3e93cf09746dc2b3442db0aac3ac83beb1c6f60f37badb340`.

Reproduce with `tools/review_deepheart_goal.gd`, an isolated `MODS_OUT` directory and the documented graphical wrapper. Candidate completion marker is `DEEPHEART_GOAL_OK`. Reference mode adds `--reference` after the engine argument separator and uses `DEEPHEART_GOAL_REFERENCE_REPRODUCED`. An explicit `--goal-assertions-only` option permits headless execution while retaining all state/route checks and skipping only image capture; it was not used for this visual acceptance.
