# LIVE1.0.5 — published and verified, 5 October 2026

Published: https://corpax88.github.io/Ever-Deeper/ — refresh and choose Continue; no reset. All approved content through DEV15.56 is now LIVE. DEV retains separate saves. Existing LIVE1.0.4 progress was continued in the accepted Mac migration test.

Publication fe352c8d3ee8c7cbb26cb3963f6a8a3e8ae4bde0 / run37240619358 succeeded. Receipt artifact11317322246 verifies all26 public files; all9 DEV15.56 and9 Worn files are unchanged. Previous LIVE1.0.4 rollback artifact11317731276.

Exact runtime PCK327857414bytes/SHA256 e1fc53f0fc87b68cf5f956c50a28a38c906b54aff3082476bfc6a108e932dad2. Final shell/package source858659174db5a359e4c461526b819e200de1e398 on codex/live-1-0-5-20261005, candidate11317221752, QA37239741887. Promotes immutable DEV15.56 artifact11312268748/run37227129258/source deaa7088d75d473b0c16951bc05f19c4db7800c4. All1594 retained payloads verified; production version/flavor, DEV-tool removal and opt-in QA fixture corrections are explicit in the receipt. Never export historical main.

Mac input,414core,production flavor,341migration and25browser observations passed, as did ordinary WebKit startup/save/reload. All16 final images were inspected at667/844/932 widths. No physical-iPhone or overall9.5/10 claim. Linux software fallback had an XP-persistence fixture failure that reproduces on unchanged LIVE1.0.4; it is documented in linux-baseline-diagnosis.json and is not counted green.

## Shared engine contract

LIVE loads its own index.pck but uses the exact preserved dev/index.wasm, dev/index.js and two dev audio worklets. Root index.wasm is intentionally omitted, reducing the site to1,070,382,849bytes below the1GiB gate;26 unique public files replace27. Existing DEV/Worn bytes are unchanged. Future publishers must preserve this dependency, and an engine upgrade needs LIVE compatibility review. Prior LIVE rollback is self-contained and includes its own WASM. Do not reuse older27-file publisher assumptions.

## Website — complete

The corresponding website update is published at https://ever-deeper-game.corpax88.chatgpt.site. Source141993fc3db781cd884268d90c0d1377a4cb6a17, saved version9, deployment appgdep_6ac2d5b6116c8191a1bbac2d8aa36597 succeeded. 82 release records and238 local links checked; existing gallery/media/styles/scripts preserved. Browser visual QA was not run under the managed Sites limitation. Receipt: website-publication.json.

No pending publication or test jobs in this release task. Next: Mats refreshes LIVE, chooses Continue and tests phone feel. Do not reset or copy DEV saves. Do not repeat completed unchanged tests or publication. Older in-progress notes below are historical.

---

# LIVE1.0.5 promotion — in progress

Mats explicitly requested latest DEV on LIVE on 5 October 2026, Europe/Oslo. Promote the exact approved DEV15.56 production artifact 11312268748/run37227129258/source deaa7088d75d473b0c16951bc05f19c4db7800c4; do not export historical main.

Release branch codex/live-1-0-5-20261005. Only production flavor/version, removal of DEV tools, the existing LIVE loading-overlay fix and opt-in QA fixtures differ. Artwork/gameplay payloads are otherwise byte-preserved. Existing LIVE save identity must continue; DEV remains separate. Public DEV and Worn must be preserved.

First run37238994591 passed input, build flavor and migration but failed the same two historical completed-goal assertions already corrected in DEV15.56 QA. Attempt2 reuses those exact approved assertions; no gameplay modification. Local tests encountered a truncated temporary package and are not counted as passing evidence. Use Mac acceptance, inspect captures, then bind immutable artifacts and all reports before publishing.

Website publication is mandatory: docs/WEBSITE-RELEASE.md, existing Site appgprj_6abcf3a6e07481918afb1c03f29caec0. Current public Site version8 documents DEV15.56 and LIVE1.0.4. Do not mark LIVE1.0.5 released until game publication verifies all27 hashes. No physical-iPhone performance claim.

## Publication size recovery
First LIVE publication2675b4c/run37239594051 stopped before deploy: three full copies total1,109,897,572bytes, over the existing1GiB safety limit by36,155,748bytes. Never weaken the size guard or remove Worn. New shell reuses exact existing DEV index.wasm/JS/audio worklets using executable dev/index with mainPack index.pck. Only redundant root index.wasm is removed. All18 DEV/Worn bytes remain pinned. This reduces total by39,514,754bytes; the accepted LIVE PCK remains327857414bytes/SHA256 e1fc53f0fc87b68cf5f956c50a28a38c906b54aff3082476bfc6a108e932dad2. Recheck real old-LIVE save migration and ordinary startup under this dependency layout. Future publishers must preserve these shared engine dependencies; an engine upgrade needs separate compatibility review. Full prior LIVE rollback includes its own WASM.

Final shared-engine Mac source858659174db5a359e4c461526b819e200de1e398, run37239741887 passed input,414core,production flavor,341migration,25browser observations and ordinaryWebKit. All16 final captures inspected. Candidate11317221752, evidence11317805479. Linux fallback37239972428 failed skills persistence; unchanged LIVE1.0.4 baseline37240395553 reproduces the same zero-XP restored state with unchanged seed/gold. This is not counted green and is not introduced by the promotion; see linux-baseline-diagnosis.json. No pending tests. Final publication and website still pending.
