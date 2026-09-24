# DEV15.8 — labelled light diagnostic

Publication pending independent visual acceptance and deployment. Source `ab298e05d135bbdfd6bd555d03ef294d6370ace8`, branch `codex/lighttest-dev15-8-20260924`. Based on public DEV15.7, excluding the rejected composite-floor experiment.

The opt-in LIGHT TEST + REPORT · 3 MIN now works in Emberdeep depth1. It automatically records seven phases: original60s, pet lights off10s, restored10s, shadows off10s, restored10s, all lights off10s, restored70s. Each phase has settle/measure markers after a two-second settling interval. Old windows flush before the light mutation, and the next interval clock resets. Existing schema1 events carry labels; no receiver schema or deployment change. SEND REPORT on the result screen transfers the existing private report. No network transmission occurs during measurement.

Original light states restore on completion or cancellation. Movement, world/depth change, opening a menu, focus loss, recorder loss, scene exit and browser interruption stop the test. Existing active or pending reports are protected. Assets, render resolution, native animation and DEV save identity are retained. This isolates lighting cost on the phone; it is not an FPS fix.

Export run36030554231 created the exact candidate. Initial headless touch check stopped on a dummy renderer texture initialization error in the unchanged Skills panel. Validation run36030905015 reuses the same artifact without re-export, retries only touch and preserves passing input/dev-tools/build-flavor evidence; all four now pass. Validation source `33f639393ae5ce92a6b7a4301a86c39c9abd204f`.

The inherited check_invariants.py still fails its QA argument/documentation-order assertion. This is reported, not suppressed as a pass. Explicit exported cases remain authoritative for this scoped change.

Physical iPhone execution and performance conclusions remain pending. Mac Chromium is used for the full180-second measurement; WebKit uses accelerated QA-only stage timing for state/transfer/recovery, not performance claims.

Both ordinary report workflows and both labelled light workflows passed on the exact package. Chromium ran the full sequence; WebKit verified transitions, report transfer and recovery. Ordinary WebKit startup passed. Actual receiver route/schema with test-only auth/database adapters and in-memory SQLite accepted both exported reports and preserved the complete payload, all windows and all15 phase markers. Chromium recorded179.4673 seconds across43 windows; WebKit accelerated state validation recorded19.348 seconds across14 windows. Both are QA fixtures, not phone evidence.
