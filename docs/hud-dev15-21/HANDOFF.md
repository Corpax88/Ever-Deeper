# DEV15.21 — Skills caption and DEV spacing

29September2026. Mats approved DEV15.20 but could not see the SKILLS text from the concept. It was omitted, not merely covered. Restored it as an actual serif UI label below the unchanged approved PNG. DEV toggle follows caption bottom plus12logical pixels. Caption is a child of the menu button, inherits visibility, ignores pointer input and preserves120touch target/104icon cap.

Exact tested source7ebf550ae28cbe3536e15a5a4105419e96e2cea2, branch codex/hud-dev15-21-20260929, repo Corpax88/Ever-Deeper. Main is publication carrier, not game rebuild source.

Validation36506876846 passed: input release, premium-core200checks,27Chromium observations/checks across844x390,667x375,900x600. Caption visible/inbounds, no overlap with icon/DEV; DEV opens/closes, Skills/mole open/close, real mining follows. Mac Apple Metal reportedDPR2; normal WebKit26.5/Apple GPU startup,pause,save/reload,confirmednewgame passed. All14actualPNGs inspected. No physical-iPhone claim. Existing900x600Skills-navigation crowding remains outside this change.

First build36506697083 was correctly blocked before testing: exact published developer-menu tooltip differed from source by the phrase on-the-surface. Recovered the actual source from pinned15.20PCK and preserved that tooltip; did not weaken the guard. Final build changes only HUD,developer layout,QA observer,version/remaps; all other PCK entries are byte-identical. Existing source invariant debt is not re-certified.

Immutable candidate11007955681,ZIPsha2566cfb1827e2b23af1e9cd8e48c37b9b604c75c7647636aaf54871f536ea4a54c6. PCK266366228bytes,SHA2562a4a26f11f0bdb8ac2fc213e4604de696bda2556629b8048bd19f666cff86a67. Browser11006699601,core11007556846.

Publisher335d9cc478e0c79d90b8a7e81677e67f8acbdcbd; acceptance in .github/hud-dev15-21 binds exact source,run,artifact,digest,files and reviewed evidence. Publication36507356916 passed package/deploy/verify;all27public hashes verified,9LIVE+9Worn preserved. Receipt11007742540;rollback11007353199.

FPS stays parked;15.19balance/stamina,approvedicon/world/hero andsaves unchanged. Next:user can refreshDEV15.21. No jobs remain. Do not repeat completed unchanged tests.
