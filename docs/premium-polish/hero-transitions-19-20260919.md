# Hero19C — connected entry, release and bounded walk exit

Continues saved18B at7ad27afb9d1ebff6c93c7bbcd427bb40a6a04aed on
`codex/hero-loop-flow-20260918`. Original Gruvepappa v28 and gameplay remain;
FPS is paused. Study source and commands:
[transition_19](../../tools/native_motion_ingame_pilot/studies/transition_19/README.md).
Exact attempts, failures and verdicts: [REVIEW.md](../../tools/native_motion_ingame_pilot/studies/transition_19/REVIEW.md).

## Result

The actual18B transition test exposed a large facing swap: idle/walk and mining
used different native heading/camera conventions. The independent critic
recommended a common facing before adding transition frames. The isolated
consumer now uses18B's existing ready pose before/after mining. Pre-hit release
retraces shown preparation; post-hit release completes withdrawal. New input
continues onto the authoritative gameplay clock without another false hit.

The walk experiment adds13genuine native full-body frames: exact shown cell31
to down walking over.20s, with ongoing distance-driven legs and the preserved
legacy walking endpoint. No production atlas is replaced. A rapid post-hit
restart initially caused a49→5frame body step; one diagnosed timing correction
finishes withdrawal before easing into preparation, reusing the original bank.

The critic passes stationary handoffs, this exact walk exit and the final rapid
restart as ordered-frame evidence. The final62→63body step is absent;64→69
develops progressively; actual contact76 remains readable. No further change
is indicated by these inspected sequences. This is not continuous-video viewing,
a numerical9/10score or production approval.

## Verified evidence

- Blender4.5.3, approved original .blend/tool SHA guards intact.61native bridge
  checks, maximum reach.5500407355<.70, hand-target errors below1e-5;13renders.
  Source cell31matches18B with identical alpha and very small RGB sampling noise.
- Final110-frame Godot4.7.2/X11 run,1696×780 at fixed60Hz: runner0, completion
  marker intact and startup source hashes match final source. All110 gameplay
  rows equal the preceding rapid case; hits47/76 produce8damage. No hit from
  the first interrupted swing; no unsupported walking request in this case.
- Stationary180-frame run exactly matches baseline mechanical rows. The first
  walking capture has180images and matching mechanics but runner4 because its
  log was empty. Keep that failure; later closed110-frame runs independently
  validate the same bridge, including the final source.
- Five rendered selection checks retain ordinary sprites for Worn/right,
  expedition outfit, Crusher/up and Deepcore/up. Only Worn/up/base green uses
  the candidate. This verifies safe fallback, not new gear/direction coverage.
- Input QA passes. Known protected `player_visual.gd` invariant mismatch remains;
  the file and production hero assets are unchanged. No iPhone/FPS claim.

## Next work and release limits

The walking bank covers only exact cell31→down with first stride phase0.
Do not guess the nearest transition for other phases. The new ready stance is
currently static. General walk↔mine, walking interruption, other source cells,
all headings, tools/outfits, idle blink/breathing and strict foot locking need
coverage before DEV adoption. Confirm normal-speed overall flow as part of final
acceptance. No LIVE or DEV publication occurred.

Deliverables: `Ever-Deeper-overganger-19.mp4` and `.gif` show the final110actual
frames at normal timing; GIF samples30Hz. `Ever-Deeper-overganger-19-bevis.zip`
retains reports, hashes, original crops/selected full frames and the13native
bridge images/atlas. `Ever-Deeper-Fortsett-her.md` contains the saved revision
and continuation instructions. Study18B's source/loop are preserved.
