# Ever-Deeper — Work-kontrollpunkt for Worn j

Oppgaven er å fullføre og publisere den avgrensede testen på `dev/worn/` etter seks faktiske kontroller og uavhengig visuell godkjenning. Ingen ordinær spill-/LIVE-adopsjon. Godkjent v28/studie20 og støttehåndslipp beholdes; FPS-arbeidet er pauset.

## Nåværende kilde og fremdrift
- Repo `Corpax88/Ever-Deeper`, gren `codex/hero-loop-flow-20260918`.
- Komplett kandidat og aktiv Mac-QA er lagret i commit `d6c856869dd19dfe9623d51946f007a0688f98df`.
- Runtime-kilde: `e32a03e620913a76f3bee9083b2e9b1d66eef972`.
- Alle 43 delblobs er nå lastet opp, SHA-kontrollert og commit-et. Den komplette deltaen ble kontrollert igjen etter git-fetch.
- Eksakt kandidat ligger nå i `.github/native-flow-trial/`; gammel delopplastingsblokkering er løst. Ikke last opp eller eksporter pakken på nytt.
- Mac-kjøring [35543977206](https://github.com/Corpax88/Ever-Deeper/actions/runs/35543977206) har gjenopprettet pakken og startet faktisk nettlesertest. Sjekk endelig status og artefakt før konklusjoner.
- Uavhengig kildegransking fant ingen konkret test-/publisherblokkering. Bildegransking venter på den ferske rapporten og PNG-ene. Ingen ny publisering ennå.

## Neste steg
1. Hent gjeldende gren. Les `AGENTS.md`, denne filen og `.github/native-flow-trial/`.
2. Hent `native-worn-mac-browser` fra kjøring35543977206. Kontroller alle seks punkter, eksakte ni filhasher, konsoll og faktisk bildestørrelse. Ved feil, rett den konkrete årsaken og bevar feilbeviset.
3. La uavhengig kritiker vurdere de faktiske bildene. Bind godkjenningen til eksakt bundle, kilde og rapport. Mac-nettleser er ikke fysisk iPhone eller FPS-bevis.
4. Bruk eksisterende publisher og workflow etter bestått kontroll. Legg kun additiv trial-publisering på main; ikke adopter hele arbeidsgrenen. Bevar og verifiser18 DEV13/LIVE-filer og9 trial-filer.

## Identiteter og gjenoppretting
- `index.pck`:327093712 byte, SHA256 `74db0719dc5d151e0ad9491e9c5e90769c6f85ff8f8db07fe55c4b825277da05`.
- `bundle.json`:SHA256 `26209f2eeeefa1688d8fd954b701dd02e4a00dbba74274271b4f3aa5d55765dd`.
- `candidate-j.xdelta`:33174356 byte, SHA256 `4d77f3bc9aa63a3aceffa1e8123872a261d172e27fdb07055bee920a333fea77`.
- QA-assembler: `python3 .github/native-flow-trial/assemble_candidate.py /absolute/fresh-output`; xdelta3 kreves. Den aktive Mac-workflowen installerer nettleser og kjører eksisterende `review_trial.mjs`.
- Nåværende lokal kopi: `/workspace/scratch/e8e722b143d2/Ever-Deeper`; komplett eksport: `/workspace/scratch/e8e722b143d2/candidate-j/web-j`. Scratch er ikke autoritativt.
- Direkte clone/fetch fungerer; direkte push har ikke credentials. GitHub-appens blob/tree/commit/ref-rute fungerer og er allerede autorisert.
- Den store overføringen ble fullført inne i code-mode: les maks393216 råbyte per halvdel via exec_command (`max_output_tokens:160000`, vent til exit_code0), kontroller eksakt base64-lengde, sett sammen to halvdeler og send til create_blob uten text()/notify() av data. Kontroller SHA mot kvitteringen. Bare korte kvitteringer returneres til modellen. Alle43 deler er nå ferdige; ikke gjenta denne overføringen.
- Eldre feil-/avbruddsbevis og solvergrensen0.0001 beholdes i git-historikken og `docs/premium-polish/worn-trial-20260920/`.

Kodeopplasting, autorisert Mac-QA og gated additiv DEV-test er allerede godkjent. Ikke spør Mats om det samme igjen. Norsk, maks5korte linjer; detaljer i prosjektfiler.
