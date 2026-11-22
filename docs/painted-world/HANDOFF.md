# Ever-Deeper · håndmalt verden · DEV15.64

Den håndmalte Mossvein-stilen omfatter nå Moonglass, Emberdeep, Starfall, begge gruvenivåer i hver region, hubben, Treasury, Deepheart og The Deep. Oppdateringen dekker terreng, malmstadier, landemerker, portaler, HUD-ikoner og menyer. Den viderefører gangområdet fra DEV15.63.

## Kilde og test

- Spillkilden er `8c3919e8a2a4e04317dbef59f72d6163fe2437e7` på `codex/mossvein-painted-20261114`. Main bærer publisering.
- Bygg den eksakte kandidaten med Godot 4.7.2 og `python3 .github/painted-world/package.py /sti/til/godot /sti/til/DEV15.63/index.pck /sti/til/kandidat`. Pakken krever original-PCK med SHA-256 `187cc463b48a93fcfe8b89595e2ca68a357d8de8134c3c2964c4d3baa5d3aa2f`. Kandidat-PCK er 318 936 686 byte med SHA-256 `e8ef59e1e3f3a23e6c1ec5e8dbd54f5ec5c29298282f4476e1fdbb0aa2925448`.
- [Mac-kjøring 44999677129](https://github.com/Corpax88/Ever-Deeper/actions/runs/44999677129) registrerte 132 kontroller og 66 bilder fra Godot ved 667×375, 844×390 og 932×430. Input og vanlig WebKit-oppstart, lagring og gjenlasting besto. [Bevisarkiv 14744729128](https://github.com/Corpax88/Ever-Deeper/actions/runs/44999677129/artifacts/14744729128) har byggmanifestet, rapportene og de faktiske bildene.
- Supplerende Godot/Mesa-test brukte samme PCK-hash ved 844×390. Moonglass-, Emberdeep- og Starfall-portalen sperret før åpning og lot spilleren gå begge veier etter åpning. Inngang og retur fungerte i alle fire gruver via konteksthandlingen. Rapporten dekker 28 funksjonskontroller og seks bildeopptak. Kjør med `PAINTED_OUT=/sti/til/bevis godot --main-pack /sti/til/kandidat/index.pck --resolution 844x390 --script tools/review_painted_transitions.gd` i et grafisk miljø med isolert lagringsprofil.
- Fysisk iPhone-ytelse er ikke målt.

## Publisering

Publisert til [DEV15.64](https://corpax88.github.io/Ever-Deeper/dev/) 22. november 2026. [Publiseringskjøring 45045557237](https://github.com/Corpax88/Ever-Deeper/actions/runs/45045557237) verifiserte alle 26 offentlige filer. [Publiseringskvittering 14763377836](https://github.com/Corpax88/Ever-Deeper/actions/runs/45045557237/artifacts/14763377836). Rollback 14762564166 inneholder DEV15.63.

Ved neste spilltest, oppdater dev-siden, velg **Continue**, og prøv gruveinngangen samt en åpen portal begge veier.
