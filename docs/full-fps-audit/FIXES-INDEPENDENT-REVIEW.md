# Independent evidence review — FPS fixes

Reviewed on 28 September 2026. Run **36410803352**, source **6834643708348ceb6002287325a6e01d4fe8cccd**. Both Mac workers completed 143 checks with no failed checks and no report error. This review accepts the observed CPU output parity and sampled rendering. It does **not** accept the contact change as a demonstrated speed improvement or establish release, ordinary-camera, audio-quality, or physical-iPhone acceptance.

The reviewer implemented the CPU transforms, then independently inspected the parent harness and its resulting evidence. This is independent evidence inspection, not an unrelated author's second code review. The root agent owns aggregate FPS assessment, other implementation reviews, ordinary startup and release decisions.

## Identity and scope

Evidence: `/tmp/ever-deeper-fixes-evidence/fps-fixes-1/` and `fps-fixes-2/`, each with `report.json`, `build.json`, console logs and actual PNGs. Runtime reports Apple GPU / AppleWebKit 605.1.15, Safari-version UA 26.5, DPR 3, canvas 2328 × 1260; harness viewport 776 × 420. This is automated Mac WebKit, not physical iPhone Safari.

| PCK | SHA256 |
|---|---|
| Original DEV15.16 | `ee5a77d6c0b15d84bb1b44c85f1aa777aeb555293e0ba11747a400d6bc9a4d72` |
| Original plus QA | `aa0194927ee9e6f4e36d1eae2c9409b08f6522b96fd47631f4c80c57751cd733` |
| Candidate plus QA | `f74c8f96db89277a4ef9a6b0dc4d4af0830a5dca55527280a79731cffde135ac` |
| Clean candidate built in this run | `9d6851067ce28b3bb22842c13cb47081dc28c72431ca8705de6c97e8cb32a6bf` |

The last PCK was built without the new QA resources. The browser images reviewed here are from the QA variants; they do not themselves show ordinary clean startup. Build manifests verify the original payload MD5 values and retain 1,423 original resources in the clean candidate. Native assets, the approved stance runtime and depth prepass remain unchanged. The contact and pet active remaps deliberately move from original compiled scripts to the production source transforms; source/remap identities are recorded in [FIXES-CPU.md](FIXES-CPU.md).

The reviewed local `cpu_patch.py`, `cpu_fixture.gd` and `review.mjs` match the exact tested commit byte for byte. The subsequently prepared distinct-resource version of `_fix_endless_target` does **not** belong to this run; its local presence must not be described as tested evidence.

## CPU disposition

| Measurement | Worker 1 | Worker 2 | Disposition |
|---|---:|---:|---|
| Cold contact search, summed original → production | 99 → 105 ms | 94 → 100 ms | Measured cost +6.06% / +6.38%; no confirmed gain |
| Contact bank, selected output, cache and fallback parity | Exact | Exact | Accepted for the tested reachable, unreachable and empty-contour cases |
| Surface pet path search, summed original → production | 13 → 11 ms | 14 → 11 ms | Helpful local result, −15.38% / −21.43%; small, coarse totals |
| Full pet path arrays | Exact | Exact | Accepted in all seven cases, including empty outcomes |

The contact helper benchmark compares source-backed original and actual production implementations in ABBA order, outside the frame-rate measurement windows. It preserves immediate repeated-query output as well as cold-query output. It does not measure the compiled original's helper time. Durations are quantized to whole milliseconds in the recorded results; 0 ms is below the available measurement resolution, not zero work. Only two cold samples per implementation/case were retained. The older diagnostic contact improvement did not repeat in these production runs. **Recommendation: omit the contact hoist from a performance release unless a separate justified benefit is established; do not advertise the older 10–18% gain as current.** No additional broad rerun is requested by this review.

The pet change has a narrower, repeatable workload reduction. In both workers, the same instances see an obstacle absent, present, then absent again. Exact original/candidate paths have 6, 8 and 6 points. Collision queries fall 160 → 128, 254 → 201, then 160 → 128, or 574 → 457 in total (20.38% fewer). Paths change on obstruction and restore after removal. Ordinary collision calls see the fresh obstacle state at every step. The dictionary lives only inside one synchronous `_path_to()` call; original movement/separation collision methods remain unchanged. This supports retaining the pet cache as bounded CPU cleanup, without claiming it explains sustained surface FPS.

Of the seven actual surface cases, three produce nonempty paths (6, 6 and 9 points); four produce empty paths in both implementations. They are parity cases, not seven successful traversals. The controlled obstruction case supplies nonempty replan coverage separately.

## Real packet replay and retarget coverage

The harness enters Endless with a durable resource target, records while Space is held for 4 seconds, invokes the original right-side placement helper on the same owner, records another 3 seconds, then releases Space for 0.5 seconds. The CPU replay reads actual controller packets and actual contour/impact inputs. Original and production motion models use inert rig sinks and compare every accepted pose and motion snapshot; they do not overwrite the visible rig.

| Recorded fact | Worker 1 | Worker 2 |
|---|---:|---:|
| Compared frames | 292 | 385 |
| Mining / contour frames | 265 / 265 | 346 / 346 |
| New swings / impacts | 11 / 11 | 11 / 11 |
| Counted target changes / cancels | 2 / 2 | 2 / 2 |
| Clipped frames / parity failures | 0 / 0 | 0 / 0 |

The exact counter predicate is **changed swing serial AND (changed target ID OR changed target position)**. It does not save IDs, positions or per-event timestamps. Initial target acquisition may count. Therefore the retained JSON establishes two events meeting that predicate; it does **not** establish that two different resource IDs were struck, identify which event followed `fixes_retarget`, or distinguish a same-resource contact-point change. The original `_place_endless()` searches from the first eligible resource independently for each direction and does not require a distinct resource. Do not claim distinct-resource retarget acceptance from this run. The original gate did pass; the previously anticipated zero-retarget failure did not occur.

Replay equality is between two motion models fed the real packets. It is not a direct assertion that the live rendered owner pose equals the original model on every frame. The seven frozen native samples separately exercise the unchanged rig through `sample()` / `rotate_pose()`; they are not seven aimed contact snapshots. Moss mining windows separately require actual health loss and at least three impacts per window, but do not exercise the contour search. These evidence types should remain distinct.

## Actual visual inspection

**60 PNGs were opened and visually inspected**, including both workers: 14 candidate native samples, eight original native samples, all 16 full-game comparison captures, all 12 frozen same-scene captures and all ten transition captures. The complete absolute-path inventory is in `/tmp/ever-deeper-fixes-independent.json`.

- Four native directions and three mining phases show the full hero and tool inside the 400 × 400 viewport. Helmet, glasses, coat, backpack, boots, hand/tool connection and approved materials remain coherent. No missing limb, detached tool or new crop is visible. The report also verifies nontransparent used bounds stay strictly inside the viewport.
- The native comparisons retain 21 exact pairs per worker: seven poses compared with three subsequent stages, including one within-mode comparison. All have zero changed channels and maximum difference 0. These are sampled rendered poses, not full continuous-animation acceptance.
- The frozen surface/mining triples show identical lighting, terrain, UI and character output when FBO/audio fixes are enabled and then restored. There are four exact comparisons per worker (candidate and restoration in each scene). The full-game production baseline/candidate captures are independently timed and have normal ambient actor/animation differences; no full-frame equality claim is made for those independent scenes.
- All transition captures retain visible native hero, companion, world and HUD. The Endless and Deepheart captures retain the blue cave environment, props and effects. No disappearing actor, missing texture or new visual regression is apparent.
- **Camera limitation:** the QA `_fix_center()` removes camera bounds and smoothing to keep the hero in frame. Hub, depth and surface transition images consequently expose gray outside-world margins, particularly the right side of the depth scene. Moss mining comparisons show a left gray strip in both original and candidate. These captures support lifecycle and actor fidelity, not ordinary camera composition. The separate clean startup review remains necessary for that scope.
- The surface fixture places the companion in front of the hero in several whole-game captures. Both original and candidate show the same overlap; the separate native captures supply unobstructed hero inspection. Do not describe the surface images alone as complete unobstructed hero review.

## Remaining limits and recommendation

No production file was changed during this evidence review. No new runtime tests, publication or prepass experiment were launched. CPU correctness and sampled rendering are accepted within the limits above. Retain the pet search cache as the supported CPU candidate; reject the contact helper speed claim. Overall package performance, FBO implementation safety, audio fidelity, ordinary startup/save behavior and publication remain the root review's responsibility. Physical-iPhone FPS, heat and long-session smoothness remain unverified.
