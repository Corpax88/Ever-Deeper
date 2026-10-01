# Bore Rush flow and continuous laser aim — DEV15.45

User phone recording on 1 October 2026 exposed repeated held-Mine stalls,
especially at discovery/boost bases. User additionally requested unrestricted
laser rotation and diagonal movement. Publication to DEV is authorized; LIVE
promotion is not requested.

## Root causes and change

- Ordinary mining's `_resolve_motion` stance lock also intercepted alternative
  modes. Its nearby-resource/wall search stopped Rush even when its own ray
  had nothing to mine. Alternative modes now retain collision resolution but
  bypass that ordinary stationary stance.
- Rush's single centre-row scan missed sidewalls and ore bases overlapping the
  player's footprint. A bounded forward footprint sweep selects obstructing
  terrain and ore. It still uses timed, individual authoritative mine claims.
- Discovery bases are solid and cannot be mined. Rush steers around their
  inflated elliptical footprint and resumes its heading. It does not resolve
  or choose a discovery/boost automatically. Release clears automatic motion.
- Laser aim previously used the four sprite facings. It now uses continuous
  analogue bearing and exact grid-ray traversal over 12 cells of distance.
  Small aim adjustments within one target retain damage progress. Movement
  remains under the joystick, including diagonals; no extra automatic motion.
- Art, existing body animation assets, mod goals, saved unlocks and namespaces
  remain the DEV15.44 resources. Laser On/Off remains beside Mine.

## Reproduction and validation

Source: `f79c19a8f534aa90616468c64a9fc1e1b9c2e491`, branch
`codex/drill-mods-20261001`, exact immutable DEV15.44 baseline artifact
11192001148 / run36920475575. Narrow pack builder preserves every unrelated
resource payload and checks the nine baseline hashes.

`tools/review_bore_flow.gd` reproduces 17 failures against DEV15.44: all twelve
cardinal approaches (centre and ±24 px offsets), four real discovery-base
approaches, diagonal control, steering and release. The corrected candidate
passes all68 checks including diagonal single-cell damage and laser bearings at15-degree intervals and diagonal
laser movement near an off-beam wall. Native actual render uses Godot4.7.2,
Xvfb/Mesa,1688×780;13 final images inspected. These are not phone performance
claims. `tools/review_drill_mods.gd` also passes all63 prior mod gates.

Mac run36923988208 passed: input/414core/71browser checks and ordinary
WebKit startup. All28 final Mac images inspected, Apple Metal renderer, DPR2.
All nine Mac package files equal the locally tested native package.
Candidate11193870007, evidence11192689544. DEV publication pending. The first run36923586219
passed core and gameplay advances but read a pre-release snapshot in the
release test (QA samples every100ms). The test now observes a released frame
before comparing stationary positions; native release checks remain strict.
Native capture harness yields back to the process frame before quitting, so
its explicit completion marker is flushed after the final render callback. It includes real CDP touch:
held-Mine off-centre mining, discovery pass/release, and simultaneous Mine plus
joystick rotation through16 bearings. Existing input/core, mobile mod layouts,
save/load and ordinary WebKit startup are retained. Images are inspected; publication receipt must be verified before calling
DEV15.45 published.

## Local recovery

Workspace `/workspace/scratch/2cc6271f8659`; runtime in `runtime/`, exact local
candidate `bore-final/`, regression evidence `bore-regression-complete/`, original
mod evidence `mods-native-complete/`. Build with
`python3 game/.github/drill-mods/build.py candidate5 NEW_OUTPUT`.
Run the two external SceneTree scripts through the existing authenticated
`tools/run_rendered_isolated.py`; use `MODS_OUT` and the candidate's main pack.
Main remains a publication carrier, never a gameplay build source.
