# Ever-Deeper — DEV14.1 publisert
Oppdatert 21. september 2026. Dette er gjeldende status; eldre «pågår»-/«ikke publisert»-notater er historikk.

Vanlig DEV: https://corpax88.github.io/Ever-Deeper/dev/ — menyversjon **1.0.0-dev.14.1**.
Publisering er fullført og godkjent av brukeren. Samme DEV-adresse og lagringsnavnerom er beholdt; alle ni LIVE-filer er uendret.
Ingen ny arena, figur eller animasjon ble laget for denne rettingen.

## Endring og begrensning
Mats viste en fysisk iPhone-video der DEV14 krasjer etter New Game og bekreftelse. Stor runtime-utpakking av figurens GLTF var en påvist oppstartsbelastning; årsaken til selve iPhone-krasjet er ikke bevist.
DEV14.1 laster samme figur som en ferdig forberedt, komprimert PackedScene. Geometri (1 033 415 vertices), skjelett, bindinger, transformasjoner og bevegelse er bevart. Bare innebygde materialer som alltid ble overstyrt, fjernes under forberedelsen; spillets materialer er beholdt.
**Krasjet er ikke bekreftet løst på fysisk iPhone.** Simulatorforsøket ga ikke gyldig spillbevis. Ingen FPS-, samlet minne- eller fysisk iPhone-godkjenning.
Mac WebContent RSS gikk ned, men GPU-prosessens RSS økte. Ikke beskriv dette som 33 % lavere samlet minnebruk.

## Kilde og publisering
Repo: Corpax88/Ever-Deeper. Spillkilden finnes på arbeidsgrenen `codex/hero-loop-flow-20260918`; main inneholder publisering og bevis og er ikke denne spillkildens eksportgrunnlag.
Eksakt publisert spillkilde: `6d6e1b8d98ecae6661b514fff92e28447715dd33`.
Senere arbeidsgren-endringer frem til `f5311101d7d8ec10d675901e3e5034546ccbe6c3` gjelder bare det uavklarte simulatoroppsettet.
Publiseringscommit: `b55ea12202f299d1aac4605c98c1ba9dcab5bbe6`; Actions-run **35610110028**: package, deploy og verify besto.
Alle **27 offentlige filer** er kontrollert mot eksakte hasher: ni nye DEV-filer, ni bevarte LIVE-filer og ni bevarte historiske prøvefiler.
Kvittering: `.github/dev14/evidence/publication-receipt.json` på main; SHA256 `3753b642b3b9769e784fda985635bd3ef267f0ee0c046841f3ae5c4e47e75f2a`.
Kvitteringsartefakt **10644245478**, ZIP SHA256 `c43dffaecd067dac633f08f3b810258ae61cf08653015f438c76dda56dc5404f`.
Eksakt kandidat **10640952568** fra test-run **35604667053**, ZIP SHA256 `0bb49acd6f7991f583624cdf952ae980dfdc67d1469bfbaeae7f4f4ddcc37092`.
Publisert PCK: 255 901 708 byte, SHA256 `510dc3c8768b37ddbc06f0ade5c34b64d927b51a77d958a7366d303d395b9707`.
Rollback før DEV14.1: artefakt **10644200271** fra publiseringsrun, ZIP SHA256 `2ebc6a78870a33ece3a4f1f13389b5199d51f6b43fc5b456d9e03db8444ed447`.

## Hva som er kontrollert
Test-run **35604667053** besto: input-release, 1259 overhaul-kontroller, 125 touch-kontroller og DEV/save-flavor.
Mac Chromium/Apple Metal: 20 originale spillbilder gjennomgått, verktøy/utstyr, Moss/Endless mining, verdensbytte, touch, pause og faktisk bevegelse etter resume.
Normal Mac WebKit 26.5, 844 × 390 DPR 3: New Game → Surface; pause, omlasting av ekte lagring og New Game med erstatningsbekreftelse → Surface. Seks originale bilder gjennomgått; ingen registrert runtime-feil eller nettleserkrasj.
Siste uavklarte iPhone Simulator-run: **35608051678**, artefakt **10642408701**. Safari Start Page ble filmet; intet gyldig New Game-forsøk. Dette er en testoppsettbegrensning, ikke spillgodkjenning eller påvist spillfeil.
Uavhengig sluttgjennomgang er godkjent for denne avgrensede DEV-endringen. `.github/dev14/evidence/startup-review.json` SHA256 `faf1f7557d4373a39ead0607001af7e660b2111e24f51b4a0736317b0e8c1cb5`.
Kjente invariant-avvik for project.godot, hero_gear.gd, player_controller.gd og player_visual.gd er dokumentert; ikke kall invariantkontrollen feilfri.

## Fortsett uten å gjenta arbeidet
Ingen bygg-, opplastings-, Mac-test- eller publiseringsjobb står igjen for denne kandidaten. Senere dokumentasjonscommits endrer ikke publiserte spillbytes.
Neste meningsfulle kontroll er faktisk iPhone-bruk av **1.0.0-dev.14.1**. Ved ny feil: ta utgangspunkt i denne versjonen og konkret video/logg; ikke redesign helteanimasjonen.
Ikke start simulatorforsøkene på nytt automatisk. De er avsluttet som uavklarte, og dokumentasjon av begrensningen er lagret.
Gjenbruk eksisterende artefakter. Aldri før binærdata/base64 gjennom verktøyargumenter eller -resultater, heller ikke inni code mode; bruk filreferanse og materialisering.
Les AGENTS.md, README.md, docs/code-map.md og gjeldende handoff før nye endringer. Bevar godkjente visuelle elementer og eksisterende publiseringskontroller.
Mats ønsker korte norske svar, normalt høyst fem linjer. Ikke påstå at fysisk iPhone-krasj eller alle animasjons-/FPS-mål er ferdig løst.
