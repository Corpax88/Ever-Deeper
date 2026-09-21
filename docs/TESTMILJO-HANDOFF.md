# Ever-Deeper — Mac-test bestått; hold neste chat lett

Repo: Corpax88/Ever-Deeper. Gren: codex/hero-loop-flow-20260918.
Testet revisjon: fd95be111fde7b2599bfbae5239f66c2bc6a3cbb.
Runtime-kandidat: e32a03e620913a76f3bee9083b2e9b1d66eef972.
Ingen ny spillversjon er publisert.

## Ferdig
- Alle43 eksakte payload-deler ligger allerede commit-et i .github/native-flow-trial/. Ikke eksporter eller last opp pakken på nytt.
- Mac-kjøring35553114935 besto alle6 faktiske kontroller: klar, held mining, walk exit, reset, touch mining, touch walk.
- Rapporten er lest og alle9 filhasher er sammenlignet med bundle.json. HP500→476 ved held mining; reset=1. Tastatur- og touchslipp ga stabil posisjon og mining=false.
- Chromium151.0.7922.34, macOS arm64, ANGLE Metal Apple Paravirtual device. CSS844×390, DPR2, drawingbuffer1688×780, faktiske PNG844×390.
- Første Mac-kjøring35543977206 feilet på tidsgrense. Den nye brukte den etablerte Metal-konfigurasjonen. Spillpakken, tidsgrenser og kontrollkrav ble ikke endret. To eksakte, ufarlige UID-varsel-linjer beholdes i rapporten; andre feil feiler fortsatt testen.

## Bevis
- Bestått kjøring: https://github.com/Corpax88/Ever-Deeper/actions/runs/35553114935
- Artefakt native-worn-mac-browser, ID10619416142,3165723 byte, tilgjengelig til21.oktober2026.
- ZIP SHA256:77bc3b7075c37cb1cff8e0189481373b5327b2d9809fb87e9c2b05d11d82e755.
- report.json SHA256:b4dc1a5312bd71a6334ad3d6a83c6ec9f9c4ebfb1f44bed05d11b6f8ab92993a.
- PCK SHA256:74db0719dc5d151e0ad9491e9c5e90769c6f85ff8f8db07fe55c4b825277da05.
- bundle.json SHA256:26209f2eeeefa1688d8fd954b701dd02e4a00dbba74274271b4f3aa5d55765dd.
- GitHub-artifactverktøyet gir en filreferanse. Bruk prepare_materialize med denne til lokale bytes; direkte URL-nedlasting ga403. Ikke returner URL eller binærinnhold til modellen.

## Minste gjenværende steg
1. Hent siste gren og det eksisterende, beståtte artefaktet. Ikke kjør Mac-suiten om igjen med uendret kandidat.
2. Fullfør uavhengig vurdering av de seks faktiske PNG-ene og rapporten. Kritikerens kildegransking var godkjent; en endelig bilderapport er IKKE bekreftet lagret. Tidligere agent/lokal kopi forsvant ved avbrudd og automatisk opprydding.
3. Lag hashbundet review.json først etter faktisk godkjenning. Publiser kun additiv dev/worn via eksisterende publisher/workflow; bevar18 DEV13/LIVE-filer og verifiser27 offentlige filer.
4. Vanlig animasjonsflyt ved normal hastighet, fysisk iPhone og FPS er ikke bevist av disse stillbildene/kontrollene. Brukeren skal få teste dette på iPhone.

## Ny obligatorisk regel: ingen tung data gjennom chatten
Store base64-overføringer via exec-resultater og create_blob-argumenter førte sammen med arbeidsloggen til gjentatte for-lange-chat-avbrudd. Å la være å skrive dem med text() var ikke tilstrekkelig.
IKKE gjenta denne ruten, heller ikke inne i code-mode. Ingen flere binærarkiver som tekst i verktøykall/resultater.
Bruk direkte filopplasting, git eller eksisterende CI/artefakter. Hele spillpakken er allerede opplastet; bare små tekstkvitteringer og endelig godkjenning mangler. Sluttartefaktet trenger ikke kopieres inn som en ny Git-blob.
Ikke gjenta beståtte tester, gamle registre, store logger eller historikk. Lag korte, avgrensede kontrollpunkter. Bevar denne regelen øverst i AGENTS.md og neste overlevering.

Godkjent v28/studie20, støttehåndslipp og modell/materialer beholdes. Ordinær flow er deaktivert; FPS-arbeid er pauset. Kodeopplasting, Mac-QA og gated additiv DEV-test er allerede godkjent. Norsk, maks5korte linjer.
