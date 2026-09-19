Latest checkpoint: [overhead18B actual gameplay preview](hero-overhead-swing-18-20260919.md).
Internal critic: clearer rearward load/body strike; all four impacts meet the ore;
withdrawal returns to ready. Preview pass only; continuous motion/production remain open.

Latest checkpoint: [simple swing17 actual preview and remaining gates](hero-simple-swing-17-20260919.md).
17C improves visible contact and tool readability. Withdrawal clearance and final
visual acceptance remain open; production and LIVE are unchanged.

# Hero animation: local independent review

Mats's direction on 19 September 2026: progress must not repeatedly stop for
external video-service sign-in while he is away. Use an internal critic for
the work that can be reviewed locally. Gemini is an optional additional review,
not a prerequisite for every investigation or correction.

This changes the review workflow, not the approved hero or release requirements.
Keep Gruvepappa v28, the FPS pause and the existing visual/gameplay release gates.
No production adoption or LIVE publication is authorized by a diagnostic pass.

## Routine

1. Reuse the existing independent critic. Give it the exact candidate capture,
   source identity, original frame timestamps and a short, neutral review task.
   Do not ask it to produce a desired score. Use one bounded review per reasoned
   attempt; another attempt needs a concrete failure analysis and revised plan.
2. Review actual rendered frames from the game. Bind the image sequence to the
   captured candidate and retain all original timestamps. Cover entry, impact,
   follow-through, the return, the next impact and exit. Inspect short ordered
   frame sequences around a suspected defect and use motion/contact data to
   distinguish a visible defect from a numerical suspicion.
3. The critic reports at most three prioritized findings, exact frame/time
   evidence, the likely cause, uncertainty, and the smallest next experiment.
   Keep observed pixels, computed timing/geometry and inferred motion quality
   separate. Existing source review alone cannot establish visual quality.
4. The implementer addresses the highest evidenced defect, runs the smallest
   relevant checks, then returns the actual new capture to the independent
   critic. Continue authorized local work without waiting for optional external
   sign-in or repeatedly asking Mats to approve routine testing.
5. Preserve the report and checkpoint at meaningful milestones. Keep progress
   replies short. If a genuine dependency blocks all useful work, state it
   plainly; do not claim a sub-agent is an unlimited background worker.

## Honest limits

The current internal critic interface accepts images and tool results. A
timestamped sequence plus timing data supports local motion diagnosis, but is
not evidence that the critic watched continuous video at normal speed. Do not
label it an actual-video review or invent a video score. Static or geometric
passes do not establish 9/10 animation quality. Record any final motion-quality
gap explicitly and keep production acceptance open until supported.

An internal agent cannot bypass third-party sign-in, consent, access controls,
or an automatic approval rejection. No new external upload is authorized by
this workflow change. The rejected Gemini upload is not to be retried without
the concrete authorization required for those two files and that destination.
Continue locally; do not seek another external service as a consent workaround.

## Current evidence and next investigation

Animation source: `005f16dace30747f66e87ef1ca049bffc3aeced8`, tree
`bdb38a970a2adb07ba7bfe31bcdd23a03a303fe2` (study 16G).
Actual capture `native-ingame.json` SHA256:
`e539b5b0308825210e4a2842dda86a70062d6afb1a1075953f013adccf9e56d4`.
There are 119 actual rendered game frames. Both original strikes at 50/90,
inputs, world state and foot placement pass. All 31 changed bank cells are
present; the other 88 character-core samples are unchanged from study 15.

Study16G remains rejected: actual tool-head return clearance is 1.63057153px
at frame 78, below the unchanged 2px requirement. The prior native gate used
study 15 ore rectangles and missed the larger live pulse. Dark, narrow tool-head
readability also needs local sequence inspection. Last actual video review was
study 15 at 3/10; no 16G video score or 9/10 result exists.

Build future clearance constraints from the convex hull of the filtered-alpha
ore contour transformed about its resource root at both scale endpoints,
0.91 and1.035. Preserve the sprite offset (0,-3). This contains all permitted
pulse/recovery sizes and avoids dependence on one recording's wall-clock phase.
Keep original impacts as separate positive controls and retain the 2px margin.
The first local review verified all 119 source frames and inspected 24 ordered,
timestamped crops plus original frame 80. It found that frames 79-82 (simulation
seconds 1.333333-1.383333, phases 0.209524-0.288095) project all 20 evaluated working
surface points into the visible ore contour. The old return guard ended at
phase 0.20 and missed this part of the lift. This is screen-space overlap, not
proof of a 3D collision or an extra gameplay hit. The next correction must cover
the entire return/lift until the real next downswing, not only the old sampled
guard interval or its 1.63px limiting point.

The same review found weak head readability at frames 58/65/73 and a repeated
mine cell at frames 48/49 before the first contact at 50. Treat those as separate
visibility and presentation-cadence investigations. The second contact does not
have the same repeat. These are image observations and computed timing, not
claims of having watched playback.

Frozen local review SHA256:
`0f4124ba6309cfd01296aa0562b26606ba306849910513672af062099a787744`.
Address the whole-return clearance first, then compare the same actual route
with the independent critic. Do not sweep amplitudes or spend another full
render merely to retry the same unmodified hypothesis.
