# DEV9 — spillbar kvotecheckpoint, 16. september 2026

**Publisert og kontrollert:** https://corpax88.github.io/Ever-Deeper/dev/?build=e76a2b9
Spillet viser **1.0.0-dev.9**. Alle ni DEV-filer stemmer med den testede pakken;
alle ni LIVE-filer er uendret. Publiseringsjobb35101544556 har tre vellykkede jobber.

Mats ba om å stoppe nye eksperimenter ved6% kvote, gjøre gjeldende arbeid
spillklart og laste opp. Denne bestillingen er fullført. Videre undersøkelser
er satt på pause til Mats vil fortsette. Ingen prosesser eller agenter arbeider videre.

## Det som er med

Alt tidligere integrert arbeid fra c8906f1, pluss rettelsen av avbrutt slag:
slipp rett før treff trekker slaget tilbake; et gjennomført treff avsluttes
fremover. Rask overgang til gange, fartstilpasset gange og godkjent v28-grafikk
er beholdt. Ingen ny endring av lagringsskjema3.

## Kilde og kontroll

- Repo:Corpax88/Ever-Deeper; arbeidsgren:codex/premium-polish-recovery-20260915.
- Eksakt spillkode:e76a2b90a8a6da4d2673689ce2eeb646e5c2303b.
- Spillkodetre:6c67ffd5f022ff0ed693d72fcfb7a33fb3ff2b4c.
- Hent nyeste arbeidsgren for disse senere dokumentene; main er publiseringsgren.
- PCK:1270ea3974b0d551f0a10f8a72ec4ba56824030822526a8b1544bb295988e32f,221007780byte.
- QA35099632983:alle12jobber besto; uendret pakke ble kontrollert.
- Native spilltest35099632802:alle3jobber besto funksjonelt; dette er ingen50FPS-godkjenning.
- Animasjonsammenligning:732bilder,812observasjoner. Endelig uendret DEV9-pakke:
  46bilder ved1696×780,4situasjoner før/etter treff,50observasjoner uten feil.
- Publiseringscommit4635e2a91ad55469c69e7fe5db2f220e0546c835,jobb35101544556.
- Kandidat10448000795;fullført QA10448008790;rollback10448003043;kvittering10449085275.
- publication-receipt.json dokumenterer alle18 offentlige filidentiteter.
- Ikke gjenbruk tidligere publisher mot gammel baseline: neste opplasting må
  bruke denne DEV9-kvitteringen og en ny eksakt pakke/QA-identitet.

## Fortsett med dette når kvoten er tilbake

1. Testinntrykk fra Mats og stabil FPS. Tidligere c890-målinger på virtuell Mac:
   Hub44.98–56.60,Ember20.79–39.54,Deep18.01–30.91FPS; fysisk iPhone uverifisert.
2. Neste avgrensede ytelsesforsøk: per-lys skyggekastermasker som beholder alle
   opprinnelige rektangler og PCF-innstillinger. Bare en plan er lagret.
3. Bedrock-skjøter og Voidstar-klumper trenger fortsatt korreksjon med godkjent
   grafikk. Det opprinnelige hjørnet passer ikke eksisterende kantankre uten
   å endre fotavtrykket; ingen ugyldig hjørnevariant er tatt inn.
4. Animasjon på flere utstyrstyper/retninger, nettleser/hazard/gjeninntreden,
   lyd og fysisk spillfølelse. Ingen endelig9/10 eller1.0-godkjenning.

## Ikke gjenta eller ta inn forkastede forsøk

- Skyggekonturer:512topologier og167936stråler geometrisk riktige, men den
  opprinnelige kameratilstanden avviker369RGB-piksler med maks4. A2 er eksakt.
  Åtte andre tilstander passerer; de opphever ikke feilen. Ingen ytelsesmåling.
- Transparent hjørnebeskjæring:153RGB-piksler avviker1 ved fraksjonell filtrering.
- Tidligere receiver-masker og native-mass-sammenslåing ga ikke godkjent gevinst.
- Ingen av disse eller den uaksepterte native-veggstudien er i DEV9.

Bevar råfeilene. Ikke løs dette ved å svekke bildesammenligning eller skjule
materialoverganger. Studiegrenene er lagret i paused-study-checkpoints.json:
shadow-contours01a447d3;corner-crop21c3bdd5;native-walls27416c0c.

## Miljø og underlag

Les AGENTS.md,docs/code-map.md og game-test-environment før nytt arbeid.
Godot4.7.2:'/tmp/ever-deeper-runtime-20260915/Godot_v4.7.2-stable_linux.x86_64'.
Xvfb:'/workspace/scratch/4e99473f21fc/runtime/xvfb/usr/bin/Xvfb'.
Bruk tools/run_rendered_isolated.py; bare én tung lokal renderer om gangen.
MovieMaker skalerer til1280×720; bruk faktisk frame_post_draw-lesing.
Ikke bruk copy2 ved gjenoppretting; skriv bytes med ny mtime.

Alle råbilder, mislykkede forsøk, logger og fixture-kilder fra denne økten er
lagret i fem Ever-Deeper-DEV9-evidence-partN.tar.gz. Identiteter og hasher står
i evidence-archive-receipts.json. Endelig eksportkontroll og publiseringsbevis
ligger også i Ever-Deeper-DEV9-published-evidence.tar.gz.
