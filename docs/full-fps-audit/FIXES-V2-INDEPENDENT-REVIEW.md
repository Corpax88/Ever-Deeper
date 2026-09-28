# V2 independent visual and startup review

Accepted within the evidence scope below. I inspected 60 actual PNGs from both Mac workers and found no new hero, material, lighting, asset, or HUD regression in the original/candidate comparisons. This is a visual and behavior-parity acceptance, not a complete FPS fix or physical-iPhone acceptance.

- Source: `21e415af523d497f6ec37706e42694b7f9c5302b`.
- GitHub Actions run: `36413947044`; both workers completed successfully.
- Evidence: `/tmp/ever-deeper-fixes-v2-evidence/fps-fixes-v2-{1,2}`.
- Clean release PCK: 262238744 bytes; SHA256 `be8aa8fc2ff2adf5726b6e8464415b7b6591f621b2c8e2e5b8ce5f69732b8f69`.
- Machine-readable inspection inventory: `/tmp/ever-deeper-fixes-v2-independent.json`.

## Actual image inspection

| Evidence | Images inspected | Finding |
| --- | ---: | --- |
| Native original/candidate, seven poses on each worker | 28 | All four idle directions plus three mining phases preserve the full hero and tool with margins. Helmet, glasses, clothing, backpack, hands, boots and pick remain coherent. No new clipping, disconnected part, missing material or lighting change is visible. |
| Surface and mining, all four comparison stages on each worker | 16 | World, hero, pet and HUD remain consistent between original and candidate. Surface ambient animals appear at different animation positions; these are live captures, not frozen whole-frame equality tests. Mining retains the target, skill notification, pet and progress UI. |
| Hub, depth, Endless, Deepheart and surface transitions, both workers | 10 | Each destination remains rendered with its hero, props and HUD. These are fixture-directed lifecycle captures with forced camera placement. |
| Worker 1 ordinary startup, all six images | 6 | Menu, fresh game, Escape menu, saved-run menu, replacement confirmation and confirmed fresh game are readable and intact. Both ordinary surface captures retain the complete hero/tool and pet inside the frame. |

The 42 recorded frozen-native comparison rows (21 per worker) all have zero changed pixels and zero maximum channel difference. I additionally viewed one original/candidate set for every pose on each worker. The equality applies to those captured poses, not every animation frame or every equipment set.

## Ordinary startup and camera scope

`ordinary/report.json` identifies DEV15.17, the exact source above, `normal_startup: true`, no fixture arguments, and `completed_observation: true`. The six images show the ordinary menu-to-world/save/replace sequence rather than a test-camera scene. Runtime logs identify Godot 4.7.2 and Safari 26.5/WebGL; the event list contains no error event. The ordinary audio telemetry reports an active music node at the requested and received 60 Hz cadence. This is telemetry, not an auditory review.

There are visible camera/background limitations that must not be erased from the conclusion:

- The forced transition camera exposes large gray exterior regions in hub/depth/surface captures. These cannot establish ordinary navigation camera quality.
- The comparative mining images contain the same narrow gray strip at the left in original and candidate. It is not an observed new candidate regression.
- The ordinary fresh-game images also show flat gray background below the cutout cliff at the bottom. Thus **not all gray background can be attributed solely to the QA camera**. No original ordinary-startup image at the same framing was supplied, so this review cannot date that observation or classify it as a new regression. The hero is nevertheless wholly visible; the large lateral exterior seen in forced transition captures is absent.

No claim of perfect camera coverage, every normal world transition, or every viewport size follows from these stills.

## Behavior and code evidence

Both worker reports contain 94 checks, all passing, with no report error. Their real-mining motion replay reports exact original/candidate results, immutable bank/metadata, 11 impacts, two cancels and two retarget events each. Unlike the earlier run's ambiguous retarget evidence, V2 records two distinct target IDs: `endless_d000001_node_001` and `endless_d000001_node_000`. It records 327/209 contour and mining frames, 8/5 transition frames and zero clipped frames. Walking coverage in this replay is explicitly zero; it must not be presented as live walking acceptance.

The reported owned-pose checks cover 680 sample cases, 11 aimed cases and 15 mutation-isolation cases per worker. CPU checks retain exact contact results, exact pet path arrays, and fresh collision results as an obstruction is added then removed between searches. These are bounded fixture gates against QA-only original references; they are not an exhaustive proof of all gameplay behavior.

Before this run I reviewed the volume helper and its fixture. Its cache compares the requested double, the current stored float gain and the current bus before suppressing a redundant music gain setter. It replaces exactly seven music writes; SFX setters are unchanged. No production change was required during that review. V2 reports exact stored gains across 164 fixture rows per worker, including both player slots, direct-edit invalidation and crossfade cases, and reports restoration afterward. The helper fixture does not cover bus-change or playback lifecycle; no auditory acceptance is inferred. The browser trace covers all `AudioParam.value` setters, so zero candidate writes in the steady window alone does not identify individual music nodes or prove sound quality.

The build manifest reports that the clean release modifies task motion, companion, audio director and menu scripts/remaps while preserving 1421 original resources with verified original MD5s. No QA resources are added to that release variant. The manifest explicitly excludes the contact pitch-hoist and FBO cache and preserves depth prepass. Full code/release and FPS acceptance remain the parent review's responsibility; this review does not attribute a speedup to a particular helper.

## Limits of acceptance

Accepted means no new visual regression was found in the 60 inspected captures and the recorded parity/startup gates support the scoped unchanged behavior. The evidence comes from Mac Safari/Apple GPU, with an instrumented comparison pack for the graphical gates and a separate clean ordinary-startup observation on worker 1. It is not physical-iPhone validation, continuous video inspection, audible music validation, a soak test, or exhaustive save/transition/equipment coverage. No new tests or production edits were performed for this review.
