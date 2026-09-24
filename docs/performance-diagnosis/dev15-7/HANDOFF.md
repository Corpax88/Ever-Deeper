# DEV15.7 — private play-session reports (candidate)

Mats authorized a separate Sites receiver, with reports readable directly by Codex after gameplay. This adds an opt-in recorder to DEV, not an FPS fix. LIVE1.0.0 and Worn must remain byte-identical.

The 24 September iPhone video of DEV15.6 (Library libfile_4004c889c684819191f4cce854e1cbad) still falls from approximately60 to29–36FPS. Earlier Mac terrain CPU improvement does not establish physical-phone FPS recovery. Keep native hero, approved assets, lighting and gameplay unchanged.

## Device flow

DEV TOOLS → START REPORT; play normally for2–3minutes; DEV TOOLS → SEND REPORT. The receiver opens in a separate top-level page and saves automatically, showing a receipt. This is deliberately a post-session private upload, not an unattended live feed. Authentication is handled by the private Sites platform; no secret is embedded in the public game. A normal ChatGPT sign-in can be required if that browser has no existing session. Do not promise that this never requires sign-in.

Five-second windows include wall-clock FPS/p95/max, slow frame count, per-frame process/physics monitor means and process maximum, snapshot draw/node/video-memory counts, visible light/shadow/pet-light counts, current world/depth/tool, movement/mining/menu fractions, drops and actual canvas/DPR. Monitor CPU is an engine process monitor, not GPU timing or a full profiler. Counts except frame/process fractions are end-of-window snapshots. No temperature reading, exact GPU execution duration, save contents, name, email, microphone or screenshots are collected by the recorder.

Explicit start only. Maximum120windows or10minutes; a pending unsent report prevents replacement. The single pending draft is saved asynchronously in IndexedDB; closing can lose an unfinished window or an uncommitted last write. Stop on app interruption; background time is not included as a gameplay stall. SEND stops recording. Receiver retries are idempotent; receipt clears the local pending report. CLEAR requires two taps. Popup failure exposes a normal link. Reports are not sent while playing, so network/upload overhead does not contaminate the recorded workload. Receiver keeps30reports.

## Canonical ownership

Game source starts at5594cc94ab28a887fe15ef377c45d68ba28ef70f on codex/fps-dev15-6-20260923. New branch codex/telemetry-dev15-7-20260924; source modifications are recorder, DEV menu, browser-shell addition and DEV15.7 stamp. `.github/workflows/telemetry-dev15-7.yml` builds exact immutable PCK and verifies native resource hashes, exported input/touch/dev-tools/build-flavor, ordinary WebKit startup, and report transfer in actual Chromium/Apple WebKit gameplay. QA handoff uses an intercepted private receiver fixture; it does not pretend to prove a physical iPhone login.

Sites project **appgprj_6ab52d1e74988191a3a254543ffad797**, source checkout `/workspace/sites/ever-deeper-reports`, title Ever-Deeper · Spillrapporter. Private owner-only audience. Expected origin `https://ever-deeper-spillrapporter.corpax88.chatgpt.site` (only claim published once successful native deployment). Source is persisted in its own Sites git repository; do not duplicate it into Library or game runtime.

## Read the latest real report

1. Call `mcp__codex_apps__sites_read_database_overview` with that exact project ID.
2. Reuse its returned DB binding/table names, then call `mcp__codex_apps__sites_read_database_table_rows` on `latest_report`, limit1.
3. Read `latest_windows`, limit25, following only returned `model_projection.next_offset` until null. Each row is one small window, avoiding whole-report text truncation. Check every row's `report_id` matches the summary before analyzing; if a new report arrived mid-read, restart at the new summary.
4. Historical headers/payloads are in `reports`, bounded30. Large payload cells can be truncated by the connector; use latest per-window rows for reliable detailed analysis.
5. Never infer missing thermal/GPU timing or causality. Compare CPU spikes, draw/lights, canvas, mining and area transitions; physical phone controls may still be necessary.

## Validation limits

API source checks cover authentication, origin, strict shape, size/window limits, D1 insert, idempotency, owner conflict, weightedFPS and old retries. Private production authentication and physical iPhone transfer require the user's first real report. The optional WebMCP read-only summary tool is additive; authoritative direct access is the Sites database connector. Preview auth is not bypassed for testing. Exact package, CI, critic and publication receipts are appended after acceptance.
