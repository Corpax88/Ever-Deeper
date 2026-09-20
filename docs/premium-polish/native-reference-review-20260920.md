# Native Flow20 reference review — 20 September 2026

Independent source review by `/root/release_critic` of `6deddf4` and the subsequent
working-tree corrections, reread before this note. Reviewed `bake_complete.py`,
`export_flow20_reference.py`, `export_runtime.py`, `constant_donor_probe.py`,
`native_rig.gd`, `tools/review_native_rig.gd`, and the original Flow20 applier.
No engine or new image review was performed; only this review file was edited.
Missing earlier captures remain lost as recorded in
[continuity](continuity-20260920.md).

**No remaining source blocker found for the bounded five-pose comparison.**
This does not approve visual fidelity, motion, runtime cost, DEV, production,
or any numerical quality score. No change to the approved model or action is
requested by this review.

- **Reference poses preserve the released hand.** The exporter calls study20's
  custom applier and records all actual bone matrices, validates the unchanged
  bind and approved atlas identity, and retains native source hashes.
  `set_reference_pose()` applies those poses without `_constrain()`. The new
  `reference_only` guard in `advance()` and non-`poses` harness rejection prevent
  the old solver from reattaching the support hand or applying its `.55` impact
  mapping.
- **Final candidate identity is checked.** The exporter updates `candidate.json`
  after replacing `motion.json`. Rendered configuration requires each expected
  hash to have 64 characters, each required GLB/motion/map file to exist, and its
  hash to match. This also closes the missing-file/missing-hash empty-string
  hole. The harness records the actual direction, action and reference-only
  scope instead of the former right-view description.
- **Lighting uses the correct view.** The renderer now consumes exported native
  light positions/colors and relative energies, normalized to peak 2.8.
  Shadowless omni lights, ambient response and tone mapping remain explicit
  image-comparison questions; code does not establish area-light parity.
- **Bake/resume safeguards are present.** The wrapper requires complete full-scope
  reports, the audited opaque RGB contract and exact PNG hashes. Per-channel
  input receipts bind prepared/probe/exporter hashes, channel, size, samples,
  threads, mode, scope and output contract. Cached data maps load as Non-Color.
  The donor helper retains coordinate-dependent sources and restores the target
  mesh. These safeguards do not establish that a full bake has completed or
  looks right.

Compare exact native cells **0, 12, 17, 21 and 35** against matching 200px Godot
captures. The reference exporter is check-only and does not render native PNGs;
use genuine retained/rendered native counterparts. Inspect silhouette,
face/cloth/metal response, tool placement and the released support hand.
The harness's automatic `passed` flag is an execution result, not visual
acceptance. General bearings, repeated interruptions, gameplay contact and
mobile cost remain outside this five-pose gate.
