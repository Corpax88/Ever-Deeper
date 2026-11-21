# Mossvein – 21. november 2026

Utgangspunktet er Mossvein-grenen a34fed1 og de tre konseptarkene fra 14. november. Den nye stien følger gangkorridoren til kobberfjellet og avgreningen til gruven. Smia bruker en lav steinovn. Fire kobberbilder følger eksisterende skade og gjenvekst. Skoglaget er dempet og Pappa Hammers eksisterende rigg har mattere materialer.

Godot 4.7.2 startet både prosjektet og testpakken. En test styrte spilleren fra start til fjellet og brukte spillets slagfunksjon til fjellet var tømt. Alle fire kobberteksturer ble vist av spilllogikken. Testen kjørte uten grafisk vindu. Pakken bygger på DEV15.61 og inneholder de opprinnelige native helteressursene. To nye ressurs-ID-er falt tilbake til korrekt filsti i testpakken.

Neste steg er visuell gjennomspilling på Mac eller iPhone. Kontroller særlig stiens kanter, smieskiltet og hakkeanimasjonen. Endringene er ikke publisert til DEV eller LIVE.

## Mac-test gjennomført 21. november

[Kjøring 44952345388](https://github.com/Corpax88/Ever-Deeper/actions/runs/44952345388) brukte arbeidsgrenens spillendringer 330b759 og testoppsett 468b1aa. Kandidatens SHA-256 er 3eb3eb38bad290acf1f55d346f1711aa5a0ff6cf22ebccf38c97e552bb3e9df3 (329361974 byte). Arbeidsflyten moss-test.yml gjenskaper og tester kandidaten med Godot 4.7.2 på macOS 15.

9 kontroller bestod ved hver av 667×375, 844×390 og 932×430: faktisk bildestørrelse, smiekontekst, gange til fire punkter, fjellkontekst, fire skadetrinn og tømt fjell. Inputtesten bestod. WebKit 26.5 kjørte ordinær oppstart, nytt spill, lagring, gjenlasting og bekreftelse av nytt spill. Bevisarkiv 14726481818 inneholder logger og rapporter samt 18 native skjermbilder og seks fra WebKit. Alle 24 ble gjennomgått. Fjellet endrer tydelig silhuett, men skog, terreng og portal er fortsatt mer detaljrike enn konseptarket. Fysisk iPhone og ytelse er ikke testet. Ingen publisering.

## Publisert på DEV 21. november 2026

[Spill DEV](https://corpax88.github.io/Ever-Deeper/dev/). Publiseringen bruker de ni filene fra Mac-testens manifest, inkludert versjonsstrengen DEV15.61. [Kjøring 44954137085](https://github.com/Corpax88/Ever-Deeper/actions/runs/44954137085) verifiserte samtlige 26 offentlige filer. Publiseringskvittering 14727241699, rollback 14726444828. LIVE1.0.5 og Worn er bevart.

[Versjonsnotat](https://ever-deeper-game.corpax88.chatgpt.site/patch-notes.html#mossvein-painted). Nettsidens kilde b756df8fd580d9c0b68ec336a9002010a7d1b2c5, versjon 15, publisering appgdep_6b02151bcd908191ae4f1a38e162a855 bekreftet. Neste manuelle kontroll er spillfølelse på fysisk iPhone.
