# Ever-Deeper — DEV15.2 er publisert

23. september 2026. **Det godkjente verktøyikonet er publisert på https://corpax88.github.io/Ever-Deeper/dev/.** Hammer/skiftenøkkel i tre, stål og messing erstatter den flate SVG-en på Skills-knappen øverst til venstre. Knappen beholder120×120 logisk trykkflate; bildets breddegrense104 gir samme optiske størrelse som kompasset. Ikoner/layout inne i Skills er uendret.

Kanonisk spillgren: `codex/approved-tools-icon-20260923`, repo `Corpax88/Ever-Deeper`. Eksakt eksportkilde: `d21215650f165c81e14ad0d56d202679eab740d5`. Main holder publisering/bevis. Les `docs/premium-polish/hud-dev15-2/HANDOFF.md` først.

Test-run35830513108 besto1259 gameplay-,125 touch-,input-,layout-,DEV/save-flavor- og28 Skills/save-kontroller.22 faktiske Chromium/Metal-kontroller: HUD og menykobling ved844×390,667×375 og900×600/DPR3, Moss-HUD og mining etter lukking. Vanlig Mac WebKit besto ny og lagret oppstart. Uavhengig kritiker inspiserte8 Chromium-bilder og1 WebKit-spillbilde: avgrenset kode/visuell kvalitet9/10, ingen blokkere. Fysisk iPhone og stabil FPS er fortsatt ikke verifisert.

Publiseringscommit `f54bfc13b849d033d0299a71062e104ce7ac6db7`, run35831303971: package/deploy/verify besto; alle27 offentlige filhasher stemmer. Ni LIVE-filer og ni historiske Worn-filer er bevart. PCK259846500 byte, SHA256 `ad3af0026fb3048addcc37a244f152e930f0e506c5cac5cc0aeb1a5d6841355b`. DEV-lagring og alle21 native figur-/utstyrsfiler er uendret.

Kandidat10737007872, bygg10737385579, nettleser10736463498. Kvittering10737605959 (ZIP SHA25696e7fd6d5d849adc92f22669fca577e052033544e89116921feb6db6e6fcfcdc). Rollback tilDEV15.1:10736374573. Bevis og kvittering ligger på main under `.github/hud-dev15-2/`.

Godkjent PNG: `assets/ui/skills/icons/tools-premium-v1.png`,1254×1254 RGBA, originale piksler bevart. SHA256 `b0ddf462bcd25fca89bffa073f0dd9af2af5c82cf2a9f299224f3fe148f1d64f`. Ikonarkiv: libfile_4d4d8efad7ec8191a546bbc55ff95b7b. Ikke generer ikonet på nytt.

Oppgaven er ferdig. Ikke gjenta eksport/opplasting/testing av denne uendrede kandidaten. Neste brukertest: oppdater DEV, sjekk15.2 og trykk det nye ikonet. Ikke start automatisk ny figur-, animasjons- eller FPS-produksjon. Stående DEV-publiseringstillatelse gjelder; ingen ny innlogging. De fire kjente invariantavvikene er beholdt, ikke nye feil.

## Implementeringsnotater

Kun HUD-bilde/bildeskala, versjonstekster og den tilsvarende eksisterende forventningen for menyens breddegrense er endret i runtime/QA. Den strenge optiske <=3CSSpx-pariteten er beholdt. Førstecap120 og andre112 ble avvist av den kontrollen; direkte Godot get_used_rect måling ga102.507logiske px for det nye ikonet vedcap104 og101.938 for kompasset vedcap112. Ingen av de avviste pakkene ble publisert.

Gjenbruk `.github/workflows/hud-dev15-2.yml` og den etablerteMac-ruten ved nye relevante endringer. GitHub-artifakter lastes som filreferanser; lokal nedlasting krever vanlig Mozilla/5.0 User-Agent dersom standard urllib får4031010. Ingen binær/base64 gjennom samtaleverktøy. Originalt bilde ble overført én gang med allowlist og SHA256-kontroll; midlertidig overføringsworkflow er fjernet.
