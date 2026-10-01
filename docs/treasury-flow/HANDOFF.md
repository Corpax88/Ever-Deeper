# DEV15.36 continuous mixed treasury delivery

Requested 1 October 2026: remove pulsed donation and one-material-at-a-time order. Launch one visible resource every 0.06 seconds while inventory remains. Shuffle each complete round of available types using the presentation RNG, so no resource is starved. Keep all 27 destinations, existing art, and amount/landing accounting. Upgrades flash while the outgoing stream continues.

Reservations now count only the matching material. Same-material arrivals retain order; forward iteration also preserves that order when a slow frame advances multiple arrivals. The stream is bounded to 32 visible items and one launch per frame; no catch-up bursts. Menus still freeze delivery. Leaving cancels airborne reservations without debiting inventory. Resources and wallet gold debit only on landing.

## Verification

Local native Godot 4.7.2 / Xvfb / Mesa llvmpipe rendered the actual candidate PCK at 1688x780. Existing 9 walk-through checks passed. Final focused suite passed 38 checks: 216 launches over 27 types, up to 24 types in flight, 0.066667-second maximum launch gap at simulated 60 Hz, exact conservation, mixed upgrades without pauses, menu pause, cancellation and bounded million-item queues. The final mixed-stream capture was inspected. This is not a physical iPhone FPS claim.

The first Mac core run exposed obsolete tests requiring three-mote pulses and fully sequential resources. These assertions were updated to the new requested behavior; conservation and pause gates retained. Local intermediate native run caught insufficient same-type arrival separation; corrected before final passing verification. Failed evidence is retained, not counted as passes.

## Recovery

Current workspace: /workspace/scratch/b411e2c0ef28; local game /workspace/scratch/c939c7fc2e13/game. Canonical game source is the GitHub codex/treasury-flow-20261001 release branch. Main is the publication carrier; do not rebuild its historical runtime. Source test harness: tools/review_treasury_flow.gd. Web QA: .github/workflows/treasury-flow.yml and .github/treasury-flow/review.mjs. Builder retains the pinned DEV15.28 baseline and applies all subsequent accepted runtime replacements including resonance charge fix.

Native render requires --main-pack candidate/index.pck and the absolute review script; raw checkout has no imported cache. The Dummy audio driver warns about web sample playback; this is not browser audio validation. Mac/browser evidence and publication receipt are recorded in .github/treasury-flow.

Mac QA 36820194082 passed 29 browser gates, input and 404 core checks, and ordinary WebKit save/startup flow. Chromium renderer: ANGLE Metal Apple Paravirtual device, DPR2, viewport844x390. All16 Mac stills and sampled video frames inspected. Source 977bca363d0b8f35286fd881f81d94c8ad874e49. Candidate 11143110846 (sha256:fcf3f7fdb37c1bfe1569f2b00d27b54429cba2ca9b0099220ae00039930c76d7); evidence 11143450436. Mac file manifest equals the local final package exactly. No physical phone performance claim.
