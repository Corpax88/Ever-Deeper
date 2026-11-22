# DEV15.66 · Møt Mara underveis

Mara gir nye oppdrag når en mekanikk blir aktuell. Spilleren møter henne på veien i regionen, i Hub eller inne i Deepheart. Graving og salg avslutter fortsatt med en fysisk innlevering. De øvrige oppdragene følger milepæler som spillet allerede lagrer. Oppdragsaksept lagres separat, slik at et oppdrag spilleren har hørt kan fortsette etter omstart.

Gult `!` betyr at et oppdrag er tilgjengelig. Grått `?` betyr at oppdraget med innlevering pågår. Gult `?` betyr at innleveringen er klar. TALK er tilgjengelig i samtaleavstand. Oppdragene følger forge, regionale porter, første skjulte sjakt, Ember Mastery, Starforge, Hub, drill, Singularity, Deepheart, The Deep, relikvier og verksteder.

## Bygg og test

Kilde `f5f628532970220218c989550a93515cd6b41249`. Godot 4.7.2 og den publiserte DEV15.65-pakken danner grunnlaget. Bruk `python3 .github/mara-progression/package.py /sti/til/godot /sti/til/DEV15.65/index.pck /sti/til/kandidat`. DEV15.65-PCK har SHA-256 `b326e0984886a5f59235ed66c187bf17e0e13ae2062fc45390e34712ccb852ac`. Testpakken har SHA-256 `aa67b874c55d3710bfcf815f7711c227634c06b4605165ca169ddaf8ce3e7ec6`.

[Mac-gjennomgang](https://github.com/Corpax88/Ever-Deeper/actions/runs/45058829721) besto 87 kontroller på 667×375, 844×390 og 932×430. Kontrollen dekket oppdragsmarkørene, TALK, autosalg, fysisk innlevering, første smikjøp, portåpning, sjakt, de fire overflateområdene, Hub, Deepheart og overgangen til relikvieoppdraget. WebKit-gjennomgangen testet oppstart og lagring. [Testbilder og rapporter](https://github.com/Corpax88/Ever-Deeper/actions/runs/45058829721/artifacts/14769205201). Fysisk iPhone gjenstår.

[DEV15.66](https://corpax88.github.io/Ever-Deeper/dev/) er publisert. [Publiseringskvitteringen](https://github.com/Corpax88/Ever-Deeper/actions/runs/45059236401/artifacts/14769205984) bekrefter alle 26 offentlige filer. [Rollback til DEV15.65](https://github.com/Corpax88/Ever-Deeper/actions/runs/45059236401/artifacts/14769050957).
