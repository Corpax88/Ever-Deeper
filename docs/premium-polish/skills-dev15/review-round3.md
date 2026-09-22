# Skills DEV15 independent review — round 3

**Accepted for the narrow Skills/stamina DEV15 release.** Final exported
Skills visual fidelity: **8.0/10**. Code/state integration: **8.3/10**.
No remaining blocker was found in this review's scope. Publication must use
the exact reviewed candidate and the reviewed publisher gates.

Accepted source: `b788ca7484bc99bb210255851dacca35db501d5f`.
Successful build/browser run: `35795605519`.
PCK: 258,735,428 bytes, SHA256
`67b7507bc8df5a2b686801d71b98de205cdb352cd4a3d78cb03df32ce5c2009e`.

## Images actually inspected

Compared the locked `42A25114-7292-4352-BD31-71556D8D420B.jpeg` with the
following final exported-package images in
`runtime/dev15/final-browser/dev15-browser/`:

- `04-approved-skills-844.png`, `07-approved-skills-667.png`, and
  `03-earned-skills.png`.
- `05-map-844.png` and `06-map-667.png`.
- `08-inventory.png`, `09-settings.png`, and `09-settings-back.png`.
- `01-new-game.png`, `02-surface-touch-released.png`,
  `10-exhausted-moss-touch-released.png`, `11-endless-touch-released.png`,
  and `12-resumed-game.png`.

Also inspected all six ordinary Apple WebKit images in the sibling
`dev15-webkit/` directory: `01-ordinary-menu.png`, `02-after-new-game.png`,
`03-after-escape.png`, `04-saved-run-menu.png`, `05-new-game-confirmation.png`,
and `06-confirmed-new-game.png`. These visibly show the initial menu, actual
gameplay, paused menu, saved expedition after reload, replacement confirmation,
and a real fresh game after confirmation. Image paths and SHA256 identities
are recorded in `.github/skills-dev15/evidence/independent-review.json`.

## Visual assessment and closed blocker

The approved miner/mole identity, warm cave lighting, serif typography, dark iron
plate, copper edges, separate icon frames, live rows, and left/right composition
survive the landscape adaptation. Both phone widths keep the Skills rows and
location plaque legible. The embedded map remains inside its frame after the
actual 844-to-667 browser resize. The close target measures approximately
45.8 CSS pixels at 667×375 and is successfully touched.

The initial export inspected in this round, source `f39f00b72e8cabf542dbed9dc02bb319d43046b7`,
had a yellow DEV TOOLS overlay above Skills/Map that obscured the location label
at 667×375. Its captures in `runtime/dev15/browser3/dev15-browser/` were not
accepted. The corrected final images visibly remove that collision. The final
browser checks also confirm the existing developer controls return on close.

The actual-resource ambercore thumbnail remains small, and row copper has more
horizontal texture than the locked concept. These are bounded visual differences.
Inventory and Settings retain the existing game UI; their captures verify the
new navigation routes, not a separate redesign. The existing DEV overlay still
appears on those older screens. The narrow score does not certify every existing
game visual or establish exact pixel parity with the square concept.

## Actual gameplay and save evidence

The final Mac Chromium DPR3 report passes all 28 recorded entries on Apple Metal,
with no lost graphics context or runtime errors. The record and inspected
captures establish real menu taps, Map resize, Inventory/Settings/Back/Continue,
touch mining on Surface/Moss/Endless, earned movement XP and stamina drain,
active rest recovery, menu freeze, low-stamina mining, and resumed movement.
The mockup-like level/resource totals are explicitly seeded comparison fixtures.

In the zero-stamina Moss check, two real contacts reduce health from 27,712 to
27,706 and increase Mining XP from 21,424 to 21,432 while effort stays at 0.75.
Resumed movement advances 102 pixels with zero stamina and controls enabled.
The menu interval leaves damage, XP, and stamina unchanged with held input
released and controls disabled.

An already active swing completes once after resume: the recorded impact count
changes from 2 to 3 before the player reaches idle. This follows the unchanged
DEV14.3 `mossvein_mine.gd` contract: an active swing reaches its strike after
release, then another swing begins only if input is still held. It is not a
claim of zero post-resume impacts. The subsequent movement interval has no
additional mining and both input and control telemetry are consistent.

All four exact-pack core suites pass: input, overhaul (1,259 checks), touch
(125 checks), and build flavor/save namespace. The separate Skills log ends
with `MINER_SKILLS_COMPLETE 28`. I verified both evidence SHA256 values against
their bindings in the accepted build record. Normal WebKit startup completes
51 observations and the six inspected images without a crash or runtime error;
the initial visit and explicit reload account for the two navigations.

The protected-file snapshot check remains a recorded failure. It names
`project.godot`, `hero_gear.gd`, `player_controller.gd`, and `player_visual.gd`.
Against the actual DEV14.3 source, the only change in those files is the two
authorized stamina movement multipliers in `player_controller.gd`; the other
three are unchanged. This is a known older-snapshot mismatch, not a passing
invariant check.

## Code and publisher review

The additive optional save section, bounded XP/level100, physics-order travel
sampling, cached levels, and 75% minimum effort remain coherent. The embedded
Map callback conflict is fixed. No new save-corruption, native-animation,
or player-immobilization blocker was found.

Re-reviewed `.github/skills-dev15/publish.py` and
`.github/workflows/publish-skills-dev15.yml` after their fresh-run update.
The publisher requires a single successful build/browser run matching the
accepted source; exact candidate/build/browser artifact identities; all nine
candidate hashes; pinned review/evidence files; the hardware Mac renderer;
required phone captures and gameplay assertions including DEV overlay visibility;
normal WebKit startup; build-bound core/Skills log hashes; the existing DEV save
namespace; and unchanged native hero/tool resources. It stages prior DEV as a
rollback artifact, verifies all eighteen retained LIVE/Worn files before
deployment, and verifies all twenty-seven public files afterward. No concrete
publication-safety blocker was found in the reviewed publisher source.

## Acceptance limits

This is acceptance of the listed final build, its Skills UI, and the tested
stamina/menu integration. It is not a publication receipt. Physical iPhone
startup/crash resolution and physical iPhone FPS remain unverified. The browser
tests and still captures do not provide a full animation-sequence or every-biome
visual certification. The approved gameplay hero and native tools remain the
existing DEV14.3 assets.
