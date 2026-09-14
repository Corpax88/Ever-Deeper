# Ever-Deeper — materialstudie v2, 14. september 2026

Mats ba om en ny mockup som passer bedre i den eksisterende verdenen, med avtalt Mac-testmiljø og uavhengig kritiker. Dette er bare en statisk materialprøve; ingen produksjonsatlas, gameplay, animasjoner eller publiserte bygg er endret.

## Kilde og endringer

- Kanonisk main kontrollert gjennom GitHub: `d4619e5429326b880c4da2d466a2bf5351f0f46c`.
- Isolert fjernlagret gren: `codex/hero-world-material-v2-20260914`.
- Første kandidat: `9581b51d2872cae4260fb66e50fc2ba9ef4fbdeb`; finjustert kandidat: `ea18d194b09d0fd5dbd49545b3a280fa2502f0bf`; rettet Mac-opptak: `3a747ea85bf6e68f6f943b6b9eb1d69a01263f5c`.
- Original v28 Blender-scene SHA-256: `94304c12a042b168c0d655dc0ceacffe2efb08997039a7a26c1ed0cc1770bc91`.
- Geometri/rest-rigg-fingeravtrykk før/etter er identisk: `9c454e0a3092fec33afc4451a61b438d8716db37e55ba069a6c0452fec10e338`.
- Native exporter, kamera, posering, klær og identitet er beholdt. `render.py --style world` beholder opprinnelige fargekart, bruker materialspesifikk mellomskala for stoff/metall/lær, normalstruktur og kontaktokklusjon. Emissiv planskyggelegging fra første prøve er erstattet av diffus materialrespons. Støvlene ble dempet og metallresponsen finjustert etter kritikk.
- Blender 4.5.3 LTS, Cycles CPU, 48 samples, 480×480 RGBA. Godot skalerer prøven til den opprinnelige 160×160-cellen. Kun iron/down/idle-frame 0 er prøvd.

## Lokal bevisføring

Arbeidskopi `/workspace/scratch/5f2517b9e058/ever-deeper`; bevis `/workspace/scratch/5f2517b9e058/review/refined-captures`; native scene og frame under `review/refined-render/iron`.

Godot 4.7.2, OpenGL/Mesa llvmpipe LLVM 20.1.2 under isolert Xvfb. Viewport 1864×860, logisk 1560×720. Surface, Mossvein, Moonglass og Hub ble fanget før/etter med pause innen hvert par og skjult HUD. Kandidatteksturen byttes bare i minnet; originalen gjenopprettes. Alle piksler utenfor heltens område er identiske innen hvert par. Renderer og eksakte SHA-er finnes i `capture-report.json` / `style-report.json`.

`tools/check_invariants.py`: 1139 beskyttede filer og 56 QA-oppføringer bestått. Godot og Blender avsluttet med kode 0. Ingen fysisk iPhone-, animasjons- eller browsergodkjenning.

## Kritiker

Uavhengig visuell agent så faktisk sammenligningsark og native render. Første kandidat: 7/10; mer naturlig stoff/lær, men flekkete støvler og for lite metallfølelse. Etter justering: 7,5/10 i stilintegrasjon, presentabel som ny mockup og tydelig bedre enn både produksjonssprite og forrige materialprøve. Ansiktet er fortsatt lesbart; ingen vesentlige stillbildeproblemer som krevde ny runde. Dette er ikke full stilperfeksjon eller produksjonsgodkjenning.

## Mac-rute og neste steg

`.github/workflows/hero-world-material.yml` kjører samme testfixture på `macos-15`, med Godot 4.7.2. Workflow er avgrenset til QA-grenen, har `contents: read`, checkout uten lagrede credentials og ingen publisering. Bare skript og render-PNG er sendt; original Blender-modell og personlige referanser er ikke lagt på GitHub. Mac-versjon, faktisk GPU, kandidat-SHA og skjermbilder følger Actions-artifact.

Vis Mats sammenligningen før produksjonssprites byttes. En eventuell implementering krever separat eksport av alle berørte frames, kontroll av antrekksmasker, retninger og bevegelse, og visuell verifikasjon i ekte spill. Ikke gjør dette automatisk ut fra godkjenning av å lage mockup.

## Mac-opptak: oppløsning

Første Mac-run `34839143688` beviste ekte Apple GPU: `ANGLE (Apple, ANGLE Metal Renderer: Apple Paravirtual device, Version 15.7.9 (Build 24G830))`, macOS 15.7.9. Alle fire miljøpar ble rendret. Kandidat SHA samsvarte. Mac-vinduet ble imidlertid begrenset til 1024×656, slik at CANVAS_ITEMS + IGNORE forvrengte proporsjonene. Disse første Mac-bildene er teknisk bevis, ikke endelig presentasjon.

Fixture bruker nå VIEWPORT for å bevare logiske proporsjoner uavhengig av skjermens størrelse. Rapporten henter faktisk renderoppløsning og vindusstørrelse, og komposisjonsverktøyet tilpasser utsnittene til bildeoppløsningen. Lokal kontroll ga 1418×654 (spillets eksisterende content_scale_factor påvirker intern oppløsning), med korrekt format og identiske miljøpiksler innen hvert par.

Hvis GitHub artifact-download leverer file_id men signert URL ikke kan hentes fra runtime, bruk Library prepare_materialize med den eksakte returnerte file_id og filnavnet; dette leverte bytes direkte i Work-workspace. Bekreft artifact SHA-256 før utpakking. Ikke bruk tidligere Mac-artifact som bevis for en nyere kandidat.

## Endelig Mac-bevis

Run `34839522693`, testet commit `3a747ea85bf6e68f6f943b6b9eb1d69a01263f5c`, fullførte ekte native Godot-opptak på macOS 15.7.9 / ANGLE Metal Apple Paravirtual device. Intern capture er 1418×654 med riktige proporsjoner; OS-vinduet var 1024×656. Alle fire før/etter-par er kontrollert. Artefakt `10345626951`, ZIP SHA-256 `a8d22d9dd058bc3c163b3656876119adb40da00c55d34d3926e190d225f16234`.

Endelig render-PNG SHA-256: `fb31ec920efdf2fd6bba419a94469ab59b82d8a0f42cc78fb8d518124c3b79ef`. Samme SHA finnes i alle fire Mac-caser. Komposisjonsverktøyet bekreftet uendrede miljøpiksler utenfor heltens område. Endelig sammenligning: `Ever-Deeper-material-v2-Mac.png`; fulle faktiske Mac-bilder under `review/final-mac`. Dette er verifisert Mac/native-stillbilde, ikke Safari/iPhone Simulator eller fysisk iPhone-FPS.

Neste steg: Mats vurderer ny materialmockup. Produksjonssprites skal ikke byttes før han har godkjent retningen.

Endelig uavhengig Mac-kritikk: 7,5/10; presentabel som ny mockup. Materialene passer bedre inn, og ansikt/silhuett fungerer også i faktisk spillstørrelse. Ingen vesentlig visuell regresjon eller behov for enda en materialrunde. Gjelder bare stillbildene.
