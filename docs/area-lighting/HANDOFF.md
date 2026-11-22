# DEV15.69 · Gruvelykter og veibelysning

Stående oljelykter markerer gruveinnganger, åpningene ved sperringer, sjakter og arbeidsplassene på dyp 2. Overflaten og huben bruker lykter på trestolper ved gruveinnganger, heiser og salg. Lyktene er dekorative og beholder områdenes farge og eksisterende lysbudsjetter. The Deep bruker hodelykta og det eksisterende lyset fra relikviene.

## Bygg og gjenta testen

Godot 4.7.2. Hent de ni DEV15.68-nettfilene fra sikkerhetskopien og kjør `python3 .github/area-lighting/package.py /sti/til/godot /sti/til/DEV15.68/index.pck /sti/til/kandidat`. Pakkeverktøyet kontrollerer SHA-256 for grunnlaget, importerer de to PNG-ene og verifiserer alle videreførte PCK-filer. Kjør `python3 .github/area-lighting/render.py /sti/til/godot /sti/til/kandidat/index.pck /sti/til/testbevis` i et grafisk miljø. Arbeidsflyten `area-lighting.yml` kjører samme sjekk og ordinær WebKit-oppstart med lagring. Se også [testoppsettet](../TESTMILJO-HANDOFF.md).

Lokal kjøring i Godot med Mesa llvmpipe dekket 95 kontroller og 14 bilder i hver av 667×375, 844×390 og 932×430. Fysisk iPhone-ytelse er ikke målt.

## Verifisert kandidat

Kanonisk spillkilde `858ad3adf3eb75841050193c5c0444403f538977` på `codex/area-lighting-20261123`, basert på DEV15.68 og Mara-dialogen. Kandidatens PCK er 319 876 770 byte, SHA-256 `30519ae8c2d988147cb5c7f0dfbfecdf636ba1090696753f909398ea34fbcc68`. Samme pakke ble bygd to ganger lokalt og også av Mac-kjøringen.

[Mac-test 45083438851](https://github.com/Corpax88/Ever-Deeper/actions/runs/45083438851) bestod 95 kontroller og skrev 14 faktiske skjermbilder ved hver av de tre størrelsene, med ANGLE Metal. Landinger varierer med gruvefrøet. Alle 42 skjermbilder ble kontrollert i kontaktark, og representative Emberdeep- og hubbilder også i full størrelse. WebKit bestod vanlig oppstart, lagring og gjenlasting. [Testbevis 14778288246](https://github.com/Corpax88/Ever-Deeper/actions/runs/45083438851/artifacts/14778288246).

Oppdater DEV-siden og trykk Continue. Emberdeep-inngangen fra skjermbildet og hubens heis gir de raskeste visuelle sjekkene.

## Publisert 23. november 2026

[DEV15.69](https://corpax88.github.io/Ever-Deeper/dev/) ble publisert fra `d1448add6090b6eec4e39f1f89e317871ffcc054`. [Publiseringskvitteringen](https://github.com/Corpax88/Ever-Deeper/actions/runs/45083945802/artifacts/14778442655) dekker de 26 offentlige filene. LIVE og Worn deler fortsatt den verifiserte motoren. [Rollback til DEV15.68](https://github.com/Corpax88/Ever-Deeper/actions/runs/45083945802/artifacts/14778600968).

[Endringsloggen](https://ever-deeper-game.corpax88.chatgpt.site/patch-notes.html#area-lighting) er oppdatert. Site-kilde `d73f48276041237fe0fe0e77345f07d3de38875f`, versjon 18, publisering `appgdep_6b037cf498188191b872ea2c9afbaddc`. 91 utgaver og 251 lokale lenker ble kontrollert.
