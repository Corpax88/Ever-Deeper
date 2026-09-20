# Ever-Deeper — fortsett Worn-test j etter nytt chatavbrudd

Mats ba om «Ny chat» etter «Resonnering mislyktes» og «Denne samtalen er for lang».
Oppgaven er fortsatt å fullføre den avgrensede Worn-testen og publisere en kontrollert
spillbar lenke på `dev/worn/` når kontrollene og uavhengig visuell vurdering består.
**Ingen ny spillversjon er publisert. Ingen testprosess kjører nå.**

## Nåværende kilde og uendrede rammer
- Repo `Corpax88/Ever-Deeper`, gren `codex/hero-loop-flow-20260918`.
- Kontrollert gren før denne dokumentasjonslagringen: `bcc4530fce145402d445aa339e3617b97a6da2f6`.
- Spillkandidatens runtime/harness: `e32a03e620913a76f3bee9083b2e9b1d66eef972`, tre `f1712d0e299b98030d4ad898c97b837d19235cc4`.
- Denne chatten endret ikke runtime, spilldesign, grafikk eller testkrav. Den gjenopptok eksport j, kjørte reelle nettleserkontroller og fortsatte delopplasting.
- Godkjent v28/studie20, støttehåndslipp, modell/materialer beholdes. Ordinær `flow_graph_enabled=false`; FPS-arbeid er pauset. Ingen ordinær spill-/LIVE-adopsjon.
- Kodeopplasting, autorisert Mac QA og gated additiv DEV-test er allerede godkjent. Ikke spør Mats om samme godkjenning igjen.

## Nytt kontrollpunkt fra denne chatten
- Tilleggsarkiv: `Ever-Deeper-Worn-fortsett-20260920-2257.zip`. Inneholder tre faktiske PNG-er, konsoll, telemetri, ufullstendig teststatus og oppdatert delopplastingskvittering. Det erstatter ikke den komplette webpakken nedenfor.
- Lokal kjøring: `/workspace/scratch/22f5820db3c6/review-j-complete/`; stdout i `review-j-run.log`.
- Fullført og lagret: `01-ready`, `02-held-mining`, `03-walk-exit`.
- Held mining ga åtte reelle treff: HP500→468. Ingen registrert native posefeil.
- Etter tastaturslipp: frame75 og85 hadde identisk posisjon `[1514.66796875,1648]`, impact_serial8, mining=false. Gange/slipp-kontrollen fullførte, og03-bildet ble tatt ved den etterfølgende kontrollsekvensen.
- Siste telemetri: frame95, HP468, åtte treff, samme posisjon, mining=false, failed=false. Et reset-klikk var sendt; siste observerte resets=0. Kjøringen ble avbrutt før resultatet var fastslått. Ikke kall reset bestått eller bekreftet defekt.
- Ingen04-reset,05-touch-mining,06-touch-walk eller `report.json`. Hele suiten og visuell godkjenning er ufullstendige.
- Den gamle session47214 er borte; ingen tilhørende Node/Chrome-prosess ble funnet. Ikke vent på den.
- Chromium151.0.7922.34/Linux/ANGLE SwiftShader, Godot4.7.2, CSS844×390, ønsket DPR2. PNG-ene er faktisk844×390; tilstanden før/etter et bilde er ikke rammesynkronisert. Ingen fysisk iPhone-, normalhastighets- eller50FPS-påstand.

## Eksakt j-pakke — gjenbruk, ikke eksporter på nytt
- Komplett arkiv: `Ever-Deeper-Worn-rettet-kontrollpunkt-20260920.zip`, Library-ID `libfile_42bd3dc811a081918239dc51b1bea846`.
- Arkiv308443351 byte, SHA256 `1b467af733067bf27f25a5eb0d348739eabd606b8922a5015a6187936d9fea12`.
- `web-j/index.pck`:327093712 byte, SHA256 `74db0719dc5d151e0ad9491e9c5e90769c6f85ff8f8db07fe55c4b825277da05`.
- `candidate-j.xdelta`:33174356 byte, SHA256 `4d77f3bc9aa63a3aceffa1e8123872a261d172e27fdb07055bee920a333fea77`.
- `bundle.json` SHA256 `26209f2eeeefa1688d8fd954b701dd02e4a00dbba74274271b4f3aa5d55765dd`.
- DEV13 base-PCK:221020724 byte, SHA256 `5016e16791f51790f7a10dfabe0719b308de82a80627aca8d740b0e355e6cdc3`.
- Arkivhash og alle19 datamedlemmer ble kontrollert på nytt og stemmer. Syv runtimefiler er identiske med DEV13; bare HTML/PCK er nye.
- Denne chatten materialiserte pakken til `/workspace/scratch/22f5820db3c6/candidate-j/`; kan forsvinne senere.

## Delopplasting — 24 av43 bekreftet
- `docs/premium-polish/worn-trial-20260920/upload-j-receipt.json` er oppdatert.
- j-del000–023 er bekreftede Git-blobs med kontrollerte SHA-er. Del024–042 mangler bekreftelse. Et avbrutt kall kan ha opprettet neste blob; ikke regn den som bekreftet uten kontroll.
- Ingen komplett payloadcommit og ingen `review.json` finnes. Ingen publisering eller Mac-jobb er startet.
- Direkte clone/fetch fungerer. Tidligere direkte push manglet credentials; de autoriserte GitHub-appverktøyene fungerer. Ikke let etter eller finn på tokens.
- Store base64-strenger ble sendt gjennom verktøyresultater under opplastingen. Selv skjult utskrift kan gjøre samtalen svært tung. **Ikke fortsett denne store binærruten ukritisk i neste chat.** Avklar en støttet overføring fra fil/backend uten store binærstrenger i samtalen før resten av opplastingen. Behold eksakte bytes og autorisasjonsgrenser.

## Neste konkrete arbeid
1. Hent gjeldende gren og les `AGENTS.md`, denne filen og avgrenset `docs/premium-polish/worn-trial-20260920/`. Eldre handoff97/test-i ligger bevart som historikk.
2. Gjenbruk eksport j og kvitteringen. Ved behov hent tilleggsarkivet med nøyaktig navn. Ikke gjenta eksport eller solverarbeid.
3. Foretrekk den etablerte Mac QA-ruten for raskere faktisk rendering når eksakt payload er komplett. Klart utkast: `docs/premium-polish/worn-trial-20260920/verify-native-worn-trial.draft.yml`. Den er fortsatt inaktiv. `.github/native-flow-trial/assemble_candidate.py` bygger kun QA-bytes, ikke publisering.
4. Lokal fallback: `npm ci --ignore-scripts`, deretter `node tools/hero_v28/runtime_pilot/review_trial.mjs /absolute/web-j /absolute/fresh-review /absolute/chrome-headless-shell`. Kjør én motor. Chrome151: `/tmp/ever-deeper-runtime-20260920/chrome151/chrome-headless-shell-linux64/chrome-headless-shell`. Offisiell ZIP: `https://storage.googleapis.com/chrome-for-testing-public/151.0.7922.34/linux64/chrome-headless-shell-linux64.zip`. Software-rendering er svært langsom.
5. Fullfør alle seks reelle kontrollpunkter, få uavhengig kritiker på faktiske bilder/rapport, og bind godkjenningen til eksakte filhash-er. Numerikk alene godkjenner ikke utseende.
6. Bruk eksisterende `.github/native-flow-trial/publish.py` og `.github/workflows/publish-native-worn-trial.yml`. De krever hashbundet review/bundle/baseline/kilde, bevaring av18 DEV13/LIVE-filer og kontroll av27 filer etter deploy. Lever først spillenken når dette består.

Den tidligere solverrettingen og feilbildet fra run i er allerede bevart. Grensen0.0001 ble ikke svekket;35007 numeriske stillinger besto med maksavvik0.0000001788 og null endring i50 forfatterlagde matriser. Dette er bakgrunn, ikke en fullført visuell test.
Svar på norsk, maks5korte linjer. Korte nødvendige oppdateringer; ingen store registre, historikkdump eller binærdata tilbake til modellen.
