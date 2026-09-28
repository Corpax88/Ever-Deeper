# Production CPU fixes — 28 September 2026

Mats authorized concrete code fixes that retain the game. This candidate implements two bounded changes from round 2. It does not change depth prepass, native rig/bone submission, approved hero stance, assets, animation rate, rendering resolution, materials, lighting, save identity, damage, mining timing, path exploration order, or gameplay reach.

## Clean changes

1. **Contact search:** `task_motion.plan_contact` builds the 19 pitch-axis bases once per point/height and reuses them across the nine swivel iterations. The same points, 25 heights, nine swivels, 19 pitches, multiplication order, scores, comparisons and selected contact remain. A maximal uncached search still evaluates 51,300 poses, with pitch basis construction reduced from 51,300 to 5,700. Cold/hot cache and runtime fallback remain unchanged.
2. **Companion navigation:** `mole_companion._path_to` owns a local `collision_results` Dictionary and passes it through private path-only point/segment helpers. Exact repeated Vector2 queries reuse their result only during that synchronous search. There is no node-level cache, toggle, timer, debug counter, or per-frame branch. All returns discard the local dictionary. Ordinary movement, separation, spawning, direct collision and segment methods remain byte-identical; a later search reads fresh world state.

The rejected inverse-rest prototype is excluded completely. The optional pose-copy idea is also excluded: it lacks measured acceptance and is unnecessary for these two bounded fixes.

## Source and PCK contract

Builder API: `.github/fps-fixes/cpu_patch.py`, `transform(text, "contact"|"pet") -> str`. `EXPECTED` carries exact input resource names and SHA256 values. Any mismatch fails before patching.

Baseline PCK: immutable DEV15.16, 262,003,869 bytes, SHA256 `ee5a77d6c0b15d84bb1b44c85f1aa777aeb555293e0ba11747a400d6bc9a4d72`. Verified from `/tmp/ever-deeper-round2-original/index.pck`.

| Kind | Production resource | Original source SHA256 | Patched source SHA256 |
|---|---|---|---|
| Contact | `scripts/player/native_worn/task_motion.gd` | `4946e722a77231c5a47f34bf4af85536ccabbb2e3c0e4f3283b54db154e25f9a` | `164ebff3bc5ca08e081a5f78ecfc5da7419196ce57d78de2ec0e4b073e76c180` |
| Pet | `scripts/companion/mole_companion.gd` | `5c485b1e41ad40fe6c71368c7824b92932bc9a1f0114e732ed1300b9e6d7be73` | `e6bb84284b4361a308ef7cb526f0c7c4ba5449684d6842e24efd50131a82088b` |

Original remaps point to the same path ending `.gdc`. Add each patched `.gd` and update only its `.gd.remap` to point to that source. The original compiled payload can remain unchanged in the PCK.

| Original resource | SHA256 |
|---|---|
| `task_motion.gd.remap` | `b768c773900a6cda757c71b6634ff230b3a2b091615373b3eaf359e1ad210b32` |
| `task_motion.gdc` | `ec2341e53515837a62197ba6a6754ffdb719bf1ba1cffc9cdc952b33c57027e6` |
| `mole_companion.gd.remap` | `ac73e224f4fe5b2f676b549a8ff565d72d014dfbab8fb31d2696482d18572946` |
| `mole_companion.gdc` | `5fe20072148eea2f9f8970bfca594a511f89a1fd71561e11417f0460b81e4067` |

Preserve active `scripts/player/native_worn/runtime_motion.gd`, SHA256 `2f5594057629eb9e15ad5385155da7cecd0aab3a418eb8648a0116eca311f720`. This is DEV15.14's approved stance runtime, not the older repo runtime file. `PRESERVE` makes the builder check explicit.

## Separate QA resources and methods

The clean production package does not include this new test harness. `qa_reference_scripts(contact_text, pet_text, active_runtime)` creates only:

- `scripts/qa/suites/fixes_contact_original.gd`: original task-motion source.
- `scripts/qa/suites/fixes_motion_original.gd`: byte-identical current stance runtime except its base points to the original task source.
- `scripts/qa/suites/fixes_pet_original.gd`: original companion source with only its global `class_name` removed to avoid registering a second global class.

Add `.github/fps-fixes/cpu_fixture.gd` at `scripts/qa/suites/fixes_cpu_fixture.gd`. `.new().run(main)` returns:

- Original versus **actual production candidate** contact output comparison in ABBA order, cold/hot queries, reachable contours, unreachable fallback and empty-contour fallback; active stance banks must match exactly.
- Seven actual surface routes with exact full path-array comparisons and retained empty-path outcomes.
- Same original/candidate companion instances in a controlled world with an obstruction added and removed between searches. Paths must change with obstruction, return to the first path after removal, and ordinary collision queries must observe every change.
- A conservative full-screen framing check for the whole native sprite rectangle, including transparent padding, with an eight-pixel edge margin.

Optional live replay uses one retained fixture instance: `record_start(main)`, `record_frame(main, delta)` per QA frame, and `record_finish()`. It copies current motion state into original/candidate models whose rig sinks are inert; no live rig or visual is modified. Both receive the actual animation packets and contour/impact surface information. Every accepted pose and motion snapshot must be exactly equal. Returned coverage counts include mining/contour frames, new swings, impacts, retargets, cancels and clipped frames. Keep this recording outside FPS windows because doing two extra motion evaluations is intentional QA work.

**Coverage requirement:** ordinary Moss mining has no `resource_visuals` contours and exercises the cheap fallback, not the optimized exhaustive search. Retain the Moss damage/input gate, but use an Endless resource with real `resource_visuals` for the contact-search gate. Require `contour_frames > 0`, actual impacts, at least one retarget/cancel, zero clipped frames, and exact replay outputs. Full-frame screenshots must include the hero/tool, correcting round 2's cropped-right-edge limitation.

## Evidence and disposition

Earlier diagnostic helper evidence: contact totals 163→146 ms and 101→83 ms across six cold calls/mode, with one retained slower case; forced companion searches reduced collision evaluations 760→616 and total helper time 17→13 ms /13→11 ms. These are local helper gains, not proof of persistent overworld FPS improvement.

The clean transformations pass input hash guards, Python syntax validation, and structural checks that ordinary collision/segment methods remain byte-identical and that no QA flags/timers enter production. Full combined Mac execution, baseline-versus-candidate image comparison, lifecycle/real-input coverage and production-package checks belong to the parent's new fixes workflow. Do not reuse round 2's diagnostic pass as clean-production acceptance. No physical-iPhone or stable-60-FPS claim, and no publication in this subtask.
