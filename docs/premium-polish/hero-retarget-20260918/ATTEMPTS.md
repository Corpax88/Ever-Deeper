# Attempt log — stock motion on the original hero

## Inventory decision

UAL1 Standard has 43 clips, including walking/idle, but no mining/chopping clip.
No visual bank was produced from that unsuitable assumption. UAL2 Standard has
43 clips, including TreeChopping_Loop and Walk_Carry_Loop. Both actual packages
were obtained free from the author and include CC0 license files.
Use UAL2 for one bounded carry/chop trial; existing native idle is retained.

## Attempt 1: proportional transfer and native two-hand grips

The real hero has 17 bones; the donor has 65. The hero's arms are approximately
1.298 times the donor length, while legs are approximately 0.439 times the donor.
A single uniform whole-body scale is therefore unsuitable.

66 actual source poses were sampled before rendering. Native limb lengths and
closed two-hand grip geometry were preserved. Some wrist targets were beyond
native arm reach: maximum 0.743685 versus a 0.71 chain. No images were rendered.
The precise failure is a target-position compatibility issue, not evidence that
the approved hero must be replaced. Source motion, native rest arms, hands and
fixed shaft grip spacing have different proportions.

## Revised plan for attempt 2

Move the whole tool by the smallest iterative correction needed to enter both
arm reach regions. Both hands move with it; do not alter their spacing, meshes
or bone lengths. Retain some elbow bend with a 0.69 target limit. Record every
correction; reject the approach if it requires large displacement or looks poor.
First inspect eight actual material/geometry keyframes in the existing up view.
Only then render a short clip for the requested independent critic. This remains
an isolated study; floor contact and actual game timing are not accepted yet.

## Attempt 2: reach solved; visual mapping rejected

All 66 sampled poses now fit the exact native arm lengths. Maximum rigid tool
translation: 0.053685 model units (carry), 0.022915 (chop). Eight native beauty
renders were inspected. The independent critic found carry provisionally useful,
but rejected a full unchanged chopping render: wind-up/tool mostly hidden by the
body/backpack, and visible tool low beside the boot rather than a readable arc.
Timing, smoothness, weight and interruption were not inferred from those stills.

The source rig was then sampled directly, without rendering. TreeChopping_Loop
is one-handed: right wrist raised to z=1.659 at phase 0, left wrist at z=1.020;
their separation is 1.181. At phase .25 their separation remains 0.979. Thus using
the vector between the two wrists as a shaft axis was an incorrect mapping.
The poor transfer is not grounds to reject stock animation or the original hero.

## Revised plan for attempt 3

Keep the source body/legs and exact native hand/limb geometry. Derive chopping
shaft orientation from the right fist's index-to-pinky knuckle line and translate
the tool to follow the right wrist, with the left arm solved as support. Keep the
shared tool reach correction. This is a specific one-hand-to-two-hand adaptation;
knuckle-line tool alignment remains a hypothesis requiring visible confirmation.
Pass criteria: all sampled poses reachable, no tool/body crossing apparent in
eight native keys, and clear contrast between raised and impact silhouettes.
Only a promising keyframe result warrants a timed short clip. No full sprite bank.

## Attempt 3: reject this source/adaptation as a shortcut

66 sampled poses fit after correction, but maximum required common translation
is 0.767143 model units, exceeding the entire 0.71 native arm chain. The eight
actual renders still bunch hands near the head or hide the tool; no clear
outward two-handed impact is visible. The independent critic rejected a full
movie of this adaptation. Reach feasibility alone was insufficient and is not
reported as success. This result is confined to this one-handed source and the
tested mappings, not all stock animations or the approved hero.

No animation was integrated or published. No motion smoothness, game impacts,
transitions, cancellations, foot contact or iPhone performance was accepted.
The planned idle/walk/strike/stop film was conditional on useful source motion;
its keyframe gate failed, so it was not rendered. The carry poses remain only
provisionally useful. Total new native preview images: 16; no new atlas.

## Concrete next plan

1. Retain the approved hero and previously tested game/return source.
2. Qualify one actual two-handed mining/chopping source on its original rig
   before implementing a new mapping. Inspect raised/contact/recovery poses,
   hand spacing and tool direction; a suggestive filename is insufficient.
3. Transfer three diagnostic poses first. Native limb lengths and rigid two-hand
   grips must remain exact; choose a 0.10-unit correction cap before rendering.
   The cap is an economical study gate, not a universal anatomical criterion.
4. Only after a readable arc at the actual up camera, capture a short timed
   idle/walk/strike/stop sequence and have the critic review that motion.
   Actual game integration must then retain the 0.68s cycle and .42 hit phase.

The saved runner now applies that correction cap before rendering and records
source durations. Those new guard/report fields were syntax checked; the exact
earlier attempt reports are preserved unchanged. Reproducing attempt 3's rejected
images requires explicitly allowing 0.80; that is for historical comparison only.
