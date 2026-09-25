DEV15.10 is independently approved and publication36119229397 is running; public verification pending. Canonical game source is ab0c12ff579134e0a092946bd92973e4599a073c on codex/canvas-cpu-dev15-10-20260925. See [final release evidence](docs/performance-diagnosis/release-candidate/HANDOFF.md). Six final core cases and ordinary saved-game startup passed; final six screenshots reviewed, publisher accepted. Exact original versus CPU/native/shared-HUD candidate improves weighted MacFPS11.25%/12.72%, slowframe totals lower;546ms candidate stall retained, no phone or stutter-fix claim. Native26/UI24 exact pairs and tool/UI lifecycle reviewed. Wider12/24 groups rejected for marginal total gain; productionwidth6 retained. Preserve LIVE/Worn and DEV save identity; use exact immutable artifact, not main's historical runtime source. Do not repeat completed unchanged matrices, export or candidate tests. Next action is finish publisher/public27hash verification, then document phone validation as unverified.

Latest follow-up: [actual original-package comparison](docs/performance-diagnosis/integrated-perf/HANDOFF.md). 676e122/run36116139795: two Mac Apple/WebKit workers passed48 checks each/24 windows total, exact original DEV15.9 versus production CPU/native candidate981dfb6. Weighted FPS45.000→47.513(+5.58%) and34.335→38.402(+11.85%); strong drift, mixed p95 and worker1 slowframes205→259/321ms candidate stall. Useful aggregate improvement, not a consistent stutter fix or physical-iPhone acceptance. Native184checks/26 exact pairs and ordinary saved-game screenshots independently reviewed on94f3302;981 changes only QA inheritance pack path, its six core and browser jobs passed. Corrected journal prototype47576 passed125checks/24 exact pairs/36 inspected PNG. Clean production shared-HUD candidate4f27644/run36116844019 is testing real input/resize/Deepheart/reload; not accepted. Public DEV15.9 unchanged. Continue authorized work; no phone retest yet. Do not repeat unchanged completed matrices.



## FPS continuation checkpoint — 25 September 2026, 08:50 UTC

Mats asks to continue autonomously until solved; do not end with another permission request. Public DEV15.9/c63aabd is unchanged. Empty-native-canvas trial96e3519/run36111698762: all36 full-image pairs exact, synchronization4→3; mixed FPS50.090→51.747 and59.899→59.965, no strong phone fix. Revised production lifecycle guard also rechecks/re-enables2D at gear changes.

Combined UI trial07edde2/run36112848069 preserves36 frozen pairs, synchronization4→2, weightedFPS50.067→52.619 and59.730→59.815. Both raw runs failed a WRONG commerce-panel predicate; the actual companion journal is separate. Corrected journal test36449d6/run36114525488 confirms original real-touch opening but reveals a journal image difference (max177). Narrow actual-image capture25b1157/run36115000765 now running; do not call this an input regression or accepted UI implementation.

Integrated occupancy+native candidate86ae743/run36114997717 now validating. First d1a01e9 failed preload resolution through compiled player_visual; direct appended-script check-only had no error. Recovery uses byte-identical player_visual source verified against original c63aabd, changing only its remap. Preserve current assets/quality, all real lifecycle gates, and all outliers. See docs/performance-diagnosis/integrated-candidate/HANDOFF.md.

Final Safari attemptee2e225/run36112922230 failed native-session transport before opening the game; actual screenshot is iOS home. Zero valid phone/Simulator FPS windows. Earlier page context-loss evidence remains separate. Do not blindly repeat this environment route. Full source, raw reports, failed gates and limitations are in docs/performance-diagnosis/{empty-canvas-study,ui-canvas-study,safari-fps}.
## Pågående FPS-arbeid 25.09: synkroniseringsprofil og tomt tegnesteg

Fastlysfelt er forkastet; se forrige checkpoint. Ny renderprofil525a55be/run36111016427 er ferdig:91kontroller,8vinduer, firefenceSync/getSyncParameter perramme også utenlys. Instrumentering koster målbart og GL-veggtid er ikke GPU-tid. Se docs/performance-diagnosis/render-profile/HANDOFF.md. Nå testes kun å hoppe over tom2D-canvas i eksisterende3D-only NativeRig200px: codex/empty-canvas-study-20260925,96e3519ef2f470310379125250959c908f750379,run36111698762. Eksaktebilder og faktisk færre synkroniseringskall kreves; ingen endring avnativefiler/figur/lys/UI/oppløsning.

Safari7a236e/run36110103989 nådde faktisk spillside i iPhoneAir/iOS26.2 Simulator, men mistetWebGL-konteksten ved oppstart.0FPSvinduer; faktiskfeilbilde inspisert. Ikke Safari-gameplay eller fysiskmobil-verifisering. Én målrettet recovery57e766a9acd23e84964fdd8843e5f8161ac89edf/run36111409066 kjører medsammeimmutablepakke, tidligGL-/konsolltelemetri, ettbegrensetreload og systemlogger. Les docs/performance-diagnosis/safari-fps/HANDOFF.md. Fortsett begge pågåendejobber og vurder faktiske resultater; ikke stopp for et nytt kjør. Canonical/public runtime fortsattDEV15.9/c63aabd, ikke publisert pånytt.

## Pågående FPS-arbeid 25.09: lysbaking forkastet

Brukeren ber om å fortsette autonomt til løst; ikke stopp etter ett forsøk. Fastlysfelt aa3b87ffd79130d0796aed6592d8f6a02f9a6481/run36110170882 er ferdig og forkastet: to Macer44,858→44,598 og42,229→42,826FPS; ingen stabil gevinst.236 kontroller,12 tidsvinduer,18 eksakte retursammenligninger,18 kandidatpar med maks1–2/255 avvik; alle12 beholdte PNGer uavhengig inspisert. Alle lys-/felt-sluttstatuser verifisert. Les docs/performance-diagnosis/fixed-merge-study/HANDOFF.md; ikke gjenkjør uendret.

Ny målrettet CPU-veggtidsprofil av WebGL-kall/rAF kjører: codex/render-profile-20260925,525a55be87f6650d0221cf260a51093688628fbd,run36111016427. Bruker eksisterende immutable fixed-light-candidate, uten ny eksport; instrumentering av/på måler observatørkostnad. Ikke GPU-tid. Safari-recovery7a236e5147fa4f12da023fb350ca7660479c622a/run36110103989 kjører også; ikke påstå iPhone-/Safari-resultat før faktiske bilder/rapport. Behold occupancy-revisjonens målte funksjonsbesparelse som separat kandidat. Kanonisk/public runtime fortsattDEV15.9/c63aabd; ingen publisering eller mobiltestforespørsel.

Latest ongoing work: [fixed-light isolation](docs/performance-diagnosis/fixed-light-study/HANDOFF.md). User explicitly requests autonomous continuation until solved. ef660ef/run36109186370 passed135 checks per Mac,24 mining windows; fixed lights off improves aggregate42.88→48.31 and47.20→51.78FPS, but drift prevents a phone prediction. All8 captures independently reviewed; baseline/restoration exact. Audited occupancy revision enabled in every mode. Two follow-ups are now running: cached fixed-light field aa3b87f/run36110170882 and corrected Simulator Safari bridge7a236e5/run36110103989. Earlier prototype/bridge runs cancelled after concrete corrections; no result acceptance or publication yet. Hero/pet/world quality and public DEV15.9 unchanged. Reconcile these runs; continue rather than asking for another go.

Latest follow-up: [world-owned occupancy revision study](docs/performance-diagnosis/revision-study/HANDOFF.md). QA c9c26ef/run36105429639 completed: six exported core cases, two Mac WebKit repeats with221 checks each,108 pixel-exact pairs and22 real mutation checks. All12 captures independently inspected; lights/hero/companion unchanged. Refresh CPU1.587→0.03385 and1.319→0.03304ms/frame (~98% less helper CPU);52–53 redundant scans→0. Total FPS32.56→35.59 and45.84→45.61, with drift/mixed p95: no repeatable full-FPS or phone fix. Retain isolated CPU candidate and unapplied production patch. All117 canonical scripts audited; current membership writers and same-count replacements covered. Both timing modes share revision bookkeeping. No publication or phone retest; canonical/public DEV15.9 unchanged. All jobs finished. Do not rerun unchanged matrices; next distinct investigation may isolate fixed work lights, without assuming the remaining bottleneck is proven.

Current verified release: [DEV15.9 native depth-one lighting shader](docs/performance-diagnosis/native-light-dev15-9/HANDOFF.md) is published at https://corpax88.github.io/Ever-Deeper/dev/. Export `c63aabd3e3e5120579285ce6e8b0b59a75f2727a` on `codex/native-light-dev15-9-20260924`; only standard depth-one terrain stops forcing the alpha-discard shader. Exact 22 A/B/A pairs, all native21 assets unchanged, input/touch125/save-flavor,24 WebKit light/report checks and ordinary WebKit save/startup passed in36043919958. Six Mac Apple Metal mining windows weighted54.47→57.35FPS (+5.3%); all candidate windows beat all reference FPS/p95, slow frames66→46. GPU interval inconclusive; no physical-iPhone gain or60FPS claim. Independent code9/10,visual9/10,DEV readiness8/10 and publisher accepted. Publication36045901828 verifies all27 public hashes and preserves LIVE/Worn/saves. Physical DEV15.8 report had47.83→59.94 lights-off→48.18FPS restored; DEV15.9 phone comparison is next. Existing invariant QA flag documentation assertion remains. Do not repeat accepted export/test/publish; do not repeat rejected floor merging. Read private labelled report after Mats sends LIGHT TEST + REPORT.

Earlier release notes below are historical.

Current verified release: [DEV15.7 private play-session reports](docs/performance-diagnosis/dev15-7/HANDOFF.md) is published at https://corpax88.github.io/Ever-Deeper/dev/. Canonical export `abc42ca5db531270510802bf7dab4f3f0936d06d` on `codex/telemetry-dev15-7-20260924`. Opt-in START REPORT → play → SEND REPORT; private receiver stores measurements readable directly with Sites database tools. Main QA `36012592198`, recovery `36014339986`, and publication `36015068520` passed; all 27 public hashes verified, LIVE1.0.0/Worn unchanged. Independent scoped code/visual review 8/10 accepted. Real production database is readable but the first user upload and physical iPhone transfer remain unverified. This is diagnostics, not a new FPS fix; DEV15.6 phone video still drops to 29–36 FPS. Read the linked handoff for the exact private project ID and reading instructions. Do not repeat export/testing/publication of this unchanged candidate. Next step is the user's first report.

Earlier release notes below are historical.

Current verified release: [DEV15.6 terrain CPU improvement](docs/performance-diagnosis/dev15-6/HANDOFF.md) is published at https://corpax88.github.io/Ever-Deeper/dev/. Canonical source6073b9d4dc11034d60305d5eb49785c033e836ed on codex/fps-dev15-6-20260923. Run35926247469 passed: five exported core cases,28 Skills/save checks,25 Chromium checks including17 exact full-frame pairs and ordinary WebKit startup. Measured section setup/draw CPU27.94% lower in Mac A/B/A; physical iPhone FPS and recorded250ms stall remain unverified. Scoped independent code9/10,visual8/10 accepted. Publication35927487060 verified all27 public hashes; LIVE1.0.0 and Worn unchanged. Approved hero/assets/animation/gameplay/saves unchanged. Do not repeat export/testing/publication for this unchanged candidate.

Current verified release: [LIVE1.0.0 production promotion](docs/premium-polish/live-1-0/HANDOFF.md) is published at https://corpax88.github.io/Ever-Deeper/ under Mats's explicit LIVE authorization. Current approved DEV content is now production without developer-menu/probe resources. Native hero/animation and required assets promoted together. Exact source 28667f9796d386472f021771ed9336223efe0a48 on codex/live-1-0-20260923. Test 35858775472 and publication 35859887837 passed; all27 public hashes verified. Six core cases,26 Skills checks,69 Chromium checks and ordinary WebKit passed;10 final images accepted (scoped code9/10,visual8/10). Production save identity retained; DEV saves remain separate. DEV15.5 and Worn bytes unchanged. No physical-iPhone claim. Do not repeat export/test/publication for this unchanged candidate.

Current verified release: [DEV15.5 retired Wayfarer shops and relocated quarry](docs/premium-polish/world-dev15-5/HANDOFF.md) is published at https://corpax88.github.io/Ever-Deeper/dev/. All five stores and ordinary purchase routes removed; Copper Ridge moved to (812,600), approach (812,650). Previously purchased speed retained. Exact source 57ab001fe2f4d1b9d37c608c290d05c668f6848a on codex/remove-wayfarer-20260923. Test 35855675070 and publication 35856567685 passed; all27 public hashes verified. Nine final images independently accepted, scoped code9/10 and visual8/10. Saves,21 native files,LIVE and trial preserved. No physical-iPhone claim. Do not repeat export/test/publication for this unchanged candidate.

Current verified release: [DEV15.4 silver tooltip headings](docs/premium-polish/skills-dev15-4/HANDOFF.md) is published at https://corpax88.github.io/Ever-Deeper/dev/. Only the five Skills tooltip headings use light steel/silver; body and right-hand list text unchanged. Exact source 666cecf24214c2b144c5bc8403cfd526e625c416 on codex/skills-silver-headings-20260923. Test35848817678 and publication35849562311 passed; all27 public hashes verified. Five final tooltip captures accepted, scoped code10/10 and visual9/10. Saves,21 native files,LIVE and trial preserved. No physical-iPhone claim. Do not repeat exports/tests/publication for this unchanged candidate.

Current verified release: [DEV15.3 Skills level and XP bars](docs/premium-polish/skills-dev15-3/HANDOFF.md) is published at https://corpax88.github.io/Ever-Deeper/dev/. Exact source30a2aff088d2e2219382c765a74bf37804f9ad73 on codex/skills-xp-bars-20260923; main holds publication/evidence. Test35846632446 and publication35847446465 passed, all27 public hashes verified. Gold bars show level/100; thin red bars replace numeric XP. Full level100 text verified.35 Chromium checks and ordinary WebKit passed, scoped independent9/10. Saves,21 native files,LIVE and trial preserved. No physical-iPhone claim. Do not rebuild/retest/reupload this unchanged candidate. Standing DEV publication authorization persists.

Current verified release: [DEV15.2 approved tools icon](docs/premium-polish/hud-dev15-2/HANDOFF.md) is published at https://corpax88.github.io/Ever-Deeper/dev/. Exact source d21215650f165c81e14ad0d56d202679eab740d5 on codex/approved-tools-icon-20260923; main holds publication/evidence. Test35830513108 and publication35831303971 passed, all27 public hashes verified. Approved PNG replaces only the HUD menu icon;104 image cap preserves120 touch target. Skills internal layout, saves and21 native files unchanged. Independent scoped review9/10. No physical-iPhone claim. Do not rebuild/retest/reupload this unchanged candidate.

Current verified release: [DEV15.1 larger gameplay icons and stat tooltips](docs/premium-polish/hud-dev15-1/HANDOFF.md) is published at https://corpax88.github.io/Ever-Deeper/dev/. Exact game source51e2c58ce8806d11c9fc608c6d6a9e48b74507c8 on codex/gameplay-icons-tooltips-20260923; main holds publication/evidence. Test run35822513557 and publication run35823540837 passed, all27 public hashes verified. Skills icon/layout sizes are unchanged by explicit user instruction; gameplay buttons are larger, stats explain themselves on hover/held touch. DEV saves, LIVE and retained trial preserved. No physical iPhone claim. Do not rebuild/retest/reupload this unchanged accepted candidate. Standing publication authorization persists; no new login is needed.

# Ever Deeper

Published milestone: [DEV12 verified, 17 September 2026](docs/premium-polish/dev12-north-edge-20260917/PUBLISHED.md).
DEV12 includes the independently reviewed upright Moss north edges.
This branch now uses a clean version-3 binary save format; older saves are intentionally invalid.
Premium polish continues; stable 50 FPS and final 1.0 acceptance remain open.

The current game is a **Godot 4.7.2** project. Open `project.godot` in this directory.
The production candidate label is `1.0.0-rc.1`; final acceptance remains open.
The published DEV label is `1.0.0-dev.12`.
Tool Forge appearances now select their advertised models even when a drill is owned.
Read [the tool skin handoff](docs/tool-skin-HANDOFF.md) for DEV8 validation status.
The post-drill guide targets required ore, and opened drill barriers retain renewable ore.
Read [the drill guide handoff](docs/drill-guide-HANDOFF.md) for DEV7 validation and publication status.
The Starforge Hub visit stays completed across checkpoints, exit and reload. The older DEV6 save-recovery notes below describe that historical release, not this branch's new save epoch.
Read [the Hub guide handoff](docs/hub-guide-HANDOFF.md) for DEV6.
Discoveries supply their first Hub building, nearby finds get visible clues, and Starfall opens after Ember mastery 1.
Read [the discovery-loop handoff](docs/discovery-loop-HANDOFF.md) for this change and [the 1.0 handoff](docs/one-point-zero/HANDOFF.md) for earlier work and remaining acceptance gates.
LIVE remains the separate published 0.46.9 package until explicitly accepted.

## Start here

- [Code map](docs/code-map.md): where to make each kind of change.
- [Verification](docs/verification.md): current checks, mobile review and known older failures.
- [Project rules](AGENTS.md): approved art and the mandatory visual release gate.
- [Cleanup review](docs/cleanup-review.md): independent scores, changes and remaining debt.

## Run and check

Install the standard Godot **4.7.2** editor. From this directory:

```sh
godot --editor --path .
python3 tools/qa.py --godot /path/to/Godot
python3 tools/check_invariants.py
```

`GODOT_BIN` can supply the executable instead of `--godot`.
The QA launcher isolates test save files, checks exit codes and completion markers,
and fails on runtime errors or timeouts. Its default is the current source suite;
older failing checks remain available explicitly, with their failures documented.

## Web builds

Install matching Godot 4.7.2 export templates, create the output directories, then:

```sh
godot --headless --path . --export-release 'Web DEV' builds/dev/index.html
godot --headless --path . --export-release 'Web Production' builds/live/index.html
python3 tools/qa.py --godot /path/to/Godot --pack builds/live/index.pck --cases build-flavor
```

DEV retains its developer menu and isolated saves. Production excludes the developer-menu
resource. Publishing is a separate, reviewed step; exporting or changing source does not
publish a build. The historical release workflows under `.github/` record prior releases.

Older JavaScript-prototype instructions are historical, not instructions for this game.
No source archive or chain of release patches is needed to open this complete project.
