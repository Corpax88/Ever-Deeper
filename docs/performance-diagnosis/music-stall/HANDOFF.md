# Ever-Deeper — musikkhakk redusert, publisering holdes
27. september 2026, overlevering etter fullførte tester. Offentlig DEV15.10 er uendret. Ingen jobber i denne oppgaven behøver videre venting. Brukeren vil bytte chat; ikke be om ny kjør-bekreftelse. Hold svar korte og unngå å gjenta fullførte tester.

## Gjeldende kilde og grenser
Repo Corpax88/Ever-Deeper. Publisert runtime ab0c12ff579134e0a092946bd92973e4599a073c på codex/canvas-cpu-dev15-10-20260925. Main er kun publiseringsbærer med historisk runtime: aldri bygg fra main. Fysisk iPhone-rapport39,23FPS under204,75s aktiv graving er fortsatt uløst. Ikke kutt lys, grafikk, oppløsning, musikk eller kjæledyr. Ingen fysisk-iPhone-godkjenning fra Mac.

## Implementert kandidat, ikke publisert
Ren DEV15.11-kilde ba396beeed9e587a8dc700edef7b28b79f1095d6 på codex/music-dev15-11-20260927. Sluttvalidering36303234754 besto seks eksporterte coretilfeller og vanlig WebKit oppstart, lagring og reload; seks faktiske sluttbilder uavhengig godkjent visuelt/kodemessig. Ingen samlet ytelses-/publiseringsgodkjenning.
- AudioDirector klargjør tre private ikke-loopende MP3-streams under lasting og gjenbruker dem.
- Eksakt Godot-export index.js kopierte hele PCM-bufferen i Sample.getAudioBuffer(), både ved start og restart. Kandidaten returnerer eksisterende buffer for spor over10s; nye avspillingsnoder, offset, gain og crossfade beholdes. I denne pakken er bare de tre musikksporene lange.
- JS-patch er fail-closed med eksakt baseline-manifest og ett treff. Alle1413 øvrige opprinnelige PCK-ressurser uendret. Spillendring er audio_director; premium_menu og visual_capture_driver har kun15.11-versjon. Engine-WASM, art/lys/figurer uendret.
- Ren byggkode og originalmanifest: .github/music-release/ på kandidatgrenen. Ingen ny eksport nødvendig.
- Kandidatartifakt10925867913,268971672bytes,SHA256521b677923e1fcfb64d84e8c9f23c8e4201e02a59c44bc0ef3a3bd7bfdbd4155.
- Core10926347253,6148bytes,SHA256a48d2181474e2124a70f5b69244a98592f04cd3a33720bfa06b1b389ef252af9.
- Startup10926079486,14510255bytes,SHA256578f039185ff0d27c1ae3f8d7ebeb8073b76a8e208e3660edf9101eab708ed09.
Alle tre ZIPer ble kontrollert mot størrelse/SHA/CRC og alle ni kandidatfiler mot manifest. Tidlige bygg8b55 feilet gammel QA-versjon;01fa hadde trunkert overføring av QA-kildefilen, rettet fullt i ba396. Ikke tell disse som spillregresjon.

## Fullførte musikkforsøk
1. Kun forhåndslasting3cb2b27/run36241633136 feilet i begge Macer: stadig nye PCM-kopier, audio.play opptil177ms. Ikke gjenta.
2. PCM-gjenbruk74dbb7e5364fb284a2d7244909bdae160b9fa5d2 på codex/music-stall-20260926, run36302925861:56kontroller per arbeider; naturlig90s bevegelse/graving og seks tvungne låtbytter per modus. Audio.play166/200ms til0/1ms naturlig;299/273ms til1/1ms ved tvungne bytter. Kandidatens lange buffere3→3, referanse6→28. Faktisk lyd målt. Fire faktiske bilder uavhengig inspisert.
   MEN gjennomsnittsFPS43,775→41,633 og37,545→33,241 (ca-4,9%/-11,5%). Publisering ble holdt. Begge moduser forhåndslaster3samples, så dette er ikke urørt15.10-startup/memory-sammenligning. Referanse lager i tillegg nyMP3 og PCM-kopi ved start.
   Artifakter10926431926/10926039111; eksakt størrelse/SHA/CRC tidligere verifisert.
3. Livssyklus1fc410178f2cfa9cb67384967106dac8bfe31f00 på codex/music-lifecycle-20260927/run36303158117:41kontroller hver i AppleWebKit og ChromiumMetal. Faktisk lyd i alle3spor; samme spor samtidig med uavhengig offset/stop; pause/resume; volum0 målt stille; mute under overlap; bufferantall forblir3. Artifakter10926531295/10925604968 verifisert. Første b4b870-test brukte ChromiumSwiftShader og feil db-grense som ignorerte+7,9dB trackgain; korrigert test uten spillkodeendring.
4. Fast arbeidsmengde48adeab3d270db17b5a094bc57e9a5771e3d855e på codex/music-steady-20260927/run36303367261: samme context, cachedMP3 i begge moduser, kun JS-copy/reuse veksles;15s oppvarming, fire20s ABBA-vinduer, fast posisjon/durable blokk/aktiv mining. Begge besto men kandidatens aggregat ca2,3% og3,3% lavere med stor tidsdrift. Artifakter10925923163/10926457313 verifisert. Ikke nok til å godkjenne.

## Siste test — ferdig analysert 27.09 kl12:50 norsk tid
Kilde0f2177679036b0116e3e6325c5034b07ded4503e, gren codex/music-paired-20260927, run36303672796. Begge jobber success,16vinduer hver. Tidlig b918/run36303603153 kansellert for å legge til minnetelemetri før aksept.
Åtte balanserte tilstøtende AB/BA-par per arbeider,8s hvert vindu etter1,5s settling, samme faste aktive miningbelastning. Full legacy duplicate+copy versus cached+shared. Alle outliers beholdt. Krav fastsatt FØR resultatene i docs/performance-diagnosis/music-stall/PAIRED-CRITERIA.md: nedre95% paret t-intervall over-2%, hver arbeiders punktestimat over-2%, riktige arbeidsmengder og vurdert minne-carryover.
- Arbeider1: paret gjennomsnitt-0,138%.
- Arbeider2: paret gjennomsnitt+4,697%.
- Samlet16par:+2,280%,95% t-intervall[-4,826%,+9,385%]. IKKE bestått forhåndsdefinert ikke-forverring. Ikke endre grensen eller bruk grønn workflow som ytelsesgodkjenning.
- WeakRef-registrerte fortsatt levende lange lyddata vokste fra3–5 til11–12buffere, omtrent92–156MB til345–377MB. Det er en konkret carryover-bekymring; må ikke kalles bevist lekkasje uten å skille fortsatt registrerte samples fra forsinketGC. Referanseperioder lager ekstra buffers som kan påvirke senere kandidatperioder. Ingen tvungetGC eller PCM-lesing under måling.
- Artifakt10926766018 music-paired-1:4473620bytes,SHA256defe06f7b7f92317ce1e04b8b0d51de2910c391a23030e8167709071641c9a85.
- Artifakt10926453048 music-paired-2:4469624bytes,SHA2567a82a14c78eed47b78b39e07e11cf72b23e327177964597a3071a562828e28e4.
Begge fullstendig nedlastet og størrelse/SHA/ZIPCRC verifisert; rapportene inneholder alle vinduer, liveBuffers, RSS og bilder. Lokal kopi music-results/, men tidligere scratch ble ryddet automatisk; GitHub-grener/artifakter er autoritative.

## Neste steg
Behold15.11 som upublisert kandidat. Undersøk levetid/registrering av lydsamples og carryover i siste rårapporter før ny testdesign; ikke kjør enda en uendret FPS-runde eller publiser på bakgrunn av usikkert snitt. Det konkrete musikkhakket er adressert og funksjonene verifisert, men vedvarende FPS og ikke-forverring er ikke etablert. Ikke be Mats teste telefonen som om løsningen er ferdig. Det foreligger stående autorisasjon til videre arbeid og DEV-publisering etter faktiske kvalitetskrav, ikke til å kalle usikre resultater godkjent.

Eldre aktiv-graving-profil: engine d4fede99/run36241264270 lokaliserte182ms i AudioDirector før215msramme. Stabil terrengbuffer2710ddb/run36240109179 ble forkastet, ingen ny test av samme hypotese. Lys/pet er ikke etablert hovedårsak til dette musikkhakket. Det fulle eldre checkpointet nedenfor er historikk, ikke gjeldende status.
