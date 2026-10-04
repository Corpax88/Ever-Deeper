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

## Expanded baseline inspection, later on 4 October

Root recovered the exact baseline into `/workspace/scratch/72d2364e7fd1/baseline-recovery/evidence` on Mac Apple Metal at DPR2. I individually inspected these additional 26 full-size images (not just a contact sheet):

- `skills-844.jpg`, `settings-667.jpg`, `inventory-full-667.jpg`, `achievements-667.jpg`, `mole-journal-667.jpg`.
- All eight `mod-preview-<resource>-844.jpg` images for wallet_gold, burrowsteel, prismite, rootiron, echo_crystal, phasecrystal, deep_alloy and singularity.
- `surface-locked-844-expanded-map.jpg`, `moonMine-1-844-expanded-map.jpg`, `starMine-2-844-expanded-map.jpg`.
- `commerce-tool_forge-844.jpg`, `commerce-forge-667.jpg`, `commerce-light_lab-844.jpg`, `commerce-wardrobe-844.jpg`.
- `treasury-inside-entry-844.jpg`, `treasury-podium-26-100000-844.jpg`, `treasury-approach-667.jpg`.
- `moonMine-2-844.jpg`, `emberMine-1-844.jpg`, `001-first-run-1s-844.jpg`.

This actual-image evidence confirms UX-01/02/03/04. All eight mod illustrations use the correct Skills dad and provide distinct meaningful effect art. Commerce framing and typography are coherent within that family, and the treasury's actual gold pile fits its authored podium; neither needs generic replacement.

New findings:

| ID | Priority | Actual evidence | Required follow-up |
|---|---|---|---|
| UX-09 | P1 | `settings-667.jpg` and `achievements-667.jpg`: the aspect <1.95 branch uses desktop typography, leaving approximately 6–8 CSS px detail text and a Back target near 30 CSS px high. `inventory-full-667.jpg` similarly uses small body labels/Close. | Make landscape-phone details readable at 667 as well as 844/932. Verify CSS font/target sizes, not the nominal Godot dimensions. |
| UX-10 | P1 | `mole-journal-667.jpg`: most command, tab and Close hitboxes are about 35 CSS px high. | Increase actual hitbox height to at least 44 CSS px while retaining the authored parchment, mole and hierarchy; verify all journal tabs and long skill rows. |
| UX-11 | P1 navigation usefulness | `surface-locked-844-expanded-map.jpg`: surface map is a flat rectangle with a few unnamed markers and an underground terrain legend. Enlarging it alone will not explain the surface road, forge, assay or world entrances. | Use real surface landmarks/routes and a surface-appropriate legend; never fake unknown underground terrain. |
| UX-12 | P1 candidate investigation | Main stops updating minimap inside the treasury, while the Skills Map route remains available. This can expose stale Hub cartography. No treasury→Skills→Map image inspected yet, so this is a source risk, not a claimed visual reproduction. | Capture the actual route and show treasury-relevant position/exit/podium information or an explicit unavailable state; do not show another area's map as current. |

The three initial baseline harness failures reported by QA were fixture assumptions (surface without underground cartography, non-commerce treasury workshop, stale exit coordinates). They are not counted here as production regressions. Independent gameplay/performance review remains separate, and no overall 9.5 acceptance is claimed.

Source work completed after the initial review: UX-01 landscape reward layout and UX-02 fullscreen map were checkpointed by root and await actual candidate image acceptance. Root also assigned parent-aware navigation in `main.gd` and `premium_menu.gd`, saved for a separate checkpoint. Controls replay follows after that checkpoint. These are implementations under review, not evidence that the findings are resolved.

## Surface and Treasury map candidate

Root subsequently checkpointed Controls replay and the 667 Settings/achievement layout. The next isolated change refreshes the map snapshot when opened while paused; surface maps now use existing authored route arrays and camp/pocket rectangles, known station/mine labels and a surface legend. Treasury maps use the actual room floor polygon, actual 27 bay positions and existing resource art, Exit/Donate markers, current player position and the pinned resource. The renderer reserves biome cards for surface/underground areas and keeps locked surface regions hidden. Navigation metadata is explicit and reset for each new expanded view; original mini markers are deep-copied.

An isolated overlay of the exact candidate1 production PCK retained every unrelated payload byte and replaced only `main.gd`, `miner_skills_panel.gd`, `minimap_overlay.gd` and their remaps. Ordinary native headless startup and 13 focused state checks passed without script errors. Evidence: `/workspace/scratch/72d2364e7fd1/ux-map-check/startup.log`, `review.log`, `checks.json` and `review.gd`. The sequence covers locked Surface → Treasury with tracked Gold → fully unlocked Surface → Moonglass D2, including pause/close, actual bounds/positions, 27 podiums, floor polygon, no marker mutations and no stale navigation metadata. This is structural validation only; target 667/844/932 rendered capture and actual touch review remain required.
