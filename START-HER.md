Current verified recovery: [16 September continuation](docs/premium-polish/RESUME-20260916.md).
Current continuation: [CURRENT-POLISH.md](docs/premium-polish/CURRENT-POLISH.md). Read these before the historical checkpoint below.

# Ever-Deeper — continue premium polish

Checkpoint prepared 15 September 2026 at Mats's request so another chat can continue.
This is a saved work in progress, not final 1.0 approval or a game deployment.

## Authoritative source

Repository: `Corpax88/Ever-Deeper`.
Work branch: `codex/premium-polish-recovery-20260915`.
The complete editable Godot project is at the repository root.

The game-source checkpoint before this documentation/evidence save is
`39f21724deb78c4c6d6103fedb1fba04a2135c32`, tree
`67e69417d18ad29d4862968564a3d60333b99426`. Both were verified directly on GitHub.
It is based on canonical source
`d4619e5429326b880c4da2d466a2bf5351f0f46c`.

Fetch the current work branch and read this file, `AGENTS.md`,
`docs/premium-polish/HANDOFF.md`, `docs/TESTMILJO-HANDOFF.md`,
`docs/code-map.md` and `docs/verification.md` before editing.
If the branch has advanced, reconcile its new handoff and work; do not reset it.
Do not mistake an older source ZIP or the default branch for this work branch.

## Exact preservation limit

The original unpublished premium-polish checkout disappeared. Its local
commits `2b5539413a64f12e3193e147a5960fcdfbc50ea6`,
`277215ecf7688bc6379b627dc51b9ace88344cea` and the later recorded short
`71034d4` are not the saved source.
The complete polished source, new production atlases and raw animation frames
were not recovered. Do not claim those changes are present.

The verified rebuilt source restores a subset: chest/storage removal,
disconnected portable-base and belt removal, seal-target follow-through with
movement cancellation, and draining pending hero texture loads at shutdown.
It keeps the five modern workshops, relic delivery, inventory and trading.
Production hero atlases are the approved canonical v28 baseline.

`docs/premium-polish/recovery/` preserves exact surviving patches, migration
scripts and three historical gameplay movies/reports from the missing candidate.
These are useful recovery inputs, but the patches lack their original base and
must not be applied blindly. That folder's original recovery note is retained.
`docs/premium-polish/INTERRUPTED-WORK-NOTES.md` records implementation findings
from session history. It is a reconstruction guide, not proof of saved code.

## Mats's actual goal and authorization

Carry out a full professional premium polish before 1.0. The world must feel
handcrafted and cohesive. Fix underlying systems when needed. Large refactors,
replacing legacy code and invalidating old saves are authorized. Remove the old
system after replacement; do not maintain parallel old/new implementations
without a real reason.

Priority order:

1. Game feel.
2. Stable FPS.
3. Animation.
4. Visual coherence.
5. Scale and environment.
6. UI.
7. Code cleanup.

Use independent critics on actual gameplay captures. Continue iteration until
the available quota is exhausted or overall quality is at least 9/10. Do not
invent a rating or use a green headless test as visual approval. Mats wants only
brief useful updates, normally at most five lines, with no coding narration.
Finish with the project's normal verified publication/handoff routine once its
acceptance gates are met. This save request does not itself approve a release.

World: mountains need mass, silhouette, height and natural ground transitions.
Shops, forge, assay, portals, hub, mining/relic areas and biome transitions must
read immediately and make sense at hero scale. Fix floating objects,
intersections, hard square seams, repeated tile patterns, weak contact shadows,
depth order and perspective. Integrate existing art with placement, terrain,
lighting, shadows, decals, overlap and foreground/background composition.
Adding unrelated decorative assets is not a substitute.

Animation: fluid responsive idle/walk/mine transitions without snapping.
Use Valheim mining only as a movement reference. Anticipation, whole-body
weight transfer, contact frame, environmental reaction, follow-through and
smooth recovery must work together. Feet, hips, shoulders, hands and the tool
must agree. Pickaxes, drills and special tools need appropriate motion.
Preserve the approved native character model and identity.

Feedback: align damage, sound, particles, resource rewards and restrained
camera feedback to physical impact; communicate weak versus powerful blows.
Do not make prolonged play tiring.

Chest removal: remove gameplay, spawning, UI, loot, events/signals, references
and unused assets. Legitimate relics, mineral caches and current progression
must survive. Complete the audit even though a tested subset is already restored.

Performance: stable minimum 50 FPS, target 60, during sustained real gameplay,
not merely at startup. Test hub, mining, large excavations, shops, pet, lights,
many resources, concurrent effects, UI, transitions and long sessions.
Investigate allocation/GC, redundant ticks, draw calls, dynamic lights,
physics, overdraw, unfreed objects/events, generation, and offscreen rendering.
Improve systems without discarding the visual quality.

UI: coherent premium materials, typography and controls; no overlap or bad
mobile scaling. Swipes follow the finger and release with real momentum/snap.
Remove genuinely unused scripts/assets/tests/UI after checking runtime,
string calls, signals, scene bindings and save ownership.

## What is actually verified

For source `39f2172`, the preserved rebuilt-source report contains 13 passing
cases and one failed layout case. The separate rebuilt-layout report records
the corrected layout passing. This is not a claim that the original 14-case
report was all green. Retain both reports; rerun the current gate after changes.

The invariant check was rerun during preservation and passed:
`INVARIANTS_OK protected_files=1095 qa_cases=56`.

The preceding source-recovery review recorded 31 actual 1696×780 source images
using Godot 4.7.2 and Mesa llvmpipe under authenticated Xvfb, and inspected them.
The report, logs and four existing contact sheets are preserved under
`docs/premium-polish/checkpoint-evidence/`.
The original PNG hashes are in the report; regenerate full-resolution images
from the exact source when required. The contact sheets are review evidence,
not replacement production assets.

Historical worn/Crusher/Deepcore movies are fixed-step 1280×720 captures of the
missing candidate, not this source and not real-time or physical iPhone FPS.
Current exact export, browser, Apple-device performance and final visual
acceptance remain open. No 9/10 or minimum-50-FPS certification exists.

## Approved native sources

Recover these existing saved originals by identity, not by creating a lookalike:

- `Ever-Deeper-hero-dark-eyes-v28.zip`,
  `libfile_5d08f0548e188191b07b18c90a5e8c40`.
  Approved .blend SHA-256:
  `94304c12a042b168c0d655dc0ceacffe2efb08997039a7a26c1ed0cc1770bc91`.
- `Ever-Deeper/Ever-Deeper-dad-v9-native-source.zip`,
  `libfile_2a51e98cb7a48191af9d21ac69c3c495`.
  Native equipment sources for all eleven gear keys.
- The separate material study
  `libfile_453ef852cf30819181e7509690c3dec9` is an unapproved study,
  not authorization to replace production materials.

Keep personal photos and native Blender originals out of the public code
payload. Read `tools/hero_v28/README.md`; preserve native grip, anatomy,
ground anchors, tool identities, outfit masks and atomic export fingerprints.

## Next concrete work

1. Recover this work branch, its root project, evidence and approved native
   originals. Establish a small real rendered playthrough in the restored runtime.
2. Verify the current source gate and independently critique the actual saved
   source before choosing the next fix. The old visual fixes are not present
   merely because session notes describe them.
3. Resume game-feel and performance work first, then fullbody animation,
   environment integration and UI. Use the surviving inputs as reviewed leads.
4. Save each meaningful milestone to a remote work-branch commit and verify
   the remote SHA before starting expensive renders. Save raw frame checkpoints
   durably; a local commit alone is not sufficient.
5. Complete exact-package, sustained GPU/browser and mobile acceptance,
   then the normal project release routine. Do not publish a WIP to satisfy
   this handoff request.
