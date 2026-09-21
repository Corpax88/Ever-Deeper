# Ever-Deeper — Worn publisert; klar for iPhone-test

## Hold chatten lett
Ingen binærarkiver eller base64 gjennom verktøyargumenter/resultater, heller ikke skjult i code-mode. De 43 payload-delene er allerede commit-et. Bruk eksisterende git-objekter og CI-artefakter. Ikke eksporter, last opp eller kjør Mac-suiten om igjen for denne uendrede kandidaten.

## Nå
- Repo: Corpax88/Ever-Deeper. Arbeidsgren: codex/hero-loop-flow-20260918.
- Runtime-kandidat: e32a03e620913a76f3bee9083b2e9b1d66eef972.
- Testet Mac-revisjon: fd95be111fde7b2599bfbae5239f66c2bc6a3cbb.
- Uavhengig gjennomgang og review lagret på grenen i 80fd100cbf994f457932830ab79a1640fc179d5d.
- Publiseringscommit på main: 133aa31ed2a72be21558f041ed7f94891f205638. Bare trial-underkatalogen og dens eksisterende workflow er lagt til; spillkilden er ikke slått sammen.
- Publisering bestått: https://github.com/Corpax88/Ever-Deeper/actions/runs/35591010824
- Alle 27 offentlige filer er verifisert mot forventet størrelse og SHA256: 18 eksisterende DEV13/LIVE-filer uendret, 9 testfiler lagt til.

## Ferdig kontroll
Mac-kjøring 35553114935 besto klar, held mining, walk exit, reset, touch mining og touch walk. Chromium 151.0.7922.34, macOS arm64, ANGLE Metal Apple Paravirtual device. CSS/PNG 844×390, DPR 2, drawingbuffer 1688×780.
Alle seks originale PNG-er er nå sett av uavhengig kritiker. Avgrenset testversjon er godkjent. Rapportens ni filidentiteter samsvarer nøyaktig med bundle.json. HP 500→476, reset=1; tastatur/touch stopper etter slipp.
Liten kjent tekstforskjell: hjelpen sier HUGG, knappen heter MINE. Ingen ombygging er nødvendig for denne testen.
Kritikk, originale kontrollrapport-bytes og hashbundet review er lagret i .github/native-flow-trial/evidence/ og review.json. Eksisterende publisher check-review besto.

## Identitet og bevis
- PCK SHA256: 74db0719dc5d151e0ad9491e9c5e90769c6f85ff8f8db07fe55c4b825277da05.
- bundle.json SHA256: 26209f2eeeefa1688d8fd954b701dd02e4a00dbba74274271b4f3aa5d55765dd.
- Browserrapport SHA256: b4dc1a5312bd71a6334ad3d6a83c6ec9f9c4ebfb1f44bed05d11b6f8ab92993a. Bevar bytes uten ekstra linjeskift.
- Review SHA256: 7d18c921bdd0223de5ad436ee386f669259cbf1dd23e0da168d07a634fc3fd31.
- Mac-artefakt native-worn-mac-browser: ID 10619416142, ZIP 3165723 byte, SHA256 77bc3b7075c37cb1cff8e0189481373b5327b2d9809fb87e9c2b05d11d82e755, beholdes til 21. oktober 2026.
- Hent eksisterende artefakt med GitHub download_workflow_artifact og materialiser filreferansen med prepare_materialize. Ikke returner URL eller binærinnhold til modellen.
- Primær grafisk rute: .github/workflows/verify-native-worn-trial.yml. Gjenbruk beviset for uendret kandidat.

## Publiseringsbevis
Kjøring 35591010824 besto package, deploy og verify på commit 133aa31ed2a72be21558f041ed7f94891f205638. Kvitteringen er lastet ned og sammenlignet med baseline.json og bundle.json; alle 27 filidentiteter samsvarer.
Kvittering: .github/native-flow-trial/evidence/publication-receipt.json. SHA256 b63a5061dd768cc4c341f4c1599fba523431d780e66c34d3d90532a40e586138. Artefakt-ID 10634023429; ZIP SHA256 f6d721959cd149bb1d295807ea5c3ba7badc9006c075b0a3f7c5169a0c278edb. Rollback-artefakt med gamle bytes er beholdt av workflowen.

## Neste steg
Spillbar testlenke: https://corpax88.github.io/Ever-Deeper/dev/worn/
Mats tester i Safari i liggende visning: hold MINE ved malmen, slipp, gå og start igjen. Be om konkret tilbakemelding på flyten før neste animasjonsendring. Ikke start bred testing eller nye eksportforsøk uten en konkret feil.
Normal animasjonsflyt ved normal hastighet, fysisk iPhone og FPS er fortsatt ikke bevist. Ingen generell animasjonsscore eller 1.0-godkjenning.
Godkjent v28/studie20, støttehåndslipp og modell/materialer beholdes. Ordinær Flow20 er deaktivert; FPS-arbeid pauset. Kodeopplasting, Mac-QA og gated additiv DEV-test er allerede godkjent. Norsk, maks fem korte linjer.
