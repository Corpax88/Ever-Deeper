# Ever-Deeper — DEV14.2 publisert og verifisert

Oppdatert 21. september 2026. Dette er gjeldende status.

[Vanlig DEV](https://corpax88.github.io/Ever-Deeper/dev/) viser **1.0.0-dev.14.2**. Publiseringsrun **35618558489** besto package, deploy og verify. Alle **27 offentlige filhasher** er kontrollert: ni nye DEV-filer, ni uendrede LIVE-filer og ni bevarte historiske Worn-filer. DEV-adressen og lagringsnavnerommet er beholdt.

## Hva som er rettet

**Figuren ble klippet bort under styring.** Små, stadige joystick-korreksjoner startet en uferdig 120 ms vending på nytt ved alder null. Figuren hang igjen i verdenskoordinater mens renderflaten fulgte spilleren. Vendingen fullfører nå sin opprinnelige frist mens retningen oppdateres. Handlingsoverganger og godkjente animasjonsdata er beholdt.

**Figurens renderkostnad er redusert.** En bygg-generert indeks-LOD2 fra den samme modellen reduserer antall vertices fra 1 033 415 til 124 069 og trekanter fra 1 017 723 til 86 653. Alle valgte vertexattributter, skjelett, skin-bindinger, teksturer, lys og animasjonsdata er bevart. Kvitteringen markerer geometrien som avledet, ikke identisk. Ingen ny figur eller animasjonsproduksjon.

## Kontrollert

- Native klipperegresjon: originalen ga 24 helt tomme bilder i en 72-bilders styringssekvens. Rettet sekvens ga ingen klipping, minste margin 55 px.
- Eksportert Chromium/Metal, 844 × 390 DPR 3: 72 styringsprøver uten klipping, minste margin 35 px. Utstyr, verdensbytte, mining, touch, pause og faktisk bevegelse etter resume besto. 22 originale bilder gjennomgått.
- 36 parvise native modellrendere: minste silhuett-IoU 99,688 %. Uavhengig kritiker godkjente figurens synlige kvalitet i denne sammenligningen og i den endelige eksporten.
- Åtte 15-sekunders Mac-vinduer med mining og etterfølgende idle: 53,60–59,76 gjennomsnittlige nettleser-rAF-bilder/s, med aktive oppdateringer av figuren. Dette er 120 sekunders visningsmåling; ikke 120 sekunder med uavbrutte hakkeslag.
- Normal Mac WebKit 26.5: New Game → Surface, pause, omlasting av lagring, New Game med erstatningsbekreftelse → Surface. Seks originale bilder, ingen rapportert feil eller krasj.
- Input, 1255 gameplay-kontroller, 125 touch-kontroller og eksportert DEV/save-flavor besto.

## Begrensninger

**Stabil FPS på fysisk iPhone er fortsatt ikke bekreftet.** Mac-målingen bruker nettleserens rAF, og enkelte pauser nådde 400 ms. Ikke beskriv dette som stabil frame pacing, en fysisk iPhone-test eller en prosentvis FPS-forbedring. Tidligere New Game-krasj på telefonen er heller ikke sertifisert løst.

De andre visuelle kvalitetsfunnene fra brukerens video er ikke generelt friskmeldt: slag/treff, pet-overlapp, fjelloverganger, material/lys, lesbarhet og FPS-panelet. Ikke start ny figur- eller animasjonsproduksjon automatisk.

Invariantkontrollen har fortsatt de dokumenterte avvikene for `project.godot`, `hero_gear.gd`, `player_controller.gd` og `player_visual.gd`. Den er ikke feilfri.

## Eksakt kilde og bevis

Repo: `Corpax88/Ever-Deeper`. Spillkilden ligger på `codex/hero-loop-flow-20260918`; main inneholder publisering og bevis og er ikke eksportgrunnlaget.

| Del | Identitet |
| --- | --- |
| Publisert spillkilde | `bee888fe36d6b8285e1198384d40694d3154956a` |
| Bestått kandidat-run | `35616856586` |
| Publiseringscommit | `bba1e16ec9f84d9971e480623a9ecc5ddb92dc9d` |
| Publiseringsrun | `35618558489` |
| Kandidatartefakt | `10646730333` |
| PCK | 236 963 468 byte; SHA256 `c0f0a04cb94193dd4806de41c18ac238a171b94ba4e7f99b5bec2f9f59d38a7f` |
| Publiseringskvittering | `.github/dev14/evidence/publication-receipt.json` på main; SHA256 `2c7d435b4828137fcfd41b50606cf581a9bf787d8d4efb5c7717c8aed4a2dac5` |
| Kvitteringsartefakt | `10647483302`; ZIP SHA256 `ce121e29f72027b8ee275d00b04fd5d141534ab694638063f01ec08157dcf352` |
| Rollback til DEV14.1 | Artefakt `10647752019` fra publiseringsrun; ZIP SHA256 `6c219fd6e61d211277456e28376999e2306add0befecf6fed1357ceb901fbab7` |

Kandidat-ZIP: `5fe8eee6a1a2fa004e184ee2c36707d4cfa9e43a3b3c60030105cbc8943b7a90`.
Browserartefakt `10647155795`, WebKit `10646976052`, build/core `10646810128`. Uavhengig sluttkontroll: `.github/dev14/evidence/independent-review.json`. Publisheren binder målingene til samme pakke, kontrollerer implementasjonshasher ved kildecommit og krever minst 50 rAF-FPS i hvert Mac-vindus gjennomsnitt.

`Ever-Deeper-DEV14.2-regresjonsbevis.zip` inneholder native-parene, alle 28 Mac-originalbilder og testdata. Library-ID: `libfile_46b7f3a1ff2c81918bfc8e6b6a7f1eb6`, versjon 1. Den opprinnelige videovurderingen er bevart i `Ever-Deeper-DEV14.1-videofunn.md`; brukerens video har Library-ID `libfile_965a948ad1348191bfa75ee2b961a549`.

## Fortsett uten å gjenta arbeidet

Ingen eksport, opplasting, test eller publisering gjenstår for denne kandidaten. Senere dokumentasjonscommits endrer ikke spillbytes. Første run 35616450072 stoppet på et foreldet QA-versjonskrav; dette er allerede rettet og erstattet av det beståtte løpet.

Ved nytt telefonbevis: kontroller at menyen viser **14.2**, sammenlign styring og vedvarende FPS med videoen fra 14.1, og hold faktiske observasjoner atskilt fra antatte årsaker. Ikke start de tidligere uavklarte simulatorforsøkene på nytt automatisk.

Scratch: `/workspace/scratch/3e70e4e0152f`. Repo: `Ever-Deeper`. Bevis: `runtime/ci142-browser`, `runtime/ci142-webkit`, `runtime/ci142-build`, `runtime/ci142-publication`. Original 14.1-PCK er hashkontrollert i `runtime/dev14.1.pck`. Ikke før binærdata/base64 gjennom verktøyargumenter eller resultater; bruk filreferanser og materialisering.

Mats ønsker korte norske svar, normalt høyst fem linjer. Les gjeldende AGENTS og handoff før videre arbeid. Bevar godkjent figur, animasjonsgrunnlag, LIVE-bytes og DEV-lagring.
