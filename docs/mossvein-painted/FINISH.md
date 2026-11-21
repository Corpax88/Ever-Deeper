# Mossvein · helhetlig overflate

Startpunkt: publisert DEV15.61, PCK SHA-256 `3eb3eb38bad290acf1f55d346f1711aa5a0ff6cf22ebccf38c97e552bb3e9df3`.
Kandidaten for DEV15.62 er en visuell oppfølging av tilbakemeldingen på dette bygget. Den myke håndmalte Mossvein-konseptretningen er målet. Terreng, leir, salgsbod, gruverampe og -inngang, portal, skoglag og de nærmeste Moonglass-flatene har egne produksjons-PNG-er i `assets/surface/painted/`. Stien ligger i de malte terrengbildene. Den mørke streken som lå som et ekstra lag er fjernet.

Pappa Hammer og muldvarpen bruker de eksisterende riggene og animasjonene. Smia og kobberfjellets fire stadier bruker den godkjente leveransen fra DEV15.61. Gangruter, kollisjon, portalkrav, minespill, lagring og HUD beholder eksisterende implementasjon.

## Test

Vanlig Mac-rute: `.github/workflows/moss-test.yml` importerer grafikken med Godot 4.7.2 og bygger fra nøyaktig DEV15.61. Den samme pakken kjøres i native ved 667×375, 844×390 og 932×430 samt med vanlig oppstart og lagring i WebKit. Bildeserien dekker salgsbod, smie, fire kobberstadier, gruveinngang og portalen fra begge sider. `review.gd` følger eksisterende gangruter og venter på portåpningen før den går gjennom. Lokalt kjøres samme native bilde- og inputtest med Mesa llvmpipe og Xvfb.

Ved ny lokal kjøring, bruk den beholdte DEV15.61-pakken og Godot 4.7.2. Kjør `godot --headless --editor --import`, `python3 .github/moss-test/prepare.py /sti/til/DEV15.61/index.pck /sti/til/kandidat` og `python3 .github/moss-test/mac.py /sti/til/godot /sti/til/kandidat/index.pck /sti/til/bevis` med et grafisk skrivebord. På Debian 13 fungerer Xvfb 21.1.16 med autentisert TCP-display i samme prosessmiljø. Mac-kjøringen har kontrollen for vanlig WebKit-oppstart. Fysisk iPhone krever egen test.
