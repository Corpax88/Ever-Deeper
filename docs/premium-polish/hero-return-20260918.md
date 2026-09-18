# Original-hero complete return — 18 September 2026

Current work: hero animation; FPS work remains paused. This is a bounded Worn/up study,
not a production adoption, full-animation acceptance or new DEV/LIVE publication.

## Exact source and saving limit

- Local tested source: `e1e0193115935765a07c2f260c2c4da8653d45cb`, tree `9acb66f80e2fb760a9befd7eb7ffbfce84a57410`.
- Checkout: `/workspace/scratch/b465f3665b0c/ever-deeper-hero-animation`.
- Branch: `codex/hero-animation-dev13-20260918`; DEV13 base `5ca6f0f77a1f87eaead777613062208159325068`.
- Last confirmed remote head: `b4b8f3e2779fdc52d6ba3a36a60ebe387098cd5f`, tree `eef8f5af7068af9ff3dccd727fe0b6702023b135`.
  This contains the new native builder but not the packed bank, selector, comparison helper or this documentation.
- Automatic approval review rejected public GitHub upload twice. The second rejection retained
  the block after exact repository/admin/push permission and a seven-file diff were verified:
  an explicit user yes in the active chat is required. Do not bypass this with connector writes.
  Complete local work is retained; do not claim that the pending source is uploaded.

## Closed native and actual-game evidence

The original Blender4.5.3 model/gear, body/feet, camera, clocks and 160px packing remain.
The additive builder verified218 cells and12 transition clips;118 image pairs are reused
only after exact all-bone matrix equality,100 pairs are newly rendered. All protected
matrix deltas are0. The12 held-source late-cancel cells remain byte-identical.
Native run exited0 in359.121s. Its final report SHA is
`996ead7ae03620e4997b62f8789e2745fb591457f218172645340c1b5262c0a2`.
Native manifest SHA: `b7f75d7a7f67d5f8338b70dc055e271b75ae3af59fa17b54b9ee4fb4141c7e46`.
Packed manifest SHA: `e2fcf1275bc80c88fa5ee5c1768154445e355ea587db58d80032ec50efa09516`. Two pages;436 source and packed cells independently checked.
All new/native matrix evidence is retained. Capture selector changes only the selected bank,
its identity check and reporting flag; the consumer, input and game clocks are unchanged.

All four actual cases exited0, passed their fixture checks and exactly matched named closed
controls for mechanics, input and world state.401 original1696x780 PNGs were hash/full-decode
checked. The comparison reports name the prior controls explicitly.

| Case | PNGs | HP-hit frames | Actual report SHA256 |
|---|---:|---|---|
| loop | 119 | 50, 90 | 5860a3c45a5611367b0ce496dc028178b6b7d6676195fef2c5fcc5e598dfbd15 |
| cancel | 94 | 70 | a11995dcc5c092b1658de8f58696ba67a3ac6c78bc1eeba48b40ef566e9ff1f8 |
| restart | 89 | 65 | 3e5f1ca1b80f24215c26ad2aeb9eaba5e1d48b97212734d03a19a89137d3a1ed |
| late-cancel | 99 | 75 | 7d520a331663fa06d1da139f087bc994c1963aab7ae6342c7e64df9ad4a0c217 |

Independent critic inspected182 of401 captures as sequential originals/crops and accepted
this narrow milestone: completed recovery and coherent stop/restart without a new visible
body/foot reset. This is not a claim of continuous video playback or all-frame visual review.
First displayed early-stop frame is cell1; rebuilt cell0 is not exercised in that route.
Late cancellation intentionally remains C0 with a short brake, not a C1 velocity bridge.

## Runtime and recovery

Godot4.7.2 (`ed1daf0bf`), Linux X11/OpenGL4.5, Mesa25.2.8 llvmpipe LLVM20.1.2.
Native1696x780; logical framing differs and must be scaled for screenshot crops.
Fixed60Hz simulation is not measured FPS. Software-driver VSync/sample-audio warnings occur;
these captures do not certify audio or any physical iPhone/Apple renderer.
Godot: `/tmp/ever-deeper-runtime-20260918/Godot_v4.7.2-stable_linux.x86_64`.
Blender: `/tmp/ever-deeper-runtime-20260918/blender-4.5.3-linux-x64/blender`.
Authenticated Xvfb: `/workspace/scratch/b465f3665b0c/runtime-20260918/xvfb/usr/bin/Xvfb`.
Use `tools/run_rendered_isolated.py`; one heavy engine at a time. All runs here are closed.
Actual commands/run records/reviews: `/workspace/scratch/eb19e34b942d/evidence/complete-return`.
Native raw bank: `/tmp/ever-deeper-complete-return-bank-20260918/render-01`.
Actual cases: `/tmp/ever-deeper-complete-return-game-20260918/{loop,cancel,restart,late-cancel}`.
Repack with the unchanged `tools/hero_v28/pack_frames.py --frames <native-bank-root> --gear worn
--manifest pilot-manifest.json --output-dir tools/native_motion_ingame_pilot/assets/worn-complete-return`.
The capture options are `--complete-return --contact-frame-order --startup-wall-seconds=600`,
plus respectively no route flag, `--cancel-cycle`, `--bridge-restart-cycle`, `--late-cancel-cycle`.
Retain `--fixed-fps60` as separate tokens `--fixed-fps 60`, exact source SHA and a fresh output.
Private originals remain outside Git at the model/gear paths in the prior entry handoff.

## Saved evidence and next action

Evidence deliverables are named `Ever-Deeper-helteretur-bank-og-loop-20260918.zip`,
`Ever-Deeper-helteretur-tidlig-stopp-og-gjenstart-20260918.zip`, and
`Ever-Deeper-helteretur-sent-stopp-20260918.zip`. They omit Git source, private Blender originals,
userdata and authentication files. The first has native raw frames; the three together retain
all four original game captures and the independent assessments.
`Ever-Deeper-helteanimasjon-testfilm-20260918.mp4` shows all401 frames in original order/timing,
with a fixed310x230 physical crop and24px labels; no interpolation or repetition.

Next: after explicit user consent, upload the pending source/atlases/documentation to the
existing branch without publishing DEV/LIVE. Then address hidden rest axe/grips, contact
readability, fast final downstroke and late pre-hit pose hold. Broader directions/tools/targets,
arbitrary input, the prior rest-cycle layout issue and physical-mobile acceptance remain open.
Do not rerun15-core solely for an unchanged fixture/bank; prior world QA remains documented.
Do not transfer this narrow review to production or claim overall9/10.
