# Oppdatert 2. oktober 2026 — DEV15.47: godkjent smieikon publisert

Den godkjente transparente hakke/ambolt-PNGen brukes nå på Tool Forge-knappen ved smia i hubben. Tekst, trykkflate og handling beholdt; øvrige kontekstikoner uendret. Mats godkjente bildet og ba eksplisitt om implementering. Ingen save- eller gameplayendring. Oppdater DEV → Continue; gå bort til den bygde Tool Forge i hubben.

Kanonisk kilde bcf4358c8dee12427dd81b625f69a0c90c4f8804 på codex/forge-icon-20261002 i Corpax88/Ever-Deeper, basert på eksakt DEV15.46. Mac37016720756 bestått input,414core,19browser-observasjoner og vanlig WebKit oppstart/lagring/reload. Faktisk AppleMetal/DPR2,667/844/932 mobilbredder; ekte touch åpner korrekt verksted. Alle13 Mac-sluttbilder inspisert. Native Godot4.7.2/Xvfb:8 kontroller bestått og3 kandidatbilder inspisert, pluss baseline-sammenligning. Uavhengig kritiker godkjente faktisk knapp og åpen smie, ingen blokkeringer. Ni pakkefiler matcher native/Mac. Ingen fysisk-iPhone/FPS-påstand; kjent invariant flag-order-testgjeld beholdt.

Publisering54b77157a4bcc7fce54212aca4bf8938b7b8c61c/run37017501263 bestått. Kvittering11231710979 bekrefter27 offentlige filhasher; LIVE1.0.4 og Worn bevart. Kandidat11231660144/evidence11231445230; rollback11231465938 beholder DEV15.46. Ingen ventende jobber/godkjenninger. Main er publiseringsbærer, aldri bygg historisk main-runtime. Ikke gjenta uendrede godkjente tester. Detaljer docs/forge-icon/HANDOFF.md og .github/forge-icon/publication-receipt.json.

Ikonretningene fra denne chatten er lagret i Ever-Deeper-ikonvalg-2026-10-02.txt. Bare smieikonet ble implementert nå; neste ikon krever eget bilde/godkjenning. Godkjent originalasset: assets/ui/tool-forge-approved-v1.png på kildegrenen.

---

# Tool Forge icon — DEV15.47 candidate

User approved the single transparent pickaxe/anvil PNG and requested integration. Only the Tool Forge context action icon changes; caption, hitbox, actions, economy and saves remain unchanged. Parent gameplay source 74d63df43fbc2a6054280a384a34e2eb9b9f810b, immutable DEV15.46 artifact11216365939/run36981607422. Main is publication carrier only.

Local Godot4.7.2/Xvfb/Mesa rendered actual candidate1688x780. Eight checks passed including real forge proximity, correct icon/caption, open correct menu, adjacent Light Lab icon preserved, disabled/hidden states. Three captures inspected; independent critic accepted actual normal/open captures without blocking changes. Not physical iPhone evidence.

.github/forge-icon/build.py verifies nine baseline files and all retained resource payloads. Exact approved PNG is retained in assets/ui/tool-forge-approved-v1.png, lossless Godot texture imported with4.7.2. Browser QA checks667/844/932 widths, actual touch opens correct workshop and closes, adjacent workshop unaffected; ordinary WebKit startup/save checks also required. Publication pending passing QA and final capture inspection. LIVE1.0.4/Worn protected. Local runtime: /tmp/bore-runtime/Godot_v4.7.2-stable_linux.x86_64 and workspace runtime/xvfb/usr/bin/Xvfb (libXfont2/libxkbfile extracted); tools/run_rendered_isolated.py provides task-local authentication and user save isolation.

## Accepted QA
Mac37016720756 succeeded. All19 browser observations, input and414 premium-core checks passed. Ordinary WebKit startup/pause/save/reload/new-game passed. Actual AppleMetal/DPR2,667/844/932 mobile widths. All13 final Mac images inspected, and nine package files match native candidate exactly. Candidate11231660144; evidence11231445230. Known historical invariant flag-order failure retained honestly. No physical-iPhone/FPS claim. Independent critic accepted actual native icon and open-menu images; no blocking changes. Accepted immutable publication prepared under .github/forge-icon.
