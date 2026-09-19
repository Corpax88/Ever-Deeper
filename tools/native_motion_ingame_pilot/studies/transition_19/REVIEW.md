# Study19 transition review

## Findings and corrections

1. Baseline entry11→12 and cancellation25→26 visibly swap backpack sides and
   tool orientation. Legacy idle uses a different heading/camera convention
   from18B. The critic rejected hiding this with a fast turn. Reuse18B frame0
   as the common Worn/up ready stance. Reverse shown preparation on a pre-hit
   release; continue withdrawal after an actual hit. No new loop render.
2. Moving at125 still instantly swaps to the old front-facing walking sprite.
   Render one exact native bridge from shown cell31 to down walking over.20s,
   using the ongoing distance/144 walk phase and genuine articulated legs.
   Camera-space conversion preserves the original endpoint projection.
   The13images are new full-body rig renders, not warped/crossfaded sprites.
3. Rapid restart after a hit initially blended an unwrapped phase. At62→63,
   shown cell49→5 caused a small backward head/torso step. Diagnosis: the
   blend traversed the flat ready region at full speed. The revised plan
   completes withdrawal, then eases preparation onto the authoritative clock.
   It reuses the same50frames; no additional native rendering is needed.

## Independent findings so far

- Stationary: entry11→12, restart43→45, cancel25→43 and post-hit61→85 keep
  facing and connected poses. No strike pose appears in the cancelled return.
  The critic passes these stationary handoffs as an ordered-frame review.
- Walking:124→125 keeps the outgoing pose;128→136 turns progressively with
  changing boot placement;137→138 matches the old walk. Only a small helmet
  highlight change is noted. No geometric correction is indicated for this
  exact exit. Foot-ground locking is not established by the reviewed images.
- First rapid run:26→30→37 is connected; both actual hits47/76 meet the ore.
  The critic singled out62→63 as the small timing refinement above.
  The same walk also passes at83→84 and95→96→97.

These are image-sequence verdicts, not continuous-video viewing or a numerical
9/10score. Original timestamps and full-image hashes remain with the evidence.

## Executions and limits

| Capture | Actual game frames | Result |
|---|---:|---|
|18B baseline|180|Runner0; two hits/eight damage|
|Same-facing stationary19|180|Runner0; all180 mechanical rows equal baseline|
|Native walk19|180|Images/report complete and mechanics equal; runner4 because its log was empty and the completion marker was missing|
|Rapid restart19A + same walk|110|Runner0 with intact completion marker; hits47/76, no unsupported requests|
|Scope guard|5|Runner0; supported Worn/up and four unsupported combinations selected correctly|

Do not rewrite the failed-log walking execution as a pass. The later110-frame
run separately validates execution of that exact bridge. Its source hashes
were captured at startup; `versions/transition_visual_19a.gd` is the exact
rendered consumer.19B adds the gear/outfit guard;19C refines rapid restart.
The final19C run and critic verdict are appended after completion.

The guard test exercises Worn/up/base green, Worn/right, expedition clothing,
Crusher/up and Deepcore/up. Unsupported cases explicitly use production
sprites; this is **fallback verification, not new motion coverage**. Disabling
the inherited18B substitution was necessary to avoid displaying a Worn tool
for another up-facing gear. Other supported-direction changes still need work.

New idle currently uses the static ready frame; breathing/blink integration is
open. Walking is limited to the exact cell31→down, phase0 first-stride bridge.
Other source cells, headings, walk→mine, interruption inside that bridge,
all equipment/outfits, strict foot locking and normal-speed final acceptance
remain gates. No production sprites, gameplay clock, LIVE or DEV changed.
FPS remains paused. No final9/10 or general transition-system claim is made.

Input QA passes. The invariant checker retains the already documented
`scripts/player/player_visual.gd` protected-baseline mismatch; that file and
all production hero assets are unchanged by study19.

## Final19C result

Final110-frame rapid run: runner0 and required completion marker,
Godot4.7.2/X11 at1696×780, fixed60Hz. Source hashes captured at startup match
the final `capture.gd` and `transition_visual.gd`. All110 mechanical rows are
identical to the previous rapid run: hits47/76, eight total damage, zero
unsupported walk requests. This confirms the tested bridge on the final
consumer as well as the corrected post-hit restart. The scope guard capture
uses the same guard code; the final change affects only rapid restart timing.

Independent final verdict:62→63 is materially improved; helmet, chest and feet
remain nearly aligned as withdrawal reaches ready.64→69 builds the backswing
progressively; facing, hands and tool remain coherent. Contact at76 remains
readable. Bounded image-sequence pass; no further correction is indicated by
these images. Continuous playback, foot locking and general coverage stay open.

Only13new native images were rendered during study19. Existing18B's50frames
were reused unchanged. Baseline180 + stationary180 + walk180 + rapid110 +
final110 =760actual gameplay frames; scope adds five images. The walk capture's
missing-log failure remains recorded above, not counted as a passed runner.
