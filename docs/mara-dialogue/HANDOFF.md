# DEV15.68 · Snakkeboble hos Mara

Alle replikkene til Mara vises i en snakkeboble som følger henne i skjermbildet. Bobla lukker seg når spilleren går unna, åpner menyen eller lesetiden er ute. Hvis spilleren vil høre instruksen igjen, kan de bruke TALK på nytt.

## Test og publisering

Kilde `413f4d62acdb00e534861bad7fd242dae2b3a9e7`. Bygg med Godot 4.7.2 og `python3 .github/mara-dialogue/package.py /sti/til/godot /sti/til/DEV15.67/index.pck /sti/til/kandidat`. DEV15.67-PCK har SHA-256 `f6550a1b18db90495b9c19fa473d3ec711a45bd940b58012b33f1485c3a233ef`. DEV15.68-PCK har SHA-256 `9d12678f76ce9aa7e3c59accd13ea561994309ad8a3f6d0f9c587d8a6fe4eb18`.

Mac-kjøringen besto 45 kontroller på 667×375, 844×390 og 932×430. Den testet den faktiske TALK-knappen, tekstbryting, forankring når kameraet flytter seg, og at bobla lukker seg riktig. WebKit besto oppstart og lagring. [Testbilder og rapporter](https://github.com/Corpax88/Ever-Deeper/actions/runs/45066884379/artifacts/14771159754).

[DEV15.68](https://corpax88.github.io/Ever-Deeper/dev/) er publisert. [Publiseringskvitteringen](https://github.com/Corpax88/Ever-Deeper/actions/runs/45067245372/artifacts/14771409599) bekrefter alle 26 offentlige filer. [Rollback til DEV15.67](https://github.com/Corpax88/Ever-Deeper/actions/runs/45067245372/artifacts/14771369604).
