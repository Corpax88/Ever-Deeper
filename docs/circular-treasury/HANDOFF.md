30 September 2026, renewed explicit user authorization: “Jeg uttrykkelig godkjenner fremtidig opplastninger av ever-deeper”. This covers future uploads of Ever-Deeper to the existing public Corpax88/Ever-Deeper repository, with the established QA and DEV publication flow. The prior automatic push denial is resolved by this new direct approval. Do not ask again. LIVE promotion remains separate.

# Ever-Deeper — sirkelrom klart lokalt, DEV15.30 ikke publisert
30. september 2026. Mats ba om rundt skattekammer, levering i sentrum med ressurser utover og vanlig gangåpning på høyre side av hubben, ingen portal. «Fikser du?».

- Implementert fra eksakt publisert gameplay34b96d5990c2c17d85d4b0e26e2bba1b05fef826; arbeidsmappe /workspace/scratch/c75108525bd2/game, gren codex/circular-treasury-20260930. Bevar eksisterende godkjente PNGer, Deep Events, regnskap og saves. Rommet er en teksturert rund/oval sal med27plasser rundt kanten, sentrert plate, vekslende materialpakker. Hubens østvegg har fysisk åpning; vanlig bevegelse inn/ut, ingen interaksjonsknapp. Nye romgrenser/kamera følger rommet.
- Lokal Godot4.7.2/Xvfb/Mesa25.2.8 llvmpipe1688x780: premium-core299 bestått før siste rene etikettplassering. Egen ekte holdt-input-test9/9 bestått: gå inn, nå midtplaten, lande/sende pakker, gå ut, beholde restlast, gå inn igjen, runde vegger/sentrum. Endelig visual-only sjekk dekker etikettjusteringen. Ingen fysisk-iPhone/FPS eller browsergodkjenning. Eksisterende invariant «QA flag order or arguments changed» består som kjent gjeld.
- Kritisk: git push ble AVVIST av automatisk godkjenningskontroll i denne turnen: eksport av mulig sensitiv kildekode til ekstern GitHub krever eksplisitt brukerautorisasjon til push/publisering. Ingen fjernbranch eller CIjobb opprettet. Tidligere generelle/eksplisitte godkjenninger er dokumentert, men denne kontrollen avviste likevel. Ikke omgå via API eller alternativ transport. Be om konkret samtykke til å laste opp denne rettelsen til offentlige Corpax88/Ever-Deeper, kjøre Mac-QA og publisere DEV etter beståtte gater.
- Lokal Chromium recovery forsøkt én installasjonsoperasjon; pinned Playwright1.62 CDN returnerte195bytes HTML istedenfor Chrome151 ZIP. Native grafikk og holdt input fungerer; autorisert Macworkflow er klar etter opplastingssamtykke. FPSarbeid parkert. LIVE uendret; public DEV15.29.
- Gjenoppretting etter scratchtap: «Ever-Deeper-sirkelrom-checkpoint.zip» inneholder komplett git-diff fra kanoniskbase, endrede kildefiler, testdriver, konkrete bevis og manifest. Klon kanonisk base; git apply changes.patch. Bygg med .github/deep-treasury/build.py mot akseptert15.28-artifact11056132610/run36617600791; script beholder samtlige15.29endringer og merker15.30. candidate-v4 er nyeste lokale pakke. Ikke byggmain. Neste: push etter ny eksplisitt autorisasjon, Macworkflow deep-treasury.yml, inspiser browserbilder og vanligWebKit, deretter adaptér immutablepublisher fra main til15.30 med gjeldende27publichash. Ingen publisher for15.30 er kjørt/akseptert.

Tidligere publiseringsstatus og historikk følger:

---


# Circular treasury — DEV15.30 candidate

Mats requested correction of DEV15.29: round room, donation at its centre with items flying to surrounding piles, walk-through opening in hub east wall instead of portal. Explicit “Fikser du?” authorizes this correction; established public repo, QA and DEV publication approval continues. LIVE is separate.

Canonical base34b96d5990c2c17d85d4b0e26e2bba1b05fef826. All previous Deep Events, donation ledger and authored assets preserved. Round textured floor and authored rock circumference, all27 bays on one ring, east hub opening/west room exit crossed using ordinary movement. Player and camera bounds follow room. Materials alternate during the long donation animation. Save schema and debit-on-landing unchanged.

Initial actual native render:299 checks passed on Godot4.7.2 / Mesa25.2.8 llvmpipe,1688x780. Inspected round mature room and hub opening; labels refined afterwards. Native evidence alone is not browser acceptance. Mac Chromium walk-in/out, central delivery, pause, conservation, save/reload and ordinary WebKit are required next. No physical iPhone or FPS claim. Existing historical invariant debt remains.

Build retains verified exact15.28 base and replaces all15.29 source changes plus this correction; retained PCK resources are byte-checked by builder. Never build historical main. Build/test entry .github/workflows/deep-treasury.yml on codex/circular-treasury-20260930; final review and publication must bind the actual commit/artifact.
