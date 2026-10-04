# LIVE1.0.5 promotion — in progress

Mats explicitly requested latest DEV on LIVE on 5 October 2026, Europe/Oslo. Promote the exact approved DEV15.56 production artifact 11312268748/run37227129258/source deaa7088d75d473b0c16951bc05f19c4db7800c4; do not export historical main.

Release branch codex/live-1-0-5-20261005. Only production flavor/version, removal of DEV tools, the existing LIVE loading-overlay fix and opt-in QA fixtures differ. Artwork/gameplay payloads are otherwise byte-preserved. Existing LIVE save identity must continue; DEV remains separate. Public DEV and Worn must be preserved.

First run37238994591 passed input, build flavor and migration but failed the same two historical completed-goal assertions already corrected in DEV15.56 QA. Attempt2 reuses those exact approved assertions; no gameplay modification. Local tests encountered a truncated temporary package and are not counted as passing evidence. Use Mac acceptance, inspect captures, then bind immutable artifacts and all reports before publishing.

Website publication is mandatory: docs/WEBSITE-RELEASE.md, existing Site appgprj_6abcf3a6e07481918afb1c03f29caec0. Current public Site version8 documents DEV15.56 and LIVE1.0.4. Do not mark LIVE1.0.5 released until game publication verifies all27 hashes. No physical-iPhone performance claim.
