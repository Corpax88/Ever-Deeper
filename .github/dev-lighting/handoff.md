# FPS handoff — DEV9 iPhone result: 52.1 FPS, remaining pet-light cost

DEV9 is published and all 18 public files were verified at 2026-09-08T21:53:51.5171964Z.
Publication commit 7e3344605a0e5854c51e617b668b1002f9eaa856; run 34282895724.
Read publication-receipt.json for the verified deployment state.
DEV-only is authorized; LIVE 0.46.9 must remain byte-identical.

## Current candidate

- DEV version: 0.46.9-dev.9; URL: https://corpax88.github.io/Ever-Deeper/dev/?v=0.46.9-dev.9
- Exact package source: b6c0a4eca4d47f8134d12f58cd4a7b2607e25420.
- QA run: 34281591200 — all 11 jobs passed.
- Candidate artifact: 10077874087; ZIP SHA-256: a0bc315c32bb9a1a76a974bdb5625e7dd9bcb4a23cac574c4c725a6914a021ca.
- PCK: 219176904 bytes; SHA-256: 78fde726ddc232060827c2500460a81224c90476b63922ee73c6f4d6cbb927f2.
- All 13 evidence archives and all nine package files verified; final visual review passed.
- Review: .github/dev-lighting/review.json; raw numerical evidence: final-evidence.json.
- Previous DEV8 identity is pinned in review-dev8.json. Publisher downloads and verifies
  all previous LIVE/DEV bytes before staging and deploys the reviewed artifact without rebuilding.
- Hero v28, artwork, gameplay, save data, moving headlamps/shadows, resolution and DPR are preserved.
  Refetch main before changes; the other chat's wardrobe portrait work is separate.

## What changed and what was resolved

DEV9 caches only supported fixed lamps; ordinary moving headlamps and shadows remain dynamic.
The floor samples the same field directly. Original lamps remain available for fallback.
Version labels are synchronized. AUTO FPS TEST now lasts 3 minutes, ending with 70 seconds
of restored lighting, so the final observation crosses the earlier ~30-second delay.

The old preview failure is resolved: first capture raced the deferred field texture upload
and GLES3 light-atlas repacking. Four raw preview pixels changed by at most 1/255 (one screen pixel).
DEV8 and DEV9 with original lamps restored exactly. Waiting for completed fixture/upload
made all repeated levels exact. Only test synchronization was corrected; assertions were not weakened.
See preview-restoration.json and diagnosis runs 34280931704 / 34281360754.

## Verified results and limits

All ten current gameplay cases, both flavor checks, protected invariants, 35 native paired
states (including actual intact/struck gates), light/commerce previews and two DPR3 Chromium
probes passed. Every final visual state was personally inspected. Static differences are
small but not zero; larger localized elevator-disc differences are retained in final-evidence.json.
The eight unaffected-world pairs are identical.

Final paired Mesa FPS: hub 3.875 -> 5.809 -> 3.983; mossvein 4.572 -> 5.044 -> 4.668.
This is original -> cache -> restored on software rendering, not an iPhone prediction.
Cache lifecycle run 34281929628 (source 209df257c79c3d4d42d712e71eb576550545fa87) passed:
deferred activation under probe lock; source/mask restoration; unsupported-source fallback;
reconfigure recovery; temporary viewport release. Observed steady GPU overhead was ~19.71 MiB
for hub and ~2.20 MiB when subsequently entering Mossvein; rebakes did not grow allocations.
The two browser tests lasted 180.303 / 180.669 seconds; last restored windows were 70.011 / 70.046 s.
Original light/shadow counts and DPR3 framebuffer were restored; touch/cancel/focus checks passed.

## Next step

Mats supplied IMG_1748.jpeg for DEV9's 180-second hub test. Do not ask him to repeat it.
Original 52.1 FPS; pet lights off 60.0; restored 51.7; shadows off 53.2; restored 52.2;
all lights off 60.0; final restored (70-second stage) 52.1. P95 20–21 ms with normal
lighting, 17 ms with pet/all lights off. See docs/performance-diagnosis/light-cost/iphone-dev9.json.
Rows use the final eight seconds of each stage; do not describe them as whole-stage averages.
This confirms a large improvement from DEV8, but does not establish sustained 60 FPS.
Next targeted study isolates HelmetCone and HelmetBounce, with restored controls, from
the unchanged published PCK on branch codex-dev9-pet-light-isolation (e2de065abd8097cca4887d022b92a3a917ad0d72).
No new runtime optimization or publication has been made. Inspect study results before choosing one.

DEV8 phone evidence remains: 34.7 FPS at meter 52 s in the hub, 2328×1260 / DPR3.
The earlier temporary 59.8 FPS after restoration was not sustained.
No evidence establishes thermal or driver throttling.

Keep responses brief and Norwegian. No critics/subagents. Preserve audited cleanup.
Do not repeat pet-skill, audio, resolution/DPR or presentation experiments without new evidence.
Full earlier investigation and boundaries: handoff-before-dev9.md.
GitHub branches and artifacts are authoritative; local copies are partial, not git checkouts.
