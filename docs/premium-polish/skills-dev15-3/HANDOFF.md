# Ever-Deeper — DEV15.3 Skills-barer er publisert

23. september 2026. **Skills-endringen er publisert på https://corpax88.github.io/Ever-Deeper/dev/.** Nivånummer beholdes; gullbar viser nivå mot100. En tynn rød bar under viser XP mot neste nivå, og erstatter XP-tallene på de fire ferdighetsradene. Dette følger brukerens Valheim-avtale fra den andre chatten. Stamina beholder ett oransje ressursfelt og verdi/100. Skills-ikoner, rammer og radplassering er beholdt.

Kanonisk kilde: `Corpax88/Ever-Deeper`, gren `codex/skills-xp-bars-20260923`. Eksakt eksportcommit `30a2aff088d2e2219382c765a74bf37804f9ad73`. Main holder publiseringsbevis. Les denne handoffen før eldre statusnotater.

Test-run35846632446 besto fem eksporterte kjernekontroller (input,overhaul,touch,layout,build-flavor),28Skills/save-kontroller og35 faktiske Chromium/Metal-kontroller. Skjermbilder ved844×390,667×375 og900×600/DPR3; tomme felt,99%XP, nivå99/100, opptjening over nivågrense, touch-tooltip og mining etter lukking. Vanlig Mac WebKit ny og lagret oppstart besto. Hovedagent og uavhengig kritiker inspiserte sluttbildene; avgrenset kode/visuell kvalitet9/10 uten blokkere. Ingen fysisk-iPhone- eller stabil-FPS-påstand.

Publiseringscommit `bde39a98ca2530577ea1400cc2deca157de384e6`, run35847446465: package/deploy/verify besto; alle27 offentlige filhasher er verifisert. LIVE9filer og historisk Worn9filer er uendret. DEV-saveidentitet `user://ever_deeper_dev_run_v3.sav` og alle21 native figur-/utstyrsfiler er bevart. Ingen spillbalanse eller XP-opptjening er endret.

PCK259847396 byte, SHA256 `b1e92f2dc7c0c28b385430fc70e3f0ba18f899bdd6ba51267acc1591bacacf97`. Kandidat10744125645, build10744120723, browser10744012119. Kvittering10744235370, ZIP SHA256 `ad4cb494744ae409286d5585b1210fafffe36e4ce539b679b3c4aa599f1e055a`. Rollback tilDEV15.2:10744300228. Filer, bevis, kritiker og kvittering er lagret på main under `.github/skills-dev15-3/` og `docs/premium-polish/skills-dev15-3/`.

Runtime eies av `scripts/ui/miner_skills_panel.gd`: gullfelt bruker nivå, rødt felt bruker eksisterende XP-ratio; oppdatering hver0,2s, flyttallsfremdrift medstep0. Begge felt er fulle ved nivå100. Førstekandidat1d45d67/run35845876089 ble avvist visuelt fordi eksisterende tekstbredde klippet100til10. Nivåfeltet er nå69logiske px bredt med samme høyrekant, og browser-testen verifiserer tekstbredden. Kun den korrigerte kandidaten er publisert.

Gjenbruk `.github/workflows/skills-dev15-3.yml` og `.github/skills-dev15-3/` for relevant nytt arbeid. De fire kjente invariantavvikene (project.godot,hero_gear,player_controller,player_visual) er historiske og rapporteres fortsatt som avvik. Ikke endre dem for å gjøre en rapport grønn.

Oppgaven er ferdig. Ikke gjenta eksport/opplasting/testing av denne uendrede kandidaten. Neste brukertest: oppdater DEV, sjekk15.3 og åpne Skills. Stående DEV-publiseringstillatelse gjelder; ingen ny innlogging. Det godkjente HUD-verktøyikonet fraDEV15.2 er beholdt; ikke generer det på nytt. Ingen automatisk ny figur-, animasjons- eller FPS-produksjon.
