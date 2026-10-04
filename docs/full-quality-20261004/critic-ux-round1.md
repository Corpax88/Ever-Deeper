# Independent visual and mobile UX review — round 1

Date: 4 October 2026. Reviewer: `ux_visual_critic`. Assigned baseline: published DEV15.54, canonical source `be3a698e0ad8bedb91e877b9932a7bb05b80684a`.

## Verdict and evidence limits

**9.5/10 is not supported.** The actual inspected surface and equipment captures show strong authored world art and a distinctive dad/mole identity. The reusable navigation and mobile information architecture remain materially weaker. No whole-game numeric score is defensible until the missing screen families and ordinary progression have been rendered and used. This report does not turn previous narrow 8–9/10 acceptance into a whole-game rating.

Actual image inspection:

- `/workspace/scratch/6fe59966113d/baseline-evidence/ordinary/01-ordinary-menu.png`: fresh DEV15.54 menu.
- `/workspace/scratch/6fe59966113d/baseline-evidence/ordinary/02-after-new-game.png`: initial surface, HUD, objective, dad and mole.
- `/workspace/scratch/6fe59966113d/baseline-evidence/ordinary/05-new-game-confirmation.png`: replacement confirmation.
- `/workspace/scratch/6fe59966113d/baseline-evidence/contact.jpg`: sixteen Deep equipment/idle/hold/release/travel thumbnails. Useful composition coverage, not readable microcopy or animation evidence.
- The corresponding browser report identifies DEV15.54. Ordinary report states 844×390 CSS, DPR2, Apple GPU. This is Mac browser evidence, not a physical iPhone test.

Read: project rules at end of `AGENTS.md`, `README.md`, `docs/code-map.md`, approved mod-preview standard, map handoff, and named UI owners. Root source release-label literals are historically superseded by immutable packaging; the actual capture label owns the reviewed version.

## Highest-impact findings

| ID | Priority / confidence | Evidence and player consequence | Concrete correction | Acceptance evidence |
|---|---|---|---|---|
| UX-01 | P1, source-confirmed; fresh image pending | `scripts/ui/treasury_goal_panel.gd`, `_layout` scales a 1000×720 portrait card to landscape height. Close/Track/Claim are only 40/46/62 design units tall. At 390 CSS px screen height they are approximately 21/24/33 CSS px, and the 20-unit source hint is about 11 px. The most important endgame reward screen has difficult touch controls. | Preserve approved copper/iron frame, actual Pappa art and gold primary action; use landscape space, readable live text and at least 44 CSS px non-overlapping action hitboxes. Collection-only states must fit too. | Actual 667×375, 844×390 and 932×430 captures; transformed CSS hitbox measurements; taps at control edges; empty/partial/ready/claimed on/off, all mod titles, unspecified material and reopen. |
| UX-02 | P1, source-confirmed; fresh image pending | `scripts/ui/miner_skills_panel.gd`, `show_map` and `_layout`, place expanded map inside the Skills right-hand plate while retaining the portrait. `minimap_overlay.gd` then spends another 188 design units on biome cards/legend. The map requested as fullscreen remains small; 13-unit legend labels shrink further. | Give expanded cartography the main screen area while preserving the approved background/frame/nav and original Skills composition when returning. Increase expanded labels, keep the terrain area dominant and use a compact readable legend. | Surface, all D1/D2 worlds, Deep and hub; locked biome cards, wall/passages/ore/entrance/objective distinctions; open from HUD tap and Skills tab, close/reopen, rotate and switch back to Skills. |
| UX-03 | P1, source-confirmed plus initial screenshot | `scripts/ui/progression_goal_panel.gd`, `_update_action_visibility`, hides all mobile action text when a resource recipe exists; `premium_hud.gd`, `set_objective`, permanently hides the guide button. The comment says the guide supplies directions, but that guide is unreachable. Initial screenshot shows Iron Pickaxe and 0/30 gold, without how to obtain/spend the gold. | Make the current action/source reachable on mobile without restoring the retired compass; retain compact counters and a legible short action or tap-to-read goal detail. | New player, sell-ready, forge-ready, 5-part recipe and pinned endgame goal: player can identify the next place/action and all required resource names. |
| UX-04 | P2, source-confirmed | `scripts/ui/quick_tutorial.gd` uses the retired `hud-menu-v1.png` with MENU while the real HUD is the approved knot labelled SKILLS. It disappears after 9 seconds and sets a persistent seen flag; `premium_menu.gd::_show_settings` offers no controls replay. Opening a menu during the first seconds also marks it seen. | Reuse current action icon/caption; add an accessible controls replay or explicit first-session learning path, without erasing veteran tutorial state. | First launch, immediate menu interruption, new run after existing save, keyboard and touch; verify hints match the visible controls. |
| UX-05 | P2, source-confirmed | `premium_hud.gd::set_context_action` uses one `GUIDE_ICON` for DESCEND, ASCEND, RETURN and EXIT; generic interact/build families carry unrelated actions. This does not deliver the previously selected visual meaning for Descend and makes text necessary. Tool Forge is a good existing authored exception. | Audit the approved icon library and apply the approved shaft/down illustration to descent. Use existing authored direction/action assets where available; do not invent generic geometry or generate unapproved replacements. | Side-by-side contextual action states at phone size; meaning remains visible without tooltip. |
| UX-06 | P2, actual image confirmed | Fresh menu gives its highest-contrast frame and first focus target to disabled CONTINUE / NO EXPEDITION FOUND. NEW GAME is visually secondary. | Promote New Game and focus it when no save exists; retain Continue priority for returning players and safe Keep Save focus in destructive confirmation. | Fresh storage versus existing save screenshots and keyboard/touch activation. |
| UX-07 | P2, source-confirmed; visual scope pending | `resource_inventory.gd` and `premium_menu.gd` use flat green/gold panels, while Skills and mod previews use authored iron/copper frames; `commerce_panel.gd` has an additional steel/industrial system. This is a consistency review item, not authority to replace approved screens. Inventory also displays base drill image when a tool skin is equipped, which may confuse appearance versus statistics. | Preserve accepted materials; reconcile labels, typography and navigation first. Clearly distinguish equipped function from selected appearance if both matter. Review actual panels before choosing further art work. | Empty/full/protected inventory, drill with each workshop appearance, corresponding tool forge panel, Skills/settings/back paths. |
| UX-08 | P2, source-confirmed | `main.gd::_install_miner_skills` closes Skills before Settings; Settings Back returns to the generic main menu. Inventory opened from Skills closes directly to gameplay. “Back” lacks a stable parent context. | Decide and consistently implement parent-aware return for detail screens, while retaining a direct Return to Mine action. | Skills → Settings → Back, Skills → Bag → Close, pause menu → Settings → Back; no unintended resumed simulation. |

## Strengths to preserve

- Surface rock, buildings, plants and portal have authored texture, depth and material quality. The surface screenshot has a clear horizontal travel lane and the dad remains identifiable.
- New-game replacement confirmation is explicit and defaults to Keep Save; no deceptive destructive action is observed.
- HUD touch icons have generous visible scale, the approved bag and Tool Forge artwork exist in the design system, and major gameplay goals remain visible.
- Map code uses explored terrain and distinct marker shapes; build on this accurate model rather than substituting decorative map art.
- Mod preview standard correctly separates live UI text and state authority from meaningful Pappa illustrations. Claims and persistence remain in TreasuryGoals/RunState.

## Coverage still required before any whole-game acceptance

| Family | Current coverage | Needed next |
|---|---|---|
| Menu, fresh/saved/confirmation | Actual fresh and confirmation images; source navigation review | Settings, achievements and every return route |
| Surface HUD | One actual start image | Movement/mining/context across worlds, long numeric counts and five-resource recipe |
| Controls and onboarding | Source only | First 0–10 seconds on actual touch, interruption/replay, simultaneous movement/mining |
| Skills and stat tips | Source only | Actual Skills screen, level 100, held touch tooltip and stamina regeneration |
| Inventory | Source only | Empty/full/protected, skin-aware equipment info, scroll to last resource |
| Commerce | Source layout/catalog review | Surface forge/assay, hub tool forge/light/wardrobe, mole journal and upgrade success/locked/error states |
| Maps | Source only | Surface + D1/D2 all biomes + Deep + hub, actual taps and return paths |
| Treasury | Source only | Entry/exit direction, room composition, mixed continuous delivery, full piles fitting podiums, every goal state |
| Deep and mods | Equipment contact sheet only | Real nodes/rock/events/rope, each mod idle/active/release and meaningful preview comparison |
| Mobile robustness | Prior 844×390 Mac evidence only | 667/844/932 CSS variants, touch transforms, browser bars/rotation, physical phone feel/performance separate |

## Implementation handoff

Root authorized UX-01 then UX-02 as separate logical changes, with a durable checkpoint after each. Root owns UX-03 and coordinates separate follow-ups. This reviewer owns only `scripts/ui/treasury_goal_panel.gd`, `scripts/ui/miner_skills_panel.gd` and `scripts/ui/minimap_overlay.gd`. The independent QA engineer owns test-suite changes. No source change or visual acceptance is claimed by this report.
