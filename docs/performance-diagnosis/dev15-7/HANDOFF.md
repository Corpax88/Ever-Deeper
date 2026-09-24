# DEV15.7 — private play-session reports

Mats authorized a separate Sites receiver, with reports readable directly by Codex after gameplay. This adds an opt-in recorder to DEV, not an FPS fix. LIVE1.0.0 and Worn must remain byte-identical.

The 24 September iPhone video of DEV15.6 (Library libfile_4004c889c684819191f4cce854e1cbad) still falls from approximately 60 to 29–36 FPS. Earlier Mac terrain CPU improvement does not establish physical-phone FPS recovery. Keep native hero, approved assets, lighting and gameplay unchanged.

## Device flow

DEV TOOLS → START REPORT; play normally for 2–3 minutes; DEV TOOLS → SEND REPORT. The receiver opens in a separate top-level page and saves automatically, showing a receipt. This is deliberately a post-session private upload, not an unattended live feed. Authentication is handled by the private Sites platform; no secret is embedded in the public game. A normal ChatGPT sign-in can be required if that browser has no existing session. Do not promise that this never requires sign-in.

Five-second windows include wall-clock FPS/p95/max, slow frame count, per-frame process/physics monitor means and process maximum, snapshot draw/node/video-memory counts, visible light/shadow/pet-light counts, current world/depth/tool, movement/mining/menu fractions, drops and actual canvas/DPR. Monitor CPU is an engine process monitor, not GPU timing or a full profiler. Counts except frame/process fractions are end-of-window snapshots. No temperature reading, exact GPU execution duration, save contents, name, email, microphone or screenshots are collected by the recorder.

Explicit start only. Maximum 120 windows or 10 minutes; a pending unsent report prevents replacement. The single pending draft is saved asynchronously in IndexedDB; closing can lose an unfinished window or an uncommitted last write. Stop on app interruption; background time is not included as a gameplay stall. SEND stops recording. Receiver retries are idempotent; receipt clears the local pending report. CLEAR requires two taps. Popup failure exposes a normal link. Reports are not sent while playing, so network/upload overhead does not contaminate the recorded workload. Receiver keeps 30 reports.

## Canonical ownership

Game source starts at 5594cc94ab28a887fe15ef377c45d68ba28ef70f on codex/fps-dev15-6-20260923. New branch codex/telemetry-dev15-7-20260924; source modifications are recorder, DEV menu, browser-shell addition and DEV15.7 stamp. `.github/workflows/telemetry-dev15-7.yml` builds exact immutable PCK and verifies native resource hashes, exported input/touch/dev-tools/build-flavor, ordinary WebKit startup, and report transfer in actual Chromium/Apple WebKit gameplay. QA handoff uses an intercepted private receiver fixture; it does not pretend to prove a physical iPhone login.

Sites project **appgprj_6ab52d1e74988191a3a254543ffad797**, source checkout `/workspace/sites/ever-deeper-reports`, title Ever-Deeper · Spillrapporter. Private owner-only audience. Published origin `https://ever-deeper-spillrapporter.corpax88.chatgpt.site`. Receiver source `f53bd5f88486bd5bc7f6295a10139bdf7ddf4946`, successful private deployment `appgdep_6ab5367bd9288191af9e5e8d5897d62a`. Source is persisted in its own Sites git repository; do not duplicate it into Library or game runtime.

## Read the latest real report

1. Call `mcp__codex_apps__sites_read_database_overview` with that exact project ID.
2. Reuse its returned DB binding/table names, then call `mcp__codex_apps__sites_read_database_table_rows` on `latest_report`, limit 1.
3. Read `latest_windows`, limit 25, following only returned `model_projection.next_offset` until null. Each row is one small window, avoiding whole-report text truncation. Check every row's `report_id` matches the summary before analyzing; if a new report arrived mid-read, restart at the new summary.
4. Historical headers/payloads are in `reports`, bounded to 30 reports. Large payload cells can be truncated by the connector; use latest per-window rows for reliable detailed analysis.
5. Never infer missing thermal/GPU timing or causality. Compare CPU spikes, draw/lights, canvas, mining and area transitions; physical phone controls may still be necessary.

## Validation limits

API source checks cover authentication, origin, strict shape, size/window limits, D1 insert, idempotency, owner conflict, weighted FPS and old retries. Private production authentication and physical iPhone transfer require the user's first real report. The optional WebMCP read-only summary tool is additive; authoritative direct access is the Sites database connector. Preview auth is not bypassed for testing. Exact package, CI, critic and publication receipts are appended after acceptance.

## Accepted evidence and remaining device check

Game export source `abc42ca5db531270510802bf7dab4f3f0936d06d`, version `1.0.0-dev.15.7`. Main QA run `36012592198` passed exported input/touch/dev-tools/build-flavor, 17 Chromium report assertions, the same report route in Apple WebKit, and ordinary WebKit startup/new/saved game. PCK: 259866160 bytes, SHA256 `f2e071574c0960a3951de358024f7d4c490253ec3629156f6bcd8ba57cf68a6d`. All 21 native resources and the DEV save path are preserved.

Supplemental recovery run `36014339986`, test source `a23592cfd69249bc29d6bffee193d374934d4cb9`, reuses the exact candidate artifact. All 12 Chromium/WebKit recovery assertions pass: blocked popup fallback, acknowledged delivery, return receipt without opener, simulated sign-in navigation that strips the fragment, denied IndexedDB and memory-only recording. This is a transport contract, not a real ChatGPT sign-in or physical-phone test. A first recovery harness used a server redirect that Playwright could not intercept beyond its first request; correcting the fixture to a separately routed navigation passed without changing the candidate.

Receiver tests use the actual route and schema, a test-only authentication stub, and in-memory SQLite. All 14 checks pass, including a maximum-length 120-window report and exact deep-equal storage/readback of the actual Chromium and WebKit exported payloads. Production database readability was verified through the Sites connector; it was empty at publication preparation. Do not describe these fixture reports as a real user session. The first physical iPhone upload remains the next necessary validation.

Artifacts: candidate `10813466140` (SHA256 `e9cd2f6a9ac0fb9bea297eae3282a96aea5786961099a7438f2546c13aaaf0ee`), build `10812764607` (`91d931d1d9ae57970f282608423aa6d53a579d6451843f130cbe80fb7a4c6fb4`), browser `10812714996` (`4c978f2f47441a917eeccbaf0adde22a6e3aeff0230ba76eb0decdce141c50ff`), recovery `10814007034` (`de30e7b51402d2952ed7c59af5e19fc551c244ed50993606159d8bc43828c5a8`). Main holds pinned evidence and publisher under `.github/telemetry-dev15-7/`.

Independent final round 3 accepted the exact export: code 8/10, scoped visuals 8/10, no material blocker. Four actual game captures and two transport fallback captures were inspected. LIVE promotion is not authorized for this diagnostics task. This is not a new FPS optimization. Once DEV publication is verified, stop optional testing and wait for Mats to send a real report.

## Published 24 September 2026

DEV15.7 is published at https://corpax88.github.io/Ever-Deeper/dev/. Publication commit `f8b3e16e4c58cd21d015ff019491f3a962194af2`, run `36015068520`: package, deploy and verify all succeeded. All 27 public hashes were checked: 9 new DEV files, 9 unchanged LIVE1.0.0 files and 9 unchanged Worn trial files. Receipt artifact `10814790284`, ZIP SHA256 `04e335b499d487d50841918717b443c30be7b49a8770af8c075fc2ec63bc8b28`. Previous DEV15.6 is available in rollback artifact `10814147652`.

This reporting task is complete. Do not re-export, retest or republish the unchanged candidate. Next action: Mats plays for 2–3 minutes after START REPORT, presses SEND REPORT, waits for the receipt, then asks to check the latest session. Read through the Sites database tools described above; do not ask him to upload a JSON file. If the private site requires sign-in and the transfer is lost during sign-in, return to DEV and press SEND REPORT again; the pending report remains on the phone. A receipt return link clears the matching pending report if Safari discarded the opener.
