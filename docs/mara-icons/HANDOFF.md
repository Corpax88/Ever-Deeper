# DEV15.67 · Mara og handlingsikoner

Mara puster rolig når hun står i ro og nikker når spilleren velger TALK. Animasjonen beveger overkroppen og hodet med føttene forankret. Den følger spillets innstilling for redusert bevegelse.

| Handling | Ikon |
| --- | --- |
| TALK | Snakkeboble |
| DESCEND og DEEPER / ASCEND | Trapp og pil ned / trapp og pil opp |
| EXIT og RETURN / OPEN / SEALED | Utgangsdør / portal / hengelås |
| SELL og SELLING / FORGE og FORGING / BUILD | Gullbarrer / ambolt / verktøy |
| DELIVER og LOAD / ATTACH ROPE / PLACE | Pakke / tau / relikviesokkel |
| BROWSE og INSPECT / POWER / STABILIZE og OVERLOAD | Lupe / lyn / skjold og energivarsel |
| LIGHT LAB / WARDROBE / TREASURY / HUB | Lykt / kleshenger / kiste / base |
| TUNNEL HOME | Muldvarpen som frakter deg hjem |
| SKILLS | Sammenkoblede ferdighetsnoder |

Kontrollhjelpen viser de samme symbolene som HUD. Nye handlingsnavn uten symbol vises med tekst.

## Test og publisering

Kilde `7c4b2a792926569dde6bf55373ca80bf5786c0c1`. Bygg med `python3 .github/mara-icons/package.py /sti/til/godot /sti/til/DEV15.66/index.pck /sti/til/kandidat` og Godot 4.7.2. DEV15.66 har SHA-256 `aa67b874c55d3710bfcf815f7711c227634c06b4605165ca169ddaf8ce3e7ec6`. DEV15.67 har `f6550a1b18db90495b9c19fa473d3ec711a45bd940b58012b33f1485c3a233ef`.

[Mac-test](https://github.com/Corpax88/Ever-Deeper/actions/runs/45060450248) besto 114 kontroller på 667×375, 844×390 og 932×430. Den åpnet faktisk samtale med Mara, kontrollerte nikket, sjekket at oppdraget fortsatt registreres og at redusert bevegelse slår av animasjonen. De øvrige ikonene ble kontrollert ved å sette handlingsknappen til hver testede handling. [Bilder og rapporter](https://github.com/Corpax88/Ever-Deeper/actions/runs/45060450248/artifacts/14769442047). Den ordinære WebKit-testen dekket oppstart og lagring. Fysisk iPhone gjenstår.

[DEV15.67](https://corpax88.github.io/Ever-Deeper/dev/) er publisert. [Publiseringskvitteringen](https://github.com/Corpax88/Ever-Deeper/actions/runs/45060806123/artifacts/14768972931) bekrefter alle 26 offentlige filer. [Rollback til DEV15.66](https://github.com/Corpax88/Ever-Deeper/actions/runs/45060806123/artifacts/14769492261).
