# Rejected native receiver experiment

This isolated renderer snapshot is excluded by both export presets. Production
does not instantiate a receiver controller or maintain receiver bounds. The
normal bounded CanvasItems, shaders, draw order and native lighting remain.

`tools/review_terrain_light_receivers.gd` explicitly substitutes this owner when
revisiting the experiment. Its baseline/candidate modes share that snapshot;
these tools are not a second production renderer. Do not enable the experiment
based on GPU time alone or silently resynchronize this historical snapshot.

Both versions preserve exact pixels in the 20-case A/B/A matrix. Neither
improves total frame time in three fresh, identically seeded native processes:

| Version | A / candidate / A2 FPS | Candidate CPU/frame |
| --- | --- | --- |
| Original | 36.344 / 36.345 / 37.429 | 1.562ms |
| Conservative support cache | 37.592 / 36.703 / 38.163 | 0.857ms |

The latter expands light support by 24px and reuses it while the affine
displacement of all bounding corners remains inside that margin. It reduces
CPU work but keeps more receivers lit. Even its lower cost consumes its GPU
saving. Both measurements use Godot 4.7.2, Mesa llvmpipe, real 1696×780 frames,
held movement/mining and 30-second samples; neither certifies a physical device.

The complete parity, timing, exact source hashes and original code delta are in
`docs/premium-polish/resume-20260916/`. Do not repeat this direction without a
specific new reason to expect a net improvement.
