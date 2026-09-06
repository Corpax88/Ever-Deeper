# Ever-Deeper v0.45.0 production release

Mats approved promoting the full overhaul to LIVE on 2026-09-06 and explicitly required no DEV menu on LIVE.

Production is exported from the complete v0.45.0-dev.1 source using `Web Production`. Apply `source-release.patch` to the previously preserved `Ever-Deeper-v0.45.0-dev.1-source.zip` (SHA256 `03467ccfa9fcbd8ddc31f7495b31f33dc2f653aaee1db5e8cbdab4f7c286c17f`) to reproduce the source changes. The production application version is 0.45.0; DEV remains 0.45.0-dev.1.

Compared with the reviewed DEV PCK, production removes the developer menu source/remap and changes only the project configuration, build-contract version assertion, UID cache and class cache. All production art, gameplay and other scripts are byte-identical. The existing 303-state visual review remains the art/gameplay reference; this release additionally verifies the exact production export, including its menu and HUD. Native production flavor QA verifies menu=false, resource=false, production user directory and `user://ever_deeper_run_v2.json`. The actual Web gameplay suite passes 776 checks.

`candidate.json` identifies the exact production runtime. `dev-baseline.json` identifies the DEV runtime that must stay unchanged. `old-baseline.json` records the previous LIVE v0.43.1. `prepare_release.py` verifies every file before packaging, backs up both previous public runtimes, publishes only the reviewed production artifact at root, and verifies all 18 public files afterward. No DEV save is copied into LIVE.

The only source changes are the production version and its QA expectation. No additional features were introduced during promotion. Browser QA uses Chromium/SwiftShader at 932×430; this is not a physical-iPhone performance measurement.

Prior full overhaul QA: run 34060346316, 303 inspected captures and 776 gameplay checks. Production QA: run 34062664521. See production-review.json for final inspection evidence. Rollback runtime is uploaded before deployment as ever-deeper-before-v0450-live-rollback (30-day artifact retention); the previous source archive remains the longer-term recovery source.
