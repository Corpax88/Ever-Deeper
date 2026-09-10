# Verification

## Current source gate

GitHub Actions runs `Godot source checks` for source pull requests and changes on main.
It imports the event's tested commit, checks protected files and runs the fourteen current cases;
logs are attached even when a check fails. The larger `Verify complete source cleanup`
workflow is a one-time baseline comparison, separate from this reusable source gate.

`python3 tools/qa.py --godot /path/to/Godot` runs input release, the 869-check gameplay
suite, shop touch/state tests, endgame, onboarding, iPhone layout, orientation,
developer tools, Crusher integration, the four 1.0 state/world/migration/UI cases
and 50 automatic-companion behavior checks in `mole-autonomy`.
The 1.0 journey checks actual held mining through streamed terrain, all five generated
relics, physical delivery and paid construction, save recovery and continued mining.
Native/headless checks do not validate rendered art or physical device performance.

Run a subset with `--cases input overhaul touch`. Logs and machine-readable results are
written to `qa-results/`. Each case has a timeout and a separate save directory. A success
message alone does not pass: the process must also exit successfully without script errors.

The export-only flavor check must run against an exported PCK, where production resource
exclusions exist: `--pack builds/live/index.pck --cases build-flavor`. Running that check
against editable source correctly finds the developer-menu resource and is not a valid
production-flavor test.

## Pre-existing failing checks

The cleanup was compared with the immutable v0.46.8 source baseline. The following old
checks fail in both versions and retain their original assertions. They are not counted
as passing gates or silently skipped inside a test. Run them explicitly with `--cases`.

| Case | Existing failure |
|---|---|
| `commerce` | Old interaction snapshot asserts `touch_targets_valid` for the revised shop layout |
| `landscape` | Old portal seam expects a 24×184 sprite before the approved surface replacement |
| `smoke` | Old Emberdeep mountain context assertion; further old mining expectations also differ |
| `workshops` | Old WorkshopPanel preview flow predates the shared CommercePanel workshop flow |
| `endless` | Historical room/lift contract intentionally superseded by 1.0 continuous-world and migration suites; original assertions remain available |

`--all --pack ...` includes all registered cases and remains red until those older
expectations are reconciled in a dedicated test update. The current gameplay/touch suites
exercise the corresponding active paths. These failures are recorded as remaining test debt.

## 1.0 candidate acceptance

`.github/workflows/one-point-zero.yml` runs the fourteen active cases against source
and the exact DEV PCK, verifies both export flavors, and checks hero motion, audio
playback and mobile WebKit touch. `tools/review_one_point_zero.gd` captures the same
PCK at mobile resolution for independent inspection. The protected version and mine
button changes are explicitly recorded in `one-point-zero/protected-changes.json`.
Review rounds and remaining acceptance limits live in `one-point-zero/`.

DEV test readiness is separate from final 1.0 approval. The latter requires a
critic rating of at least 9/10, zero critical bugs and sustained smooth physical
iPhone evidence. The DEV publisher accepts only immutable reviewed artifact bytes
and preserves all nine existing LIVE files. It cannot publish a new LIVE build.

## Refactor invariants

`python3 tools/check_invariants.py` verifies hashes of every protected art/audio/import
setting, scene, game-data file, player/light implementation and the project configuration.
Shaders and their resource identities are also protected. These hashes establish parity for
this structural cleanup; update them only alongside an intentional, reviewed game change.
It also checks that every QA entry resolves to a real method, and validates the fixed
mine ordering/mapping owner. Save serialization and migration functions are unchanged.

Removed helpers were private, disconnected render/presentation implementations. Full-token
references, scene bindings, string calls and engine callback names were checked before
removal. Public/debug APIs and active fallbacks were retained. See the removal inventory.

## Browser capture command

After exporting with the commands in README.md, install the browser dependency with
`npm ci` and `npx playwright install webkit`, then run:

```sh
TOUCH_BROWSER=webkit SMALL_IPHONE=1 CAPTURE_SCOPE=light CAPTURE_END=10 node tools/capture-web.mjs --web-dir builds/live --output-dir qa-results/mobile
```

Omit `CAPTURE_SCOPE=light` to use the full capture matrix, and select a numeric range with
`CAPTURE_START` / `CAPTURE_END` (1–303). Unknown command-line flags fail explicitly.
The runner works with the ordinary Godot export shell. It injects a hidden stale-version
badge as a test fixture; `main._validate_release_version()` supplies the running version
and synchronizes it. No release-stamping step is required. `EXPECTED_VERSION` optionally
asserts an exact expected version; otherwise the badge must agree with the running game.

## Visual gate

Export both flavors with matching Godot templates. Capture the same states from the
baseline and candidate at the same viewport/seed, and inspect them before any deployment.
Compare production resources and game-data hashes as well as gameplay results. No art or
layout changes are intended. Source review and a passing headless suite cannot replace
this visual gate from `AGENTS.md`.

## FPS and frame times

See [mobile performance](performance.md). The rendered benchmark is separate from
the headless source suite and does not certify physical iPhone performance.
Use DEV TOOLS → SHOW FPS to measure the actual device while playing.

The v0.46.9 protected-file manifest differs from the cleanup baseline only in
`project.godot`: the release version changes from 0.46.8 to 0.46.9. Its rendering,
viewport, FPS ceiling, save identity and other settings are unchanged.

## Intentional DEV6 lighting optimization

The headlamp protected hash is updated alongside the reviewed, lossless crop of its
transparent texture bounds. The gameplay check now tests the unchanged light-node
position (`shadow_origin_preserved`), while `origin_centered` keeps its old diagnostic
meaning (zero texture offset). Light energy, color, range, occlusion and five styles
are retained. No other protected-file baseline changes. See the lighting-cost report.

## DEV7 floor composition

The existing protected-file baselines remain unchanged. The new floor shader shares
lighting across the original textured floor and translucent color wash. The old
two-pass path remains a QA reference. This is not a bit-identical change: separate
framebuffer clipping and rounding can differ in isolated bright highlights. Inspect
paired output, including maximum-range light styles, before accepting a package.

The final package workflow includes the visible/struck gate harness using the same
artifact; a separate supplemental run is no longer needed. Source and production
flavor checks, native image review and two full DPR3 browser tests remain required.

## Intentional Gruvepappa v28 replacement

The 99 protected hero files (88 atlases and eleven manifests) are intentionally
updated to the approved native v28 model. Cell size, equipment IDs, frame timing,
shader and outfit behavior are preserved. Four projected floor anchors correct an
old preceding-camera sample; native grip and bone targets are validated at export.
The hero workflow checks all eleven tools, four directions, idle/blink/walk/impact,
all outfits, worlds and relevant environmental states in the exact exported package.
Real motion must also produce damage with worn, Crusher and Deepcore tools in all
four directions. Inspect the captured package before setting the release review flags.
