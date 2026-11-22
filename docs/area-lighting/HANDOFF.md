# DEV15.69 · Gruvelykter og veibelysning

Stående oljelykter markerer gruveinnganger, åpningene ved sperringer, sjakter og arbeidsplassene på dyp 2. Overflaten og huben bruker lykter på trestolper ved gruveinnganger, heiser og salg. Lyktene er dekorative og beholder områdenes farge og eksisterende lysbudsjetter. The Deep bruker hodelykta og det eksisterende lyset fra relikviene.

## Bygg og gjenta testen

Godot 4.7.2. Hent de ni DEV15.68-nettfilene fra sikkerhetskopien og kjør `python3 .github/area-lighting/package.py /sti/til/godot /sti/til/DEV15.68/index.pck /sti/til/kandidat`. Pakkeverktøyet kontrollerer SHA-256 for grunnlaget, importerer de to PNG-ene og verifiserer alle videreførte PCK-filer. Kjør `python3 .github/area-lighting/render.py /sti/til/godot /sti/til/kandidat/index.pck /sti/til/testbevis` i et grafisk miljø. Arbeidsflyten `area-lighting.yml` kjører samme sjekk og ordinær WebKit-oppstart med lagring. Se også [testoppsettet](../TESTMILJO-HANDOFF.md).

Lokal kjøring i Godot med Mesa llvmpipe dekket 95 kontroller og 14 bilder i hver av 667×375, 844×390 og 932×430. Fysisk iPhone-ytelse er ikke målt.
