# Ever-Deeper premium polish — saved for a new chat

Mats explicitly requested **“Lagre prosjektet slik at ny chat kan overta”**.
All agents stopped at safe authoring boundaries. This is a complete WIP source
checkpoint and continuation record, **not 1.0 approval, 9/10 approval, or deployment**.
Production hero atlases remain the approved v28 assets. Stable 50 FPS is not met.

## Recover the right project

- Repository: `Corpax88/Ever-Deeper`.
- Work branch: `codex/premium-polish-recovery-20260915`.
- The commit containing this handoff preserves the entire current editable root Godot project.
  Read the branch's actual latest head before editing; do not reset to an older pointer.
- The preceding source/tool checkpoints were `8328622` (last complete 15-case gate),
  `6e3e4fa` (native motion authoring), `4da9f80` (actual Mac framebuffer checks),
  `9fed86f` (native pilot exporter), and `1b11e0f` (native rig review scaffold).
- Current local checkout: `/workspace/scratch/5a78be25fc28/Ever-Deeper`.
  Scratch may disappear. Git and the saved review/native archives are authoritative.
- Leave the older dirty checkout `/workspace/scratch/02374ae65f32/Ever-Deeper` intact.
- Read `AGENTS.md`, this file, the four critic handoffs below, `docs/code-map.md`,
  `docs/verification.md`, and the game-test-environment skill before resuming.

The earlier `START-HER.md` body, `RESUME-20260916.md` and `CURRENT-POLISH.md`
contain historical milestones. They do not supersede this save.

## User's standing mandate

Full professional premium polish, with permission for substantial refactoring,
replacing bad systems, deleting dead legacy code and invalidating old saves.
Priority: game feel, sustained FPS, animation, visual cohesion, scale/environment,
UI, cleanup. Use independent critics and real gameplay captures, and continue
until actual quota exhaustion or overall 9/10. Never invent either stopping condition.
Only short useful progress updates; do not narrate coding. Preserve the approved
native character/art, and meet the visual and gameplay gates before the normal
verified publication routine. This save request pauses that work for transfer.

## What changed in this checkpoint

| Area | Saved work | Acceptance limit |
| --- | --- | --- |
| Hub | New coherent native floor, correctly scaled mapping, smaller objective detail card, opaque physical workshop/museum worksites in place of ghosts | Actual hub/relic captures inspected; no whole-game approval |
| Relic hauling | Fixed-step tension-only rope, eight constraint passes, physical pedestal placement tolerance | Actual controller/context/rope journey passes all 18 checks |
| Deep grounding | Resource/site footprints, clear seal activity areas, feet-based actor/resource/relic draw order including rebasing | Relic journey shows the previous hero-on-ore fault removed |
| Deep geology | Curved generated corridors and native-density floor blending at all five geological boundaries | Floors improve; wall projection/corners remain a major visual defect |
| Native seals | Full engraved native plates and inlay-only glow; stone stays opaque and fixed in scale | At 88×59 the plates still read too much like gravel; 112×75 is a proposal, not implemented |
| Surface | Full native shelves, mouths and resources on real floor, opaque mountain stages, actor/rock depth and footprints | 36-frame floor set passes; final movement/route fixes still need actual rendering |
| Player timing | Distance-driven gait, declared sample phase/contact handling, movement immediately cancels post-mining hold | Impact/Deepheart gameplay capture passes; full new animation system is not in production |
| Saves | One version-3 binary disk codec, checksums, verified atomic replacement and retained backup, canonical terrain state | 341 focused assertions pass; latest broad QA fixture changes remain unrun |
| Lighting | Active Hub empty-shadow removal; conservative Deep light receiver candidate | All 20 A/B/A pixel cases exact; candidate is **default off**, valid cost comparison pending |
| Cleanup | Obsolete barrier migration and reverse scan removed; rejected runtime rendering experiments removed | No claim that all remaining dead code has been audited |

The old chest gameplay was removed in the preceding saved work. The current search
finds no active chest system. Legitimate mineral caches and the Echo Coffer relic
are intentional gameplay, not the discarded chest mechanic. Native anatomical
comments using “chest” are not gameplay references.

## Exact evidence and open gates

- Fresh complete Godot editor import after the freeze: exit 0, no script/parse errors.
  `evidence/handoff-import-20260916.log` is in the performance review archive.
- `relic-grounding-v4`: all 18 actual movement, discovery seals, attachment, hauling,
  Tunnel Home and physical placement checks pass. No forced rope endpoint or
  direct relic award. Root and world critic inspected the actual 1696×780 images.
- `mining-contact-polish-v5`: actual presented impact frames, input turn,
  Deepheart station approaches, final follow-through, full machine framing,
  orientation recovery and return to play pass.
- `surface-all-native`: 36 images, 23/23 checks, all eight local contexts and 144 drops.
- `surface-contact-v1`: 52 images, **26/29**, overall false. Three new long-travel
  tests failed. Final tangent sliding, physical support shapes and route fixture
  fixes were written afterwards; they import, but have not been rendered/tested.
- Version-3 binary persistence gate: 341 assertions. Final clean timing probe was
  canceled for this save. Earlier JSON cost ~23–26ms at 1,000 bands; valid pilot
  binary samples ~9–11ms; latest ~12ms sample overlapped Blender and is not an
  isolated comparison. Normal small saves were around 1ms in the pilot.
- Final receiver matrix: 20 A/B and A/A2 pairs differ by **zero RGBA pixels**.
  The in-process timing attempt is invalid because it reused excavated state.
  Do not quote its 38.24/38.75/39.72 FPS as an optimization gain.
- `tools/check_invariants.py` currently fails only the protected
  `scripts/player/player_visual.gd` hash. This is an intentional changed owner,
  left pending complete visual review; do not blindly refresh all protected hashes.
- The full current 15-case source suite, exported package/browser gate, all tools,
  all biome gameplay and long physical-device performance have **not** passed
  for this new source. Earlier green reports apply only to their stated sources.

### Honest sustained performance

GitHub workflow `35055690783`, source `4da9f80`, used the older runtime from 832,
with a verified **1696×780 actual framebuffer** on Apple Paravirtual/ANGLE.
All three 300-second sessions functioned but failed the sustained 50 FPS goal:

| Area | 30-second average-FPS range |
| --- | ---: |
| Hub | 35.0–40.5 |
| Ember | 40.1–46.2 |
| Deep | 17.1–26.6 |

No orphan/growing-memory trend was found. These are virtual Mac measurements,
not iPhone measurements. GPU timestamps were unavailable. The earlier workflow
35051075873 silently rendered 1024×656 and must not be described as target-size
evidence. The new Swift display helper selects a legal advertised display mode;
retain actual framebuffer assertions. Deep still measured 42.48 FPS with all
lights disabled in the new controlled profile, so light masks alone cannot meet
the target on that virtual device. Render CPU times can include driver waits.

## Critic handoffs and concrete next actions

1. [Surface](surface-HANDOFF-20260916.md): run its final full 54-image candidate
   matrix first to expose any real collision/travel regression, then the Overhaul
   case. Reconcile stale layout arch assertions with the actual native split arch.
2. [Persistence](save-schema-three/HANDOFF-20260916.md): finish the isolated short
   save measurement and rerun updated Endless/Overhaul coverage. Preserve the
   legitimate active achievement epoch helper. Old saves are intentionally invalid.
3. [Performance](receiver-mask-HANDOFF-20260916.md): three **fresh** isolated
   30-second native/candidate/native processes with identical initial terrain,
   no Blender/QA contention. Enable the receiver candidate only if its total
   cost is beneficial. A ~1.5ms controller estimate makes net gain uncertain.
4. [Native animation](native-runtime-HANDOFF-20260916.md): retain approved v28
   identity; finish the bounded native rig pilot before considering a broad switch.
   It is not an accepted production replacement. Resume only from saved originals
   and the private derived scene, not a lookalike or procedural character.
5. Deep wall mapping: `tools/wall_pilot/native_wall_mapper.gd` is a newly authored,
   **unused, unrendered** native-art mapping study. It is not wired into gameplay.
   The existing renderer rotates horizontal strips 90 degrees, turning boulders
   sideways, and maps wildly different corner alpha extents to the same 192px
   square. The pilot uses each corner's genuinely upright leg and calibrated
   uniform native scale. It still needs a comparison harness, real terrain/corner
   images and critique; do not promote it just because import passed.
6. Improve seal readability, remaining material joins/UI momentum/animation,
   then all current source, invariant, exported mobile and sustained gameplay
   gates. Do not deploy this WIP checkpoint or claim overall 9/10.

Rejected attempts are documented in `native-mass-rejected-20260916.md` and
`pixel-terrain-group-rejected-20260916.md`. CanvasGroup reduced draws but cost
27–35% more GPU time; native mass/atlas draw reductions did not establish a
reliable total gain; low-resolution albedo harmed fidelity. No such failed
replacement remains in production. Do not repeat them without new evidence.

## Native animation state

124 genuine native Worn/Deepcore pilot frames exist, plus numeric contact/grip
reports and actual hub cadence comparisons. 340px/s with an 88px stride was
rejected as hurried/light (7.73 footfalls/sec, ~47ms support). The 260 comparison
retimes those frames; it is not a newly authored 260 gait and is not approved.
Production movement speed and v28 atlases remain unchanged.

Finite pre-rendered transition banks did not solve arbitrary repeated interruption
cleanly. A bounded **native-source** runtime pilot therefore derives actual source
meshes/rig/materials, not proxy geometry. Prepared geometry is 318,150 triangles,
above the nominal 120k because disconnected native facial/hair strands survive
collapse. Materials are not yet baked. The first albedo bake was interrupted
for this save before any completed PNG. The intact derived `prepared.blend`
and exact pose data are preserved; restart the bake from that file.

Earlier runtime pose stress tests exposed planted-foot/reach failures under rapid
repeated interruption. The final narrow 40-transition probe has zero reach excess,
but needs 0.039441 native pelvis correction at 260 against its 0.035 limit. The
saved solver remains a work checkpoint. Five
native-pose fidelity captures, real controller interruption review and real-time
A/B/A cost remain mandatory before wider export or a production swap.

## Durable non-repository files

Three archive names are unique and searchable in ChatGPT files. Restore them
under one fresh workspace; their internal relative paths recreate the original
native/evidence directories. Each has an internal file SHA-256 manifest.
Archive size/hash inventory is `checkpoint-archives-20260916.json` beside this
file; a follow-up save receipt records their confirmed persistent identities.

- `Ever-Deeper-native-polish-checkpoint-20260916.tar.gz`: prepared native scene,
  real frame pilots, packed candidates, movies, pose/contact reports, runtime
  source inventory and cadence evidence. No duplicate source Git checkout.
- `Ever-Deeper-world-review-20260916.tar.gz`: full-resolution latest Hub,
  relic, mining-contact, all native floor boundaries and surface matrices.
- `Ever-Deeper-performance-review-20260916.tar.gz`: final exact light matrix,
  save/source logs, light inventory, import log and all three original Mac4da9
  artifact ZIPs. The ZIPs retain the complete native workflow evidence after
  GitHub's 30-day artifact expiry.

Original native sources already persist separately:
`Ever-Deeper-hero-dark-eyes-v28.zip` = `libfile_5d08f0548e188191b07b18c90a5e8c40`;
`Ever-Deeper-dad-v9-native-source.zip` = `libfile_2a51e98cb7a48191af9d21ac69c3c495`.
Original v28 SHA-256 is
`94304c12a042b168c0d655dc0ceacffe2efb08997039a7a26c1ed0cc1770bc91`.
Do not upload personal photos or native Blender originals to the public repo.

## Runtime restoration and execution

The game-test-environment skill and `docs/TESTMILJO-HANDOFF.md` own restoration.
Known working binaries while this workspace survives:

- Godot: `/tmp/ever-deeper-runtime-20260915/Godot_v4.7.2-stable_linux.x86_64`
- Blender: `/tmp/ever-deeper-runtime-20260915/blender-4.5.3-linux-x64/blender`
- Xvfb: `/workspace/scratch/02374ae65f32/runtime/xvfb/usr/bin/Xvfb`

Serialize graphical Godot runs. The wrapper `tools/run_rendered_isolated.py`
owns a private Xauthority, display, saves and logs and fails on runtime errors,
even when Godot exits zero. Do not weaken it. Avoid heavy CPU jobs during timing.
Single-script `--check-only` can falsely report missing RunState because it does
not initialize autoloads; use whole-project import or real suites.

Git CLI push has no write credential here. The connected GitHub git-data tools
successfully save to the existing work branch. Build an exact Git tree, verify
it equals the local committed tree, create the commit and fast-forward the ref.
API commit metadata may produce a different commit SHA with the identical tree.
Retain local checkpoint branches, fetch, then only soft-align identical trees.
Never hard-reset the dirty original workspace. Saving source does not publish
the game. LIVE remains 0.46.9; no new DEV/LIVE game was deployed in this work.
