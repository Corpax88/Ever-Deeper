# Ever-Deeper — testmiljø og gjenoppretting

## Fast regel — 14. september 2026

Klargjør og reparer testmiljøet automatisk når en spillchat starter eller fortsetter. En feil ved første oppstart eller i skybrowseren skal føre til gjenoppretting og prøving av den etablerte alternative ruten, ikke et avsluttende svar om at testing ikke går. Mats skal ikke måtte be om samme reparasjon igjen. Fortsett den opprinnelige spilloppgaven etterpå.

Bruk ferdigheten `game-test-environment` (Spilltesting og overlevering). Oppdater denne handoffen ved milepæler; oppbevar eksakt kilde, kommandoer, versjoner og bevis. Gi korte resultatmeldinger, maks fem linjer. Ingen løpende feil-logg i chatten. Ikke påstå at tester har passert uten kjøring og faktisk inspeksjon.

Den etablerte Mac-ruten er en macOS-arbeider i GitHub Actions med Apple GPU. Safari-appen kjøres i iPhone Simulator gjennom Appium/XCTest. Det er en fungerende skytestrute, ikke en dokumentert dedikert Mac mini med SSH. Den brukes uten å be om gjentatt klarsignal innen eksisterende autorisasjon. Den gir ikke bevis for fysisk iPhone-FPS eller varme. Bevar tilgang, arbeidsgren og prosjektets publiseringsregler.

## Gjeldende kilde

Komplett Godot-kilde i `Corpax88/Ever-Deeper`, main ved overtakelse `d4619e5429326b880c4da2d466a2bf5351f0f46c`. Les `README.md`, `AGENTS.md`, `docs/code-map.md`, `docs/verification.md`. Gamle August-notater om distribusjonsrepo alene er foreldet. Godot 4.7.2 og matchende eksportmaler; `tools/qa.py` og `tools/capture-web.mjs` eier testing.

## Grafisk gjenoppretting

Først prøv kjøreverktøyet på nytt; tidligere handshake-feil er ikke nåværende diagnose. Hent verktøy fra de versjonene prosjektets workflow angir, sjekk arkivets integritet og kjør `--version`. Historisk scratch-ZIP med Godot-navn var ufullstendig; ikke gjenbruk den ukritisk.

Eksisterende eksport/grafikk: `.github/workflows/hero-v28.yml`, `.github/workflows/hero-v28-environment.yml`, `.github/workflows/hero-v28-motion.yml`, `scripts/dev/visual_capture_driver.gd`, `tools/capture-web.mjs`. Enkelte historiske workflows peker mot bestemte gamle run-ID-er. Bruk et eget kandidatoppsett bundet til gjeldende kilde, ikke gamle artifacts som ny godkjenning.

Ved behov for Mac: bruk en separat QA-gren i Ever-Deeper. Dokumentert eksempel finnes i Plingdal `tests/cloud/README.md` eller privat `Corpax88/Inkcremental` gren `codex/plingdal-3d-qa` (`plingdal-qa/` og `.github/workflows/plingdal-3d.yml`). Mac GPU, WebKit og iPhone Safari/Appium er fungerende ruter. Bevar isolasjon og ikke overskriv andre spills QA-grener. Linux/SwiftShader er tidligere brukt til faktiske Godot-bilder.

## Nåværende oppgave

Tilpass bare helterenderingen til den eksisterende 2D-verdenen. Behold godkjent Gruvepappa v28, proporsjoner, ansikt, klær, briller, hjelm, rigg, animasjoner og gameplay. Bruk den faktiske Blender-kilden og `tools/hero_v28/export_hero.py`. Første leveranse er sammenlignbar før/etter i uendret faktisk miljø, med visuell kritiker. Mats skal se sammenligningen før produksjonssprites erstattes.

Kildene er bevart som `Ever-Deeper-hero-dark-eyes-v28.zip` og `/Ever-Deeper/Ever-Deeper-dad-v9-native-source.zip`; hent via filnavn dersom lokale arbeidskopier mangler. Ikke legg personlige referansebilder i offentlig repo. Modell og fungerende native verktøy er ikke i spillrepoet.

## Bekreftet ved oppstart 14. september

Kjøreverktøyet fungerer igjen; aktuell kilde er hentet og eksisterende Mac-/Safari-testoppsett er funnet i varige prosjektfiler. Dette er ikke en ny grafisk godkjenning. Se videre bevis og neste steg i den visuelle oppgavens handoff etter at test-renderen er laget.


## Gjenoppretting fullført i denne chatten

14. september 2026: Godot 4.7.2 og Blender 4.5.3 LTS starter og den originale v28-scenen åpnes. Native Godot/OpenGL 4.5/Mesa llvmpipe har rendret Surface, Mossvein, Moonglass og Hub med faktisk spillkilde. Skjermbilder: `/workspace/scratch/ed13a852ef8e/review/`. Dette er kildebasert visuell mockup, ikke godkjent eksport/browser/FPS eller publisering.

Kjør `tools/run_rendered_isolated.py` med Godot-binær og en Xvfb-rot. Denne chatten hentet godot-binæren fra den offisielle 4.7.2-releasen, Blender fra `download.blender.org/release/Blender4.5/blender-4.5.3-linux-x64.tar.xz`, og pakket ut Ubuntu-pakkene xvfb 21.1.12-1ubuntu1.8, libxfont2 2.0.6-1build1, x11-xkb-utils 7.7+8build2, libxkbfile1 1.1.0-1build4 i `bin/xvfb`. `xkbcomp` må finnes der Xvfb forventer den; den manglet, og ble lagt i `/usr/bin/xkbcomp` uten å endre tilgangsregler. Den varige ferdigheten inneholder eksakte nedlastingsadresser og den testede gjenopprettingsmåten. Ikke endre apt-sandbox eller X11-autentisering for å få det til.

## Lagring og godkjenning

Den generelle ferdigheten `game-test-environment` er installert og verifisert etter lagring; `SPILL-TESTMILJO-HANDOFF.md` er separat bevart. Plingdal-dokumentasjonen ble lagret på kanonisk kildegren `codex/test-recovery-rule-20260914`; gjeldende publiserte Site og nyere QA-kilde ble bevart.

Automatisk godkjenningskontroll avviste Ever-Deeper-push til main (delt standardgren) og senere til ny gjennomgangsgren (påstått uverifisert offentlig kildeutlevering). Ingen alternativ GitHub-skrivemåte ble brukt for å omgå dette. Ever-Deeper-dokumentendringene er foreløpig lokalt committet på `codex/hero-style-review-20260914`, ikke bekreftet på fjernlager. Godkjent bruk av ny gren er nødvendig dersom disse repo-endringene skal deles via GitHub. Den installerte generelle rutinen fungerer uavhengig av dette.

## Siste visuelle checkpoint

`tools/hero_style/render.py --style relief` gir en statisk materialprøve fra den originale Blender-modellen; `capture.gd` lager fire faktiske før/etter-par uten produksjonsbytte. `compose_review.py` lager sammenligningsarket og bekrefter identiske omgivelser. Bevis i `/workspace/scratch/ed13a852ef8e/review/relief/`; kildeprøve i `review/relief-render/iron/`. Godot og Blender avsluttet med kode 0, og `tools/check_invariants.py` bekreftet 1139 beskyttede filer / 56 QA-oppføringer.

Varige leveranser heter `Ever-Deeper-hero-materialstudie.zip`, `Ever-Deeper-hero-materialstudie-HANDOFF.md` og `Ever-Deeper-hero-sammenligning.png`. ZIP-en inneholder den avledede Blender-scenen, renderen, faktiske bildepar og rapporter. Modellgeometri/rest-rigg er identisk; nåværende prøverender har SHA-256 `670064a137bce1d216f6f066d7aa7d4a9eb75fd8e7ef6667b1eb3e1862c37df8`.

Uavhengig kritiker: klar til å vises som statisk materialforslag, men ikke ferdig samsvar med miljøets art style. Mindre glans og bedre struktur; hjelm/hud/klær er fortsatt enklere enn miljø/muldvarp, og varmt hotspot ved hånd/spenne består. Vis Mats den konkrete sammenligningen før sprites erstattes. Ikke omtal dette som godkjent animasjon, eksport, fysisk iPhone-test eller ferdig stilintegrasjon.

## Ny bekreftet Mac-runde — materialstudie v2

Se [gjeldende materialstudie](hero-world-material-v2-HANDOFF.md). Brukeren autoriserte uttrykkelig Mac-ruten og kritiker i denne oppgaven. QA-grenen `codex/hero-world-material-v2-20260914` er opprettet og endringene er fjernlagret. Mac-run `34839522693` rendret fire faktiske miljøpar på Apple Paravirtual GPU via ANGLE Metal. Bevar VIEWPORT i fixture slik at Mac-skjermens vindusgrense ikke forvrenger proporsjonene, og rapporter faktisk teksturstørrelse. Tidligere notat om avvist push gjelder den gamle økten, ikke denne autoriserte og fullførte QA-grenen.
