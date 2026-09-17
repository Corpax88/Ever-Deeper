# DEV10 published — 17 September 2026

DEV URL: https://corpax88.github.io/Ever-Deeper/dev/?build=2307601
Displayed version: `1.0.0-dev.10`. This is a verified playable correction, not completed premium polish or final 1.0.

## Exact source and publication

Authoritative root Godot source: `Corpax88/Ever-Deeper`, branch `codex/dev10-polish-20260917`.
Reviewed runtime source: `23076019b53819c6c7f213b7e55d24a2f6194f83`.
Subsequent `7180d6a`, `c6fa219`, `c14281c` add/fix isolated extra CI workflows only.
The previous local commits `adc6cee`, `b8c5edc`, `25c69bc` have identical trees to uploaded `9906cbc`, `39e3ddf`, `2307601` respectively. The original local history remains on `codex/dev10-local-checkpoint-20260917`; do not duplicate or reset it.

Shell git could read but had no write credentials. After Mats explicitly replied “Alltid godkjen” to the concrete public-code/DEV request, the authenticated GitHub connector uploaded equivalent git trees. This approval continues for Ever-Deeper code uploads and gated DEV publication; do not ask again. No LIVE release is authorized by this DEV publication.

Publication adapter commit: `5e7b431adbf50a4a9fd77303c12c26bc9b6802af` on main.
Publication run: https://github.com/Corpax88/Ever-Deeper/actions/runs/35182372885
Package/deploy/verify all pass; **nine new DEV and nine unchanged LIVE files** independently checked by the publisher. Receipt is in this directory and on main (`cbc1dd2`). Rollback artifact `10480758976` retains both previous packages; its ZIP SHA256 is `3d3780407960ea61f484ddf6073d71bf41356e0f1d5a15598b2393a094841e17`.

DEV candidate artifact: `10479804355`; complete review: `10480503718`.
Candidate ZIP SHA256: `026fae146631d599c933d09b635574e8b1c7bb7ed3501c0dbc898ff79be45a3d`.
PCK: `221007492` bytes, SHA256 `8b83ed55d62841eac8e891ad6c224b101665d98f5ead63a022e66589d6266c3b`.
Local and CI package bytes match; all nine identities are in publication-receipt.json.

## Completed evidence

- Exact-package QA run35181119505: all12jobs pass, including15core suites, DEV/Production flavor,19shop visual states,1267Chromium gameplay checks, six touch sections and58commerce resource-lifetime checks.
- The same CI PCK also passes47rendered hazard lifecycle checks at1696×780: full telegraph/held mining, journal pause with0px drift, ordinary resume, fresh hit, Tunnel Home and Deep re-entry.
- Independent critic accepted15actual current CI images, preserving v28 hero/art, menus and controls. A suspected text defect in the default image viewer disappeared at original resolution; exact glyph pixels differ by at most1channel value, no missing glyph geometry. It was a review-display artifact, not a game change.
- Extra run35181478025: Chromium and WebKit actual audio output each pass unlock, common/rare overlap, discovery duration, mute and unmute. No subjective listening claim.
- Same extra run: Worn/Crusher/Deepcore x4directions produce12real damage cases. Independent critic inspected287sampled video frames; no new visual blocker. Video848×390 at25encodedFPS on SwiftShader is not precise contact-time or smoothness certification.
- Linux WebKit gameplay/pause raises glBlitFramebuffer INVALID_OPERATION. These failed artifacts remain retained. The same immutable package and assertions pass on Mac WebKit, run35181878479:1269gameplay+9pausechecks, Apple GPU,1696×780buffer, zero observed GL/script errors. No errors were suppressed.
- First Mac WebKit run35181702247 failed before launch because GNUtimeout was absent; use Actions step timeout on macOS. The corrected attempt is a separate successful run.
- Virtual-Mac five-minute real-input sessions, run35181119506, are functional with isolated persistence and0orphan nodes. FPS ranges: Hub53.60–58.39, Ember37.54–51.32, Deep31.53–44.04. **All fail stable50FPS acceptance**. GPU timestamp values were invalid; engine CPU monitor samples repeat and are not true per-frame CPU percentiles.
- Existing publisher11offline checks pass against actual candidate/completeZIPs and complete API receipts; independent adapter review approved the exact DEV-only route.

## Remaining work

The only DEV10 production change is the five-line world physics pause/restore plus version identity. Approved art, animations, balance and schema3 remain unchanged.

Stable50FPS, fullworld joins/Bedrock/Voidstar cohesion, all11tools/directions, physical-iPhone feel and final9/10 remain open. The old player_visual.gd protected-baseline mismatch remains explicitly recorded; no invariant was weakened.

The shadow-mask experiment remains unadopted. Enabled moving-draw diagnosis lives separately on `codex/dev10-moving-draw-diagnosis-20260917`, commit`7623117951008822e9e120950bb92b3e522dfda1`: real Deep35.91/36.39FPS; section setup1.858ms/frame, draw callbacks0.091ms/frame. Renderer dominates; a maximum~0.963ms/frame setup-only opportunity is not a demonstrated improvement or50FPS solution.

Active next work after this checkpoint: isolated camera-bounds reuse parity experiment and coordinating simultaneous achievement/pickup labels. These are **not in published DEV10**. Preserve actual failed comparisons as well as accepted evidence. Only one heavy local renderer may run at a time.
