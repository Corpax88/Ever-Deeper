Current verified release: [DEV15.5 retired Wayfarer shops and relocated quarry](premium-polish/world-dev15-5/HANDOFF.md) is published at https://corpax88.github.io/Ever-Deeper/dev/. All five stores and ordinary purchase routes removed; Copper Ridge moved to (812,600), approach (812,650). Previously purchased speed retained. Exact source 57ab001fe2f4d1b9d37c608c290d05c668f6848a on codex/remove-wayfarer-20260923. Test 35855675070 and publication 35856567685 passed; all27 public hashes verified. Nine final images independently accepted, scoped code9/10 and visual8/10. Saves,21 native files,LIVE and trial preserved. No physical-iPhone claim. Do not repeat export/test/publication for this unchanged candidate.

Current verified release: [DEV15.4 silver tooltip headings](premium-polish/skills-dev15-4/HANDOFF.md) is published at https://corpax88.github.io/Ever-Deeper/dev/. Only the five Skills tooltip headings use light steel/silver; body and right-hand list text unchanged. Exact source 666cecf24214c2b144c5bc8403cfd526e625c416 on codex/skills-silver-headings-20260923. Test35848817678 and publication35849562311 passed; all27 public hashes verified. Five final tooltip captures accepted, scoped code10/10 and visual9/10. Saves,21 native files,LIVE and trial preserved. No physical-iPhone claim. Do not repeat exports/tests/publication for this unchanged candidate.

Current verified release: [DEV15.3 Skills level and XP bars](premium-polish/skills-dev15-3/HANDOFF.md) is published at https://corpax88.github.io/Ever-Deeper/dev/. Exact source30a2aff088d2e2219382c765a74bf37804f9ad73 on codex/skills-xp-bars-20260923; main holds publication/evidence. Test35846632446 and publication35847446465 passed, all27 public hashes verified. Gold bars show level/100; thin red bars replace numeric XP. Full level100 text verified.35 Chromium checks and ordinary WebKit passed, scoped independent9/10. Saves,21 native files,LIVE and trial preserved. No physical-iPhone claim. Do not rebuild/retest/reupload this unchanged candidate. Standing DEV publication authorization persists.

Current verified release: [DEV15.2 approved tools icon](premium-polish/hud-dev15-2/HANDOFF.md) is published at https://corpax88.github.io/Ever-Deeper/dev/. Exact source d21215650f165c81e14ad0d56d202679eab740d5 on codex/approved-tools-icon-20260923; main holds publication/evidence. Test35830513108 and publication35831303971 passed, all27 public hashes verified. Approved PNG replaces only the HUD menu icon;104 image cap preserves120 touch target. Skills internal layout, saves and21 native files unchanged. Independent scoped review9/10. No physical-iPhone claim. Do not rebuild/retest/reupload this unchanged candidate.

Current verified release: [DEV15.1 larger gameplay icons and stat tooltips](premium-polish/hud-dev15-1/HANDOFF.md) is published at https://corpax88.github.io/Ever-Deeper/dev/. Exact game source51e2c58ce8806d11c9fc608c6d6a9e48b74507c8 on codex/gameplay-icons-tooltips-20260923; main holds publication/evidence. Test run35822513557 and publication run35823540837 passed, all27 public hashes verified. Skills icon/layout sizes are unchanged by explicit user instruction; gameplay buttons are larger, stats explain themselves on hover/held touch. DEV saves, LIVE and retained trial preserved. No physical iPhone claim. Do not rebuild/retest/reupload this unchanged accepted candidate. Standing publication authorization persists; no new login is needed.

# Ever-Deeper — DEV15 publisert

Vanlig DEV: https://corpax88.github.io/Ever-Deeper/dev/ — 1.0.0-dev.15.
Mats ba om implementering av låst Skills-mockup og aktiverte stamina. Arbeidet er ferdig.
Les docs/premium-polish/skills-dev15/HANDOFF.md og Ever-Deeper-Fortsett-her.md for gjeldende status.

Spillkilde: b788ca7484bc99bb210255851dacca35db501d5f på codex/locked-skills-ui-20260922. Main inneholder publisering/bevis.
Eksakt test-run35795605519 besto core,28 Skills/save-prøver, faktisk Mac Metal-mobilspill og vanlig Apple WebKit-oppstart/lagring. Uavhengig kritiker inspiserte19 sluttbilder og godtok denne avgrensede DEV-endringen (visuelt8.0/10, kode8.3/10).
PCK258735428bytes, SHA25667b7507bc8df5a2b686801d71b98de205cdb352cd4a3d78cb03df32ce5c2009e.
Publiseringsrun35796692140 og commitbacabfe3c9b2729f7f918d00c66da8dffc929f35. Alle27 offentlige filer verifisert. Kvittering: main/.github/skills-dev15/evidence/publication-receipt.json; artefakt10724631256. LIVE, historisk prøve og DEV-lagringsnavnerom er bevart.

Ingen ny eksport/opplasting/Mac-test står igjen for denne kandidaten. Fysisk iPhone-krasj/FPS og Simulator er fortsatt ikke verifisert. Ikke start simulatorarbeid eller ny helteproduksjon automatisk. En allerede påbegynt sving kan fullføres etter resume; menyen fryser skade, XP og stamina.

## Testmiljø som faktisk virket
- Godot4.7.2. Last ned offisiell Linux-binær; pakk ut til /tmp, da en tidligere workspace-kopi ble trunkert. Intakt lokal fil var /tmp/ever-deeper-skills-tools/Godot_v4.7.2-stable_linux.x86_64 (146414384bytes).
- tools/run_rendered_isolated.py med lokal Xvfb ga ekte native bilder og isolert lagring. Xvfb lå under runtime/xvfb/usr/bin; nødvendig libXfont2/libxkbfile/xkbcomp var satt opp.
- Endelig eksport og grafisk test kjøres i .github/workflows/skills-dev15.yml. Linux bygger; macos-15 kjører Chromium/Metal og Apple WebKit. Rendererjobber har contents:read og checkout persist-credentials:false.
- 21 godkjente native ressurser gjenbrukes med individuelle hasher fra .github/skills-dev15/native-input.json. Build.py bruker offentlig DEV-PCK bare som bærer; ingen ny Blender-/figurproduksjon.
- Eksisterende GitHub-connector er autentisert. Lokal git push mangler shell-legitimasjon; ikke be Mats logge inn på nytt. Ikke send binærdata/base64 gjennom verktøyargumenter eller -resultater. Bruk filreferanser og direkte overføring.
- Testbevis: Ever-Deeper-DEV15-bevis.zip; kilde og produksjonsgrafikk er lagret i Git. Første grafikkarkiv: libfile_06d3ff7b27ac81918aedb9576867c224.

Kjent invariantkontroll: den eldre beskyttede snapshoten avviker for project.godot, hero_gear.gd, player_controller.gd og player_visual.gd. Mot faktisk DEV14.3 endres bare de autoriserte stamina-multiplikatorene i player_controller; de øvrige tre er uendret. QA-registeret er oppdatert. Ikke kall hele invariantkontrollen grønn.

Mats ønsker korte norske svar, normalt høyst fem linjer. Ingen samlet9/10- eller fysisk iPhone-godkjenning.
