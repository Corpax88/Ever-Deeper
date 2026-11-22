# DEV15.65 · Første oppdrag med Mara

Mara står ved veien i Mossvein. Spilleren kan snakke med henne, samle tre salgbare malmstykker, gå forbi SELL-boden og vende tilbake. Delvise salg teller med og samme salg teller én gang. Oppdraget lagres med ekspedisjonen. Eldre lagringer med oppgradert hakke får ikke oppdraget automatisk. Det tidligere tastatur- og berøringskurset er fortsatt tilgjengelig via Settings → Controls → Replay Guide.

Salgsanimasjonen bruker SELLING. Meldingene, kartet og veivisningen bruker vanlige engelske ord som sell og sale.

## Bygg og test

Spillkilde `5f0389e80a85dd7836f2162b673834068b6d612f`, gren `codex/mossvein-painted-20261114`. Bygg med Godot 4.7.2 og `python3 .github/camp-quest/package.py /sti/til/godot /sti/til/DEV15.64/index.pck /sti/til/kandidat`. Verifisert DEV15.64-PCK har SHA-256 `e8ef59e1e3f3a23e6c1ec5e8dbd54f5ec5c29298282f4476e1fdbb0aa2925448`. Kandidatens SHA-256 er `b326e0984886a5f59235ed66c187bf17e0e13ae2062fc45390e34712ccb852ac`.

[Mac-gjennomgang](https://github.com/Corpax88/Ever-Deeper/actions/runs/45048101412) besto 69 kontroller på 667×375, 844×390 og 932×430. [Testbilder og rapporter](https://github.com/Corpax88/Ever-Deeper/actions/runs/45048101412/artifacts/14764786023). Quest-sjekken går til Mara med vanlig bevegelseslogikk, bruker den vanlige kontekstknappen for samtale og gruveinngang, legger inn en testlast med malm, utløser det automatiske salget og fullfører oppdraget. Den sjekker lagring, eldre lagring, delvise salg og at samme transaksjon ikke registreres to ganger. Oppstart og lagring testes også i WebKit.

De eldre testene for handelspanel og malformede journaldata feiler likt i DEV15.64 og DEV15.65. Mara-oppdraget og meldingsendringen har egne kontroller. Fysisk iPhone er ikke testet.

## Publisering

[DEV15.65](https://corpax88.github.io/Ever-Deeper/dev/) er publisert. [Publiseringskjøringen](https://github.com/Corpax88/Ever-Deeper/actions/runs/45048528598) verifiserte alle 26 offentlige filer. [Publiseringskvittering](https://github.com/Corpax88/Ever-Deeper/actions/runs/45048528598/artifacts/14765085622) og [rollback til DEV15.64](https://github.com/Corpax88/Ever-Deeper/actions/runs/45048528598/artifacts/14764811469).
 
Frisk start viser Mara ved campveien. Viderekomne spillere kan fortsette en eksisterende ekspedisjon. Test TALK, SELL og retur til Mara på en fysisk iPhone når det passer.
