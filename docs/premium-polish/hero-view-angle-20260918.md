# Camera elevation study — 18 September 2026

Mats explicitly allowed changing the angle if that helps. This study interprets
that permission as changing the native hero camera elevation first; retain its
azimuth, character/tool geometry, lights, scale and saved animation poses.
It does not change the world camera or publish a new sprite bank.

## Plan before reviewing the images

Reuse the actual previously tested CompleteReturn bank's final pose matrices,
whose report SHA256 is996ead7ae03620e4997b62f8789e2745fb591457f218172645340c1b5262c0a2.
Do not reuse either failed stock mapping: their kinematic problems are distinct
from camera occlusion. Restore only the archived native report as a pose input.

Render nine transparent256px originals: idle0, nearest saved wind-up to.40,
contact.55; existing elevation about35degrees, then45 and55. Apply and verify
all17 bone matrices directly; keep lighting and orthographic scale2.9 fixed.

Pass criteria: a clearer axe/shaft and readable hand contact across the three
poses, useful wind-up/contact contrast, and preserved character proportions.
An unchanged azimuth preserves the ground-heading axis, but changed vertical
projection/ground anchor and ore contact need actual-game integration before
adoption. Stills cannot verify motion timing, transitions or smoothness.

Use one concise independent image review. If a view is promising, identify the
smallest follow-up that checks it in motion/in context; do not expand to all tools.
Retain successful data and revise the plan before a failed trial is repeated.

## Elevation result and revised plan

Nine original renders completed with maximum all-bone deviation4.18e-7 from the
saved poses. Raising the view shows more helmet top and compresses body height,
but the idle hands remain occluded. It does not satisfy the planned visibility
criterion. No motion bank is warranted from this result.

The revised test keeps the baseline elevation and samples azimuth offsets-25
and+25degrees, using the same three saved poses. Six new images; reuse the first
trial's baseline for comparison. This tests whether lateral viewing exposes the
hands. Rotating the sprite view also rotates its projected aim; that must be
checked against the actual target before any adoption. Do not treat the view
change as proof of corrected tool contact or solve it by changing the world.

## Side-view review and bounded in-game follow-up

The independent angle critic selected+25degrees azimuth at the baseline elevation
for one short motion/context test. More shaft/head/grip is outside the helmet;
two-hand contact remains partly crowded and the contact pose is still upright.
Elevation-only and-25degrees are not worthwhile candidates from these stills.

Follow-up plan: reconstruct the exact76 unique native cells actually presented
by the previously closed119-frame loop, using its recorded bone matrices. Render
only those cells at+25degrees, with the original200px/8-sample export and masks.
The other142 cells retain their old bytes only to preserve layout; presentation
of any of them must fail the study fixture. This mixed, incomplete bank is never
a production candidate. Existing input/consumer/clock/world remain unchanged.
Update the ground anchor for the changed camera and run one actual Godot loop.
Check actual targeting and foot direction; a view advantage can fail in context.
No broad bank, all-tool expansion, FPS test or publication is authorized by this
local visual result. User permission for angle changes does apply to this study.

## Closed actual-game result

Blender4.5.3 rendered76 beauty/mask pairs using the saved exact bone matrices,
200px and8 samples. Two packed pages preserve the prior218-cell layout; all119
actual presented draws belong to the76 newly rendered cells. Godot4.7.2/X11
Mesa25.2.8 llvmpipe exited0; no new input, consumer, world or hit-clock behavior.
This is Linux graphical evidence, not Safari/iPhone performance certification.

The independent mechanical comparison passed all119 captures, both hits at50/90,
input events, sampled states/phases and initial/final world equality. Every PNG
was hash checked and fully decoded. Updated ground-anchor coordinates are checked
against the new bank; sprite placement need not equal the old camera's placement.
The capture source was local64cf95e (full identity is retained in the game report).
The angle-specific review tolerance change only concerns JSON float round-off.

Actual game report SHA47f51cae47e12efb2ea4fe9f83f6ae95b075f2439c0e40f089e425083a0e2117.
Packed manifest SHA4c7a0a9566c0a5e17e53d3078a958f3c9417a11ef285313ea4482d3b80b2d7ed.
Control report SHA5860a3c45a5611367b0ce496dc028178b6b7d6676195fef2c5fcc5e598dfbd15.

## Independent visual decision

Keep+25degrees as a limited visual candidate. Its gain survives the actual scene:
frame40 has a clearer raised pick head, shaft and arm silhouette. At gameplay
size, both hands still merge near the face; the contact pose remains cramped.
At50/90 the head blends into the ore's near edge, so a convincing visible strike
is still difficult to read. Mechanical timing agreement is not physical contact
proof. Walking looks more turned toward screen right.

The critic viewed10 chronological before/after pairs, not real-time playback.
This cannot establish perceived timing, complete swing continuity or locomotion
alignment. The mixed76-cell bank is not adoptable. No production, DEV or LIVE
change was made; FPS work remains paused.

## Saved result and next step

`Ever-Deeper-vinkel-spillprove-20260918.mp4` contains all119 draws from both cases
side by side at the original60Hz simulation cadence, fixed310x230 crop per case
and28px label band. No new/repeated/interpolated frames; fully decoded. It is a
comparison of controlled game captures, not measured device FPS.

`Ever-Deeper-vinkelprove-bevis-20260918.zip` preserves native angle stills, the76
new native beauty/mask pairs, the guarded packed bank/identity, all119 new actual
scene captures, logs, reports, movie-edit metadata and the critic's observations.
It excludes private Blender originals, repo source and test save files.

Next: retain+25degrees for a bounded strike-readability study, checking tool head
and both grips against the actual ore in three poses before more motion output.
Also check foot/heading alignment before extending the view to other routes.
Do not repeat the failed elevated-camera or one-handed source trials. No complete
replacement bank until contact, motion and stop/restart behavior are accepted.

## Recovery

Restore the packed-angle-bank directory from the evidence archive to
`tools/native_motion_ingame_pilot/assets/worn-angle-25/`; it is intentionally
not committed as an adoptable asset. The existing capture fixture accepts
`--complete-return --view-angle-probe --contact-frame-order` only for the exact
up/loop route and fails on any non-angle cell. Keep identity.json beside the five
packed files. The commands/run identities in the archive name exact sources.

The source producer is `tools/hero_retarget_probe/angle_bank.py`. Its input is the
previous saved `Ever-Deeper-helteretur-bank-og-loop-20260918.zip`, native v28 and
Worn v9. Before packing, preserve the old render_fingerprint as
reference_render_fingerprint and replace it with SHA256 of the completed angle
report; pack using the existing200-to160px packer. identity.json binds the five
packed hashes and the76 rendered cells from that report. The archived ready bank
avoids repeating this work merely to restore the exact tested scene.

Local tools: `/tmp/ever-deeper-runtime-20260918`; Xvfb restored at
`angle-xvfb/root/usr/bin/Xvfb` beneath it. Restore the ordinary extracted packages
from the existing test-environment guide if missing; no authentication bypass.
