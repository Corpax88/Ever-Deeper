# Chainbreaker rock — DEV15.52 candidate

Mats requested Chainbreaker jumps through mountain rock as well as ore (3 October 2026). Implemented on canonical DEV15.51 runtime `3bf373333fe9ac8fa5e1a58667f358b077df9c5d`, not historical main. Source candidate `5d7a30fe98215af40ad2673dd8b141221f5fb4a0`, branch `codex/chainbreaker-rock-20261003`.

Rock or ore starts one snapshot of all visible exposed ore and mineable rock-edge cells. Hops choose the closest surviving target every 0.1 seconds. There is no target count cap. Each snapshot target receives at most one chain strike. New rock layers and ore revealed during a chain wait for a later attack. Permanent walls, inaccessible depth bands and offscreen/interior rock are excluded. Node IDs and absolute terrain cells survive streaming rebases. Existing release, menu, mod-switch and movement ownership are retained. Preview text now explains rock and ore. Approved artwork, animation system, save format and other mod behavior are retained.

## Evidence

- Linux Godot4.7.2: 51 mechanics checks passed, including mixed rock/ore, distinct targets, buried-node HP, late ore eligibility, offscreen/interior exclusions, stable rock queue, release, mod switch and existing five-mod movement/core/ricochet/Vortex behavior.
- Actual Godot/Xvfb/Mesa llvmpipe render of exact candidate at1688x780:21 ordered frames; inspected rock-front break progression and blue arcs; maximum54 real strikes and0 pending on release. This is software/native evidence, not physical iPhone performance.
- Local PCK325828798 bytes, SHA2566a383de0864cac7d00204ddbdf821f59476e63ba676b56717428763949e0599e. All unaffected baseline resource payloads compared byte-for-byte.
- Mac acceptance37148602793 passed input,414core,51native mechanics and 30 browser checks/observations. Actual AppleMetal/DPR2 Chromium; ordinary AppleGPU WebKit startup/save/reload passed. All23 final Mac images inspected. Candidate11283079175; evidence11283248541. All9 Mac files match local candidate. Publication pending. Author review; no independent critic requested for this scoped change.
- Old local invariant script reports QA flag-order mismatch. The same known flag-order invariant fails on Mac; it is not counted as passed.

## Recovery

Local workspace `/workspace/scratch/fac602da740c`: `game`, `candidate`, `mechanics-final`, `motion`, `runtime`. Baseline exact DEV15.51 `/workspace/scratch/6ab6c9e27f74/candidate`; canonical baseline artifact11282502442/run37147089434. Existing source binary in an earlier workspace was truncated and segfaulted; extracting its CRC-valid archive into this task's runtime restored Godot4.7.2. Do not reuse the corrupted executable.

Build `.github/chainbreaker-rock/build.py BASELINE CANDIDATE`; this patches only two scripts/remaps and menu version into the exact reviewed baseline. `tools/review_chainbreaker_rock.gd` runs with `MODS_OUT` and isolated `XDG_DATA_HOME`. `tools/review_chainbreaker_motion.gd` runs through `tools/run_rendered_isolated.py` with explicit `MOD_MOTION_CAPTURE_OK` completion marker. CI `.github/workflows/chainbreaker-rock.yml` covers input/core, native mechanics, actual Chromium touches and normal WebKit startup/save/reload. Publication reuses reviewed artifact bytes and verifies current public baseline before preserving all LIVE/Worn files.

Standing GitHub/tested DEV authorization applies. Another chat may be correcting treasury door direction: recheck main/public baseline before publication and never overwrite a newer package. No LIVE promotion requested.

Player test after publication: DEV → refresh → Continue → DEV TOOLS → CHAINBREAKER TEST; hold Mine at plain rock, then try mixed rock/ore; release stops the chain. No reset.
