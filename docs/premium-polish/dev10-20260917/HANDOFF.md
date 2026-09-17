CURRENT: [Verified published DEV10](PUBLISHED.md). The following is the earlier local-candidate record, retained as history.

# DEV10 candidate — menu physics, 17 September 2026

This is a tested local candidate, **not a publication or completed premium polish**.
The last published game remains DEV9 (`e76a2b9`). No public branch was updated.
Base: `1b9cfe26485c0f01dade7f2bbd6153cbc3c5fb9a` on
`Corpax88/Ever-Deeper`, `codex/premium-polish-recovery-20260915`.
Candidate branch: `codex/dev10-polish-20260917`; runtime/export source: `b8c5edc`.
Later commits add review records and CI branch routing only.

## Included runtime change

`main.gd` now suspends world physics while a commerce/companion panel is open,
then restores the previous physics-processing flag on close. DEV9 only stopped
ordinary processing, so an already-triggered Deep surge continued moving the
hero behind the journal. The restored flag preserves worlds that did not have
physics enabled in the first place. Pending impulses resume normally on close.
Display version and the existing capture expectation are now `1.0.0-dev.10`.
Approved production art, animation, balance and save schema 3 are unchanged.

## Completed verification

- Recovered actual Godot `4.7.2.stable.official.ed1daf0bf` and authenticated Xvfb.
- DEV9 rendered mining/Deepheart contact suite: 16 passing checks.
- Real hazard telegraph, held mining, surge, journal, close, renewed mining,
  Tunnel Home and re-entry: initial DEV9 fails two checks with **59.088 px** of
  movement behind the menu. The fix has **0 px** movement and **47/47** passes.
- An intermediate fixed run failed a premature 0.45-second settlement assertion.
  Its raw evidence is retained. The final fixture observes ordinary physics with
  a bounded 120-tick/20-second deadline before proceeding; every original pause
  assertion remains unchanged. This prevents teleporting with an unsettled push.
- Independent critic inspected six actual images and the five-line runtime fix;
  accepted this bounded change without a whole-game score.
- Exact exported DEV PCK: all **15 current core suites** pass.
- The same package passes the DEV build-flavor check.
- The same exported PCK, launched outside the source tree: **47/47** rendered
  hazard lifecycle checks pass at actual **1696×780**, including zero menu drift.
- Native renderer is Linux Mesa llvmpipe. These are functional/visual checks,
  not Safari, Apple GPU or physical iPhone performance evidence.

PCK SHA-256: `8b83ed55d62841eac8e891ad6c224b101665d98f5ead63a022e66589d6266c3b`.
PCK bytes: `221007492`. Full nine-file identity is `package-identity.json`.

## Performance experiment — not adopted

`tools/shadow_mask_pilot/` subclasses the production caster generator and keeps
every rectangle, vertex and PCF setting. The first eight full-frame A/B/A2 pairs
are pixel-exact; managed light/caster pairs drop from e.g. 156 to 64.
The subsequent code review fixes temporary-bit ownership during StaticLightField
rebakes and respects original mask eligibility. Production never loads this tool.

Three serialized 60-second Deep sessions give **37.162 / 37.224 / 35.053 FPS**
(control/candidate/restored control), with 4,228 mined resources each. Candidate
gain against the first control is only 0.17%; baseline drift is larger. This does
not establish a useful speedup. The candidate stays isolated, with no adoption,
50-FPS claim, or Mac claim. Do not repeat rejected contour/crop/receiver studies.

## Remaining gates and continuation

1. Push this reviewed branch only when external publication is permitted.
   The two existing CI workflows now include this branch, retain `contents: read`
   and isolated saves, and will run exact-package browser checks and Mac sessions.
2. Inspect new CI evidence; do not reuse DEV9 QA/artifact identities. The new
   rendered hazard lifecycle step is already wired into exact-package CI. A browser audio
   check is still open; the older one-point-zero workflow has stale DEV8 text.
3. Publish DEV only after its remaining gates pass, with a fresh immutable
   candidate identity and the DEV9 publication receipt as rollback baseline.
   Preserve all nine current LIVE files. No publication adapter has been changed.
4. Continue the actual full polish: stable 50 FPS, Bedrock joins/Voidstar clusters,
   all-tool/direction animation coverage, browser hazard/audio, and physical
   device feel remain open. This bounded fix does not complete those tasks.

Browser probing in this session could not reach the loopback preview
(`ERR_BLOCKED_BY_CLIENT`). Do not turn that into a game or WebGL failure; use the
established CI route. Existing `check_invariants.py` still reports the documented
DEV9 `player_visual.gd` baseline mismatch; its protected baseline was not changed.
All fresh source changes are retained in an incremental git bundle and patch
alongside the exact candidate and raw evidence; see the detached continuation.

## Runtime recovery

Godot: `/tmp/ever-deeper-runtime-20260917/Godot_v4.7.2-stable_linux.x86_64`.
Xvfb: `/workspace/scratch/d5437d917805/runtime/xvfb/usr/bin/Xvfb`.
Checkout: `/workspace/scratch/d5437d917805/ever-deeper`.
Use `tools/run_rendered_isolated.py`; one heavy renderer at a time.
Native exact-package regression uses an empty `--project` directory plus
`--main-pack <index.pck> --script <absolute tools/review_hazard_pause.gd>` and
`-- --pack-source=<index.pck> --output=<absolute evidence directory>`.
Keep the explicit `HAZARD_PAUSE_COMPLETE` completion marker and inspect the JSON.
