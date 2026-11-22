# Mossvein · stier og kollisjon

DEV15.63 knytter gangområdet i Mossvein til de synlige kantene på hovedveien, leirplassen, gruverampen og gruveavsatsen. Grenen ned til gruva følger den malte rampen, og bakkelagene tones inn der leirveien og rampen møter hovedveien. Malm, bygninger og portalstøtter har kollisjon rundt foten. Den låste Moonglass-portalen stopper spilleren ved den synlige sperren. Posisjoner i eldre lagringer som havner utenfor de nye kantene, flyttes til nærmeste trygge område.

## Reproduser

Bruk Godot 4.7.2 og eksakt publisert DEV15.62 som basis. PCK SHA-256 er `00cb1a0249be72b16fa41d4bb3605c1369a86b12a490aff1d7c4c9acd6d990a7`. Bygg med `python3 .github/moss-test/prepare.py /sti/til/DEV15.62/index.pck /sti/til/kandidat`. Test i grafisk modus med `python3 .github/moss-test/mac.py /sti/til/godot /sti/til/kandidat/index.pck /sti/til/bevis`. Lokal reserve er Xvfb/Mesa llvmpipe med autentisert TCP-display i samme prosessmiljø. Den vanlige Mac-ruten er `.github/workflows/moss-test.yml`, med egen inputtest og vanlig oppstart, lagring og gjenlasting i WebKit.

Kilde `0e099d04cc8ecf5fde9de22012ab846c48d2cb2c`. Kandidat-PCK er 328 951 206 byte, SHA-256 `187cc463b48a93fcfe8b89595e2ca68a357d8de8134c3c2964c4d3baa5d3aa2f`. Lokal Godot/Mesa bestod 126 kontroller i 667×375, 844×390 og 932×430 og separat inputtest. Bildene dekker leiren, avkjøringen ned til gruva, landingen, åpen og lukket portal og alle fire kobberstadiene. Fysisk iPhone-ytelse er ikke målt.

## Verifisert publisering

- [Mac QA 44975809561](https://github.com/Corpax88/Ever-Deeper/actions/runs/44975809561) bestod 126 kontroller og separat inputtest. Bevisarkiv 14735259007 har 33 native bilder og seks WebKit 26.5-bilder. WebKit kjørte ved 844×390 og DPR 3 med vanlig oppstart, lagring og gjenlasting. Bildene ved leir, gruve og portal er gjennomgått.
- [DEV15.63](https://corpax88.github.io/Ever-Deeper/dev/) er publisert. Kjøring 44976219608, offentlig kvittering 14735793050. Alle 26 offentlige filer ble verifisert. Rollback 14736290399 inneholder DEV15.62.
- [Versjonsnotat](https://ever-deeper-game.corpax88.chatgpt.site/patch-notes.html#mossvein-walkable-terrain) er publisert i nettstedsversjon 17. Kilde `efc08bea6ec437b91d19c01eb068c073a42b4996` og publisering `appgdep_6b025464f3a4819192cfaddb179e80e5`. 90 versjonsnotater og 250 lokale lenker verifisert.
