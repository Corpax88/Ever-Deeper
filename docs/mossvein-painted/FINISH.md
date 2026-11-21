# Mossvein · helhetlig overflate

Startpunkt: publisert DEV15.61, PCK SHA-256 `3eb3eb38bad290acf1f55d346f1711aa5a0ff6cf22ebccf38c97e552bb3e9df3`.
Kandidaten for DEV15.62 er en visuell oppfølging av tilbakemeldingen på dette bygget. Den myke håndmalte Mossvein-konseptretningen er målet. Terreng, leir, salgsbod, gruverampe og -inngang, portal, skoglag og de nærmeste Moonglass-flatene har egne produksjons-PNG-er i `assets/surface/painted/`. Stien ligger i de malte terrengbildene. Den mørke streken som lå som et ekstra lag er fjernet.

Pappa Hammer og muldvarpen bruker de eksisterende riggene og animasjonene. Smia og kobberfjellets fire stadier bruker den godkjente leveransen fra DEV15.61. Gangruter, kollisjon, portalkrav, minespill, lagring og HUD beholder eksisterende implementasjon.

## Test

Vanlig Mac-rute: `.github/workflows/moss-test.yml` importerer grafikken med Godot 4.7.2 og bygger fra nøyaktig DEV15.61. Den samme pakken kjøres i native ved 667×375, 844×390 og 932×430 samt med vanlig oppstart og lagring i WebKit. Den ferdige pakken utelater de tre gamle importene for terrenghyllen, skogpanoramaet og forgrunnsrammen som ikke har referanser etter utskiftingen. Originalbildene er beholdt i Git. Bildeserien dekker salgsbod, smie, fire kobberstadier, gruveinngang og portalen fra begge sider. `review.gd` følger eksisterende gangruter og venter på portåpningen før den går gjennom. Lokalt kjøres samme native bilde- og inputtest med Mesa llvmpipe og Xvfb.

Ved ny lokal kjøring, bruk den beholdte DEV15.61-pakken og Godot 4.7.2. Kjør `godot --headless --editor --import`, `python3 .github/moss-test/prepare.py /sti/til/DEV15.61/index.pck /sti/til/kandidat` og `python3 .github/moss-test/mac.py /sti/til/godot /sti/til/kandidat/index.pck /sti/til/bevis` med et grafisk skrivebord. På Debian 13 fungerer Xvfb 21.1.16 med autentisert TCP-display i samme prosessmiljø. Mac-kjøringen har kontrollen for vanlig WebKit-oppstart. Fysisk iPhone krever egen test.

## Verifisert og publisert

- Kilde `186095564ca58af25f20b38298589c1a390d5339` på `codex/mossvein-painted-20261114`. Endelig PCK er 328 947 934 byte med SHA-256 `00cb1a0249be72b16fa41d4bb3605c1369a86b12a490aff1d7c4c9acd6d990a7`.
- [Mac-test 44957971064](https://github.com/Corpax88/Ever-Deeper/actions/runs/44957971064) har 22 godkjente kontroller i hver av 667×375, 844×390 og 932×430. De 30 native bildene og de seks fra vanlig oppstart, pause, lagring og gjenlasting i WebKit 26.5 er gjennomgått. Bevisarkivet er 14728084331. Lokal Mesa llvmpipe-kjøring bestod også 66 kontroller med den endelige pakken. Fysisk iPhone-ytelse gjenstår.
- Inputtesten bestod. De separate testene `overhaul`, `premium-core` og `one-point-zero-world` hadde også feil i DEV15.61. `overhaul` forventer den gamle testversjonen DEV15.11. De to andre ga samme feil for Treasury-mål og slag mot en generert forekomst i begge pakker.
- DEV-publisering `f150c1713a85a5e1b211c6bb69ecd55935f4b18c`, [kjøring 44958625783](https://github.com/Corpax88/Ever-Deeper/actions/runs/44958625783), kvittering 14727624654. Alle 26 offentlige filer er verifisert, inkludert åtte LIVE-filer og ni Worn-filer. Rollback 14728572446 inneholder DEV15.61. [Spill DEV](https://corpax88.github.io/Ever-Deeper/dev/).
- [Versjonsnotat](https://ever-deeper-game.corpax88.chatgpt.site/patch-notes.html#mossvein-painted-finish) er publisert i nettstedsversjon 16. Kilde `1149513c1c0434bf2a3a7510974d13905fabdce1`, publisering `appgdep_6b0221059de48191962b6bb0a6522568`. Verifisert 89 versjonsnotater og 249 lokale lenker.
