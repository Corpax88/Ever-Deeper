# DEV15.1 — større spillikoner og statforklaringer

23. september 2026. Mats presiserte at større ikoner gjelder spillområdet, ikke størrelsene inne i Skills. **DEV15.1 er publisert på https://corpax88.github.io/Ever-Deeper/dev/.** Publiseringsrun35823540837 besto package, deploy og verify. Alle27 offentlige filhasher er kontrollert. Publiseringscommit740079b34adac8ae93f10da36be1ab6de76dcd04.

Mining, meny, guide, muldvarp, sekk, gull, ressurskrav og handlingsikoner er større. Trykkflatene følger ikonene. Kompakt landskap bruker samme tydelige kontrollstørrelser, og guide-markører holder seg unna kontrollene. Kartet har kollisjonsfallback for svært smale logiske visninger; den faktiske3:2-testen passet med kartet i toppraden.

Skills beholder eksisterende ikonstørrelser, dimensjoner, bilder og layout. Alle fem stats har forklaringer ved hover, tastaturfokus og langt trykk. Teksten viser det faktiske nivåets staminafordel og lover ingen ekstra loot-bonus for Prospecting. Stamina forklarer at hvile krever at man verken beveger seg eller miner. Forklaringen lukker ved slipp, avbrutt touch, dragging, tabbytte, resize og lukking. En holdt finger beholder gesten selv når nettleseren sender syntetisk hover før ScreenDrag.

## Kilde og test

Kanonisk repo: Corpax88/Ever-Deeper. Spillgren: codex/gameplay-icons-tooltips-20260923. Eksakt eksportkilde: 51e2c58ce8806d11c9fc608c6d6a9e48b74507c8. Main eier publisering/bevis, ikke spillkilden. Test-run35822513557 besto begge jobbene. PCK258740164 byte; SHA256 fa6c452639e54d05df746eb9ef3743459a7b07b7c452aca95643c32861f30ee0.

Fem eksporterte kjernesuiter besto: input,1259 gameplay-kontroller,125 touch-kontroller, mobil-layout og DEV/save-flavor.28 isolerte Skills/save-kontroller besto.59 Chromium-kontroller/captures besto på Mac Metal, inklusive ekte mining, joystick, direkte trykk på guide/sekk/muldvarp, hover for alle fem stats, langt trykk, korte trykk, drag og forsinket drag mellom stats. HUD fanget ved844×390,667×375 og900×600/DPR3. Normal Apple WebKit besto New Game, lagret-spill-omlasting og bekreftet New Game.30 originale skjermbilder er i browserartefakten.

Kandidat10733743912, build10733898766, browser10733689603 fra samme run. ZIP SHA256 er bundet i .github/hud-dev15-1/review.json. Alle21 godkjente native filer er identiske med DEV14.3. Spillbalanse, lagringsskjema og helte-/utstyrs-/animasjonskode er uendret fra DEV15. DEV bruker user://ever_deeper_dev_run_v3.sav.

## Rettelser fra kritiker og sluttprøve

Første iterasjon0a303016 besto52 Chromium-kontroller. Kritiker fant mulig kart/gull-kollisjon i en smal logisk visning, upresis hviletekst og risiko for syntetisk hover etter langt hold. Iterasjon140876a feilet den nye, faktiske Stamina→Mining-dragtesten. Syntetisk mouse_entered kunne komme før ScreenDrag og nullstille eieren.51e2c58 krever både utløpt touch-karantene og ingen aktiv finger før muse/fokus-hover kan starte. Den uendrede forsinkede dragtesten besto ved begge telefonbreddene i sluttbygget. Ingen av de avviste/mellomliggende eksportene ble publisert.

## Begrensninger og videreføring

Fysisk iPhone og fysisk FPS er ikke verifisert. Invariantkontrollen beholder de fire arvede avvikene: project.godot, hero_gear.gd, player_controller.gd og player_visual.gd. Disse filene er uendret fra DEV15 i denne oppgaven. Ikke start ny hero-, animasjons- eller FPS-produksjon automatisk.

Gjenopprett testmiljø etter game-test-environment-rutinen. Bruk eksisterende autentisert GitHub-forbindelse; vanlig git clone/fetch fungerer, men shell-push mangler legitimasjon. Ingen ny brukerinnlogging. Sourcebygg: .github/hud-dev15-1/build.py og workflows/hud-dev15-1.yml, Godot4.7.2, native carrier med21 eksakte filhasher. Nettleser: eksisterende macos-15/Node22/Playwright Metal-route. Ikke re-eksporter eller test på nytt når de aksepterte filene er uendret. Mats sin stående DEV-publiseringstillatelse gjelder fortsatt.

Uavhengig gjennomgang godkjente alle30 faktiske sluttbilder. Se independent-review.md og den tilhørende JSON med30 bildehasher.

Publiseringskvittering: artefakt10733424420, ZIP SHA256 5c5bfd9a9799ac1e79311948b30132180254430fba891575a97dfa797de66166. Rollback til DEV15: artefakt10733913517, SHA256 a0b70e1bbe465efea7e48bf494a8e7babc06bb33c1386409e315cb3e1989dc70. Ni LIVE-filer og ni historiske Worn-filer er bevart identisk. Ingen ny eksport, opplasting eller testing trengs for denne uendrede godkjente kandidaten.
