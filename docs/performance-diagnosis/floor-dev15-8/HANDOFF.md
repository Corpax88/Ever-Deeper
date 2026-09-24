# Floor-lighting study — rejected for performance

24 September 2026. Candidate is **not accepted and not published**. Ordinary DEV remains DEV15.7. No physical iPhone improvement is claimed.

## Result
An opt-in shader combines depth-one opaque underlay and tinted floor texture into one lit draw. It remains disabled in normal gameplay. Original reference is retained. Assets, hero animation, saves, reporting and LIVE/Worn are unchanged.

Source/export 32b1470e7efc729f7ba5d18dda64c85ec4cf7c25, branch codex/floor-lighting-dev15-8-20260924. Exact PCK SHA256 2c109f70ba587a685696b81b238774c62e33be5ffa944db5287c2b200cd29d7b, 259867612 bytes. Version inside the experimental package is still DEV15.7; it is NOT the public package.

Main run 36025763317: five exported core suites, Skills checks, actual Mac Chromium/Metal and ordinary Apple WebKit new/saved startup succeeded. Seventeen full-frame reference/candidate pairs differed by at most 1/255 per channel; every restored reference was identical. Root inspected all four biome contact sheets covering intact/damaged/broken/restored. No visible difference found in that limited fixture; maximum-upgrade lighting was not covered. No independent release acceptance was requested because performance rejected the candidate.

Initial A/B/A was inconclusive: about 57.3/52.7/51.3 FPS with scene resets and timing drift. Draw calls fell 221 to 185. Runtime assertions passing are not evidence of an FPS improvement.

A single targeted follow-up reused the exact export, without rebuilding. Harness df55593515a3bf2ddfef660dca0f97cadd771d2f; run 36027470057. 45s warmup, continuously held mining, no intervening scene resets or screenshots; six 20s windows in A/B/B/A/B/A order. Original windows: 58.39,58.20,57.68 FPS. Candidate:57.23,56.89,55.64 FPS. Weighted original 58.090 versus candidate56.586 FPS (2.59% lower). Draw calls220 versus184 (16.36% fewer); candidate maximum stalls381.6/166.4/422.4ms versus original63/54.3/68.5ms. Causality of individual stalls is not established, but this fails an improvement acceptance criterion. Do not promote based on green execution checks or fewer draw calls.

The timing report source_commit is the harness commit, NOT the export commit. It records the exact package manifest; compare that manifest to the original build before reuse. All results are Apple virtual GPU measurements, not physical-phone timing.

## Artifacts
- Candidate10819753028; build10819588382.
- Original browser evidence10819694253, SHA256 e1d37f914e14581be677acaa373c549ab9f24b3c9f33f6bb599c4d0203daff82.
- Repackaging run36027130484, artifact10820565278: existing original pixel metrics, unchanged reports and CSS-size contact sheets. No repeat game testing. Original full-resolution captures remain in the original artifact.
- Timing10820926245, SHA256708eafbf9b369c007b0184092cc030d1b1051547059530b05a6305a8f670e24a.
- Local evidence /workspace/scratch/41a58a9f2ec4/floor-evidence; source files /workspace/scratch/41a58a9f2ec4/floor-study. Git/CI are durable authorities.

## Recovery and next decision
Established Mac Actions route works; no new credentials are needed. For large browser artifacts exceeding the32MiB executor transfer limit, use a read-only packaging workflow against the exact original artifact; it produces small review materials without rebuilding or rerunning gameplay. Direct signed-URL fetch returned403 here; no access controls were altered.

Do not rebuild, repeat this unchanged test or enable composite_underlay as a proven fix. The current candidate does redundantly set two shader uniforms whenever draw_floor runs; caching unchanged values is a possible revised implementation, not a measured explanation for the stalls. It would need a fresh bounded comparison if chosen. Broader lighting/rendering remains a hypothesis supported by old phone light-off controls, not established by this failed optimization.

Best next diagnostic direction is a same-area physical-phone reversible test that isolates current lighting cost from canvas pixel load, with stage labels in the private reports. Existing AUTO FPS TEST only supports hub/depth2, whereas this user's report was Emberdeep depth1. Do not claim it covers this case. Avoid changing resolution blindly: older resize experiments had WebGL errors. Any new diagnostic must preserve saves, normal graphics and recovery on interruption.

No publication occurred. This first floor optimization experiment is complete and rejected; the user's overall physical-phone FPS problem remains open.
