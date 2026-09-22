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
