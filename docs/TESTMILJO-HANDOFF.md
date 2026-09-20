# Ever-Deeper — fortsett fra korrigert Worn-test j

Mats ba uttrykkelig om ny chat etter feilen «Denne samtalen er for lang til å fortsette».
Dette er et trygt kontrollpunkt, ikke en publisering. Ved fortsettelse gjelder fortsatt:
**Få den avgrensede Worn-testen spilleklar og lever en verifisert lenke.**
Les denne korte oppdateringen først. Eldre detaljhistorikk finnes i versjon96 av denne filen og i Git-dokumentasjonen.

## Kilde og retting som er lagret
- Repo: `Corpax88/Ever-Deeper`; gren `codex/hero-loop-flow-20260918`.
- Korrigert runtime/harness: `e32a03e620913a76f3bee9083b2e9b1d66eef972`; tre `f1712d0e299b98030d4ad898c97b837d19235cc4`. Remote-grenen er kontrollert. Senere dokumentasjonscommits er ikke en ny spillkandidat.
- Gammel g-kandidat feilet i run i ved sjette treff/frame52: `Rejected disconnected armR segment 0 error 0.0001066327095`. Den skal ikke publiseres.
- `_solve_chain` manglet re-projisering/normalisering av radialvektoren etter quaternion-transport. Én linje Gram–Schmidt retter dette; grensen0.0001 er beholdt.
- Samme35 007 stillinger før/etter: største lengdeavvik0.0001285672 →0.0000001788; alle50 forfatterlagde matriser er uendret, avvik0. Testen avviser også ikke-finite verdier. Dette reproduserer feilklassen, ikke bevis for en bestemt antiparallell årsak.
- Godkjent v28, studie20, støttehåndslipp, modell og materialer beholdes. Ordinær `flow_graph_enabled=false`; FPS-arbeid er fortsatt pauset.

## Eksakt ny webkandidat j — ferdig eksportert, ikke ferdig godkjent
- Nytt arkiv: `Ever-Deeper-Worn-rettet-kontrollpunkt-20260920.zip`.
- Arkiv308443351 byte; SHA256 `1b467af733067bf27f25a5eb0d348739eabd606b8922a5015a6187936d9fea12`.
- `web-j/index.pck`:327093712 byte; SHA256 `74db0719dc5d151e0ad9491e9c5e90769c6f85ff8f8db07fe55c4b825277da05`.
- `candidate-j.xdelta`:33174356 byte; SHA256 `4d77f3bc9aa63a3aceffa1e8123872a261d172e27fdb07055bee920a333fea77`.
- DEV13 base-PCK SHA256 `5016e16791f51790f7a10dfabe0719b308de82a80627aca8d740b0e355e6cdc3`,221020724 byte. Xdelta-rundtur er utført og gir eksakt j-hash.
- Alle20 arkivmedlemmer er CRC-kontrollert; alle datamedlemmer er SHA-kontrollert etter lukking. Arkivet inneholder9 webfiler, delta, browser-j-evidens, logg, bundle, delopplastingskvittering og faktisk i-feilbilde. Ingen privat Blender-original.
- Syv øvrige runtimefiler er byte-identiske med DEV13. PCK og HTML er nye. Ingen ny eksport trengs for videre testing av j.

## Siste observerte kontroll — ufullstendig, ingen bestått sluttrapport
Chromium151.0.7922.34/Linux/ANGLE SwiftShader, Godot4.7.2, CSS844×390, ønsket DPR2.
CDP-bildene er faktisk844×390; ikke kall dem1688×780. Tilstand før/etter bildet er registrert, men er ikke nøyaktig samme frame.
- `01-ready` og `02-held-mining` er fullførte bildekontrollpunkter. Sistnevnte: frame65, åtte faktiske treff, HP500→468, ingen native feil.
- Siste JSON: frame90, ni treff, HP464, x1514.66796875/y1648, `mining=false`, `failed=false`, ingen feil. Tastaturgange er observert.
- Kjøringen var ved `keyboard-movement-release-stable`; ingen03-gange-capture, reset- eller touch-capture, og ingen `report.json`. Ikke kall hele suite eller slippkontroll bestått.
- Etter brukerens ny-chat-forespørsel finnes ingen aktiv administrert session53759. Ikke vent på den. Kontrollpunktet er markert ufullstendig.
- Uavhengig kritiker støtter den numeriske rettingen; endelig j-UI/pose/kontroller er IKKE visuelt godkjent ennå. Ingen9/10, fysisk iPhone-, normalhastighets- eller50FPS-påstand.

## Testmiljø og neste konkrete arbeid
1. Hent gjeldende Git-gren. Les `AGENTS.md`, toppen av `START-HER.md`, `docs/TESTMILJO-HANDOFF.md`, kodekart/kontrollguide og `docs/premium-polish/worn-trial-20260920/` med avgrensede lesninger. Ikke dump hele historikken eller store verktøyregistre i chatten.
2. Finn nytt arkiv med nøyaktig navn og verifiser manifestet. Gjenbruk `web-j/`. Lokal kopi var `/workspace/scratch/e9847b04c09b/deliverables/`; web og rapporter under `/tmp/ever-deeper-worn-trial-web-j` og `/tmp/ever-deeper-worn-review-j`.
3. `npm ci --ignore-scripts`. Chrome151: `/tmp/ever-deeper-runtime-20260920/chrome151/chrome-headless-shell-linux64/chrome-headless-shell`; offisiell kilde `https://storage.googleapis.com/chrome-for-testing-public/151.0.7922.34/linux64/chrome-headless-shell-linux64.zip`.
4. Kjør én motor: `node tools/hero_v28/runtime_pilot/review_trial.mjs /absolute/web-j /absolute/fresh-review /absolute/chrome-headless-shell`. Harness har tidsbasert polling uten periodiske skjermbilder, CDP-capture, faktisk PNG-størrelse, joystickstart(.22,.72), reell reset og stoppkontroller. Linux-rendering bruker flere sekunder per frame; ikke start mange motorer.
5. Et etablert Mac-alternativ er forberedt som **inaktivt utkast** `docs/premium-polish/worn-trial-20260920/verify-native-worn-trial.draft.yml`. Ingen Mac-jobb ble startet. `.github/native-flow-trial/assemble_candidate.py` er lagret i e32 og rekonstruerer kun QA-bytes; den publiserer ikke. Harness støtter standard Chromium på Mac uten å tvinge SwiftShader. Kjør først når eksakt payload er komplett.
6. Når alle seks reelle kontrollpunkter består, få en uavhengig kritiker på de faktiske bildene og rapporten. Bevar test-i-feilen som historikk. Ikke erstatt visuelt bevis med numerikk.

Verifisert Godot4.7.2 (`ed1daf0bf`): `/tmp/ever-deeper-runtime-20260920/godot/Godot_v4.7.2-stable_linux.x86_64`; matchende webtemplates finnes. Den gamle1.7MB-ZIP-en under `/workspace/scratch` er korrupt; ikke bruk den. Ny offisiell74.2MiB-ZIP ble hentet fra godotengine/godot-builds4.7.2-stable og validert.
Xdelta: `/tmp/ever-deeper-runtime-20260920/xdelta3/usr/bin/xdelta3`.
Ved nødvendig ny eksport: originale materialdata `/tmp/ever-deeper-native-runtime-matched-20260920`, motion `/tmp/ever-deeper-native-motion-tasks-20260920/tasks.json`; bevarte arkiver heter `Ever-Deeper-native-materialer-20260920.zip` og `Ever-Deeper-bevegelseskobling-20260920.zip`.

## Publisering og delvis opplasting
Ingen ny DEV/LIVE er publisert. DEV13 og LIVE0.46.9 står fortsatt urørt.
Mats har godkjent kodeopplasting og gated additiv DEV-test på `dev/worn/`; ingen ordinær spill-/LIVE-adopsjon.
Publisher og reviewkrav er `.github/native-flow-trial/publish.py` og `.github/workflows/publish-native-worn-trial.yml`: eksakte9 filer, seks kontroller, uavhengig visuell godkjenning, hashbundet review/bundle/baseline/kilde, bevaring av18 gamle filer, kontroll av27 etter deploy.
`candidate-j-bundle.json` og `upload-j-receipt.json` i dokumentasjonsmappen/arkivet bevarer j-metadata. Bundle SHA256 `26209f2eeeefa1688d8fd954b701dd02e4a00dbba74274271b4f3aa5d55765dd`.
43 delta-deler à786432 byte (siste kortere). Bare j-del000–002 har bekreftet opplastingskvittering; de er urefererte Git-blobs. Andre avbrutte kall kan ha laget flere, men er ikke bekreftet. Ingen komplett payloadcommit eller `review.json` finnes. Rekonstruer fra eksakt delta og hashkontroller; ikke bruk den gamle g-delopplastingen.
Direkte Git clone/fetch fungerer. Direkte push feiler uten credentials; de autoriserte GitHub-verktøyene create_blob/tree/commit/update_ref fungerer. Ikke hent eller finn på tokens. Store binærkall gjorde denne chatten tung; unngå å skrive binærdata/verktøyregistre/historikk tilbake til modellen og lagre kvittering etter hvert fullførte kall.
Svar på norsk, maks5korte linjer. Fortsett fra j og lever kontrollert spillenke når portene består.
