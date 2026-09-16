# Receiver-mask performance work: paused for new chat

Saved 2026-09-16 at the user's request. **The Deep receiver optimization remains
opt-in, default off. Pixel correctness has passed; a valid performance gain has
not been established. The sustained 50 FPS requirement remains unmet.** No
timing or rendering process was left running by the performance critic.

## Exact current ownership

- New `scripts/lighting/terrain_light_receivers.gd` and its `.uid`: conservative
  native light masks per terrain section, updated before drawing. Full-resolution
  native light texture alpha support, including a filtering guard, defines the
  convex support hull. Unknown textures/materials retain conservative behavior.
  Native artwork, shaders, light colors, PCF shadows and occluders are unchanged.
- `scripts/lighting/lit_draw_sections.gd`: `receiver_masks_enabled = false`,
  controller lifecycle and conservative section-bound metadata. Enable explicitly
  on the Deep world's `lit_draw_sections` only for the candidate measurement.
- `scripts/world/endless_descent_world.gd`: this agent's integration is only
  `lit_draw_sections.begin(self, true)` in `_draw_partitioned_deep`. Other changes
  in that shared file belong to root and must be preserved.
- `scripts/companion/mole_companion.gd`: Hub-only disabling of the two mole
  shadow emitters, because the Hub has no occluders. Native cone/bounce lighting
  is retained. This small fix is active independently of the Deep opt-in flag.
- New `tools/review_terrain_light_receivers.gd` and its `.uid`: exact A/B/A matrix
  and one-stage-per-process mining timing harness.
- Already checkpointed separately: `tools/configure_review_display.swift` and
  `.github/workflows/premium-session.yml`; legal advertised Mac resolution
  selection and actual 1696x780 framebuffer assertions. Keep these fixes.

## Latest valid verification

[Full current-source report](receiver-mask-exact-20260916.json) preserves source
SHA-256 hashes. Original captures and log are at:

`/workspace/scratch/5a78be25fc28/evidence/receiver-mask-exact-final/`

All **20 cases have zero differing RGBA pixels in both A/B and A/A2**. Actual
framebuffer is 1696x780 except the deliberate 1536x864 resize case. Coverage:
initial scene; maximum wide lamp range/energy in eight directions; focused lamp
and first-frame rotation; hit/Crusher/pet mutation; fractional camera; resize;
new and removed nonhelmet light; rebase down/up; Hub empty-shadow comparison.
Godot 4.7.2 exited 0 using llvmpipe. The log has expected unsupported sample audio
and VSync warnings, not script errors. Gameplay/UI and tweens are frozen only in
the pixel fixture. This proves equivalence to the current baseline, not overall
visual approval or physical-device performance.

No new timing was started after the save request. The earlier in-process timing
at `/workspace/scratch/5a78be25fc28/evidence/receiver-mask-final/` is **invalid for
performance comparison**: its three starting terrain hashes differ because
`reset_run(false)` retains excavation. Do not quote its apparent FPS improvement.
The latest harness rejects the former `--benchmark` mode and requires a separate
process/save/output directory for each stage. Its timing-only branch parses but
has not yet been executed. It checks the five report source hashes; that is not
a whole-project source freeze. Preserve all runtime dependencies between stages.

## Resume: one clean A/B/A experiment

Serialize all rendering. Pause other agents' Blender bakes and CPU-heavy checks
before timing; give the save critic its separate short probe first if still needed.
Use new output directories. Re-run the exact matrix if any hashed source changed:

```bash
cd /workspace/scratch/5a78be25fc28/Ever-Deeper
python3 tools/run_rendered_isolated.py \
  --godot /tmp/ever-deeper-runtime-20260915/Godot_v4.7.2-stable_linux.x86_64 \
  --xvfb /workspace/scratch/02374ae65f32/runtime/xvfb/usr/bin/Xvfb \
  --output /workspace/scratch/5a78be25fc28/evidence/receiver-mask-resume-parity \
  --resolution 1696x780 --timeout 240 -- \
  --script tools/review_terrain_light_receivers.gd -- \
  --output=/workspace/scratch/5a78be25fc28/evidence/receiver-mask-resume-parity
```

After that passes, run the following **three times sequentially in new processes**:
use `native` with output `receiver-native-A`, then `receiver` with output
`receiver-candidate-B`, then `native` with output `receiver-native-A2`. Substitute
the output in both places. The saved JSON report can be used directly as the
parity reference if all five source hashes still match.

```bash
python3 tools/run_rendered_isolated.py \
  --godot /tmp/ever-deeper-runtime-20260915/Godot_v4.7.2-stable_linux.x86_64 \
  --xvfb /workspace/scratch/02374ae65f32/runtime/xvfb/usr/bin/Xvfb \
  --output /workspace/scratch/5a78be25fc28/evidence/receiver-native-A \
  --resolution 1696x780 --timeout 120 -- \
  --script tools/review_terrain_light_receivers.gd -- \
  --output=/workspace/scratch/5a78be25fc28/evidence/receiver-native-A \
  --timing-mode=native --seconds=30 \
  --parity-report=/workspace/scratch/5a78be25fc28/Ever-Deeper/docs/premium-polish/receiver-mask-exact-20260916.json
```

If using the newly rerun matrix, update `--parity-report` to its JSON. Require
`reference_verified: true`; compare identical starting terrain hash, player,
depth/window and gear before interpreting FPS. Inspect mined resources, distance,
source stability, actual initial framebuffer and both native controls. Include
receiver CPU overhead and p95, not just GPU time. Timing-only JSON intentionally
does not claim local pixel parity: its reference records that proof. If the gain
is marginal or negative, reject the candidate rather than enabling it globally.

## Evidence and remaining causes

The honest Mac baseline at
`/workspace/scratch/5a78be25fc28/evidence/mac-4da9/` used actual 1696x780 but the
older runtime (832), on Apple Paravirtual/ANGLE, with GPU timing unavailable.
It is not an iPhone proxy. The 300-second sessions all failed sustained 50 FPS:
Hub 35.0–40.5, Ember 40.1–46.2, Deep 17.1–26.6 average FPS across stages.
No orphan or growing-memory trend was found in those sessions.

Deep controlled frozen profiling was roughly 29–32 FPS / 30–32 ms render CPU
median. Disabling shadows yielded 33.69 FPS / 27.56 ms; disabling all lights
yielded **42.48 FPS / 21.86 ms**. Therefore removing light work alone cannot meet
50 FPS on that environment. Render CPU timers can include driver/wait costs;
these values do not by themselves prove a GDScript or draw-submission bottleneck.
`Performance.TIME_PROCESS` in the sustained report likewise is not a clean
per-frame script-only measurement.

Read-only native inventory:
`/workspace/scratch/5a78be25fc28/evidence/light-workload-inventory/inventory.json`.
Deep: four active lights, all shadowed; 13 merged terrain occluders; about 206
draws in the inventory pose. Ember: five active lights, four shadowed; 10 merged
occluders. Hub: four active lights, two formerly shadowed, zero occluders.
Fixed lights were already correctly consolidated; their disabled source nodes
are not extra rendered lights. Cone/bounce lights at one actor share origin but
use different PCF widths, colors and energy, so simply merging them changes art.
Deep occluder refresh is only about 9 microseconds in the Mac profile.

Do not repeat already rejected experiments without new discriminating evidence:
native mass mesh / exact atlas lowered draw counts without reliable total gain;
reduced-resolution albedo caching degraded texture fidelity; the exact-screen
CanvasGroup slowed GPU time by approximately 27–35%. Its rejection report is
`pixel-terrain-group-rejected-20260916.md` plus JSON. All three obsolete group
scripts/shader and all three UID sidecars are removed. Keep the display fix.

Root was preparing a separate native wall candidate in unused helper/harness
files at the save boundary. This agent did not evaluate it. Coordinate its scope
with root's master handoff before doing further rendering or authoring.
