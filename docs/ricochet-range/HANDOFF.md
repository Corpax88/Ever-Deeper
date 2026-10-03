# Ricochet range and immediate workshop skins — DEV15.54

Mats reported short Ricochet reach and a temporary wrong pickaxe in IMG_1953.jpeg. The change doubles first-shot reach256→512 world pixels (4→8 tiles) and bounce distance192→384 (3→6 tiles). Projectile speed1200px/s, three distinct contacts, damage, release cancellation and buried-ore reveal stay intact. Lifetime now covers the longest valid route plus250ms; eligible-rock snapshot spans that route. Distant ore retains the existing close-range direct strike rule; projectile bounces target rock faces.

The native pickaxe now follows requested gear immediately, without waiting for fallback sprite atlases. Crusher, Comet, Crownseeker and Deepheart workshop selections persist and return on the first mod-off frame. Ricochet deliberately retains its approved cannon while selected. No artwork, save schema, economy or hero redesign.

## Canonical package

Gameplay source be3a698e0ad8bedb91e877b9932a7bb05b80684a on codex/ricochet-range-20261003, Corpax88/Ever-Deeper. Based on published treasury-door DEV15.53/source5ac6a3cbe16b53ea8e54ac1776998765d97b3857/artifact11284031991/run37150590876. Retains that east-facing vault and Chainbreaker rock15.52. Never publish the superseded15.52-based Ricochet candidates. Main is a publication carrier, not gameplay source.

Final local PCK327687342 bytes, SHA2567637ed10116bca208f841c11ea8d9359f4057b925fe2bc20bc1cda9ec267f56d. Builder verifies all1582 unchanged baseline payloads byte-for-byte. Changes only five-drill behavior, native gear choice, preview description, QA fixture, remaps and version. Final combined Mac run37151451383 owns publication acceptance. Standing GitHub and tested DEV authorization applies; no repeat permission.

## Focused evidence

- Native range22/22: eight real-tick long-distance bearings, three long contacts, flight beyond800ms, buried-node HP, bounded reach and release cancellation. Original DEV15.52 fails11 of22.
- Retained Chainbreaker/five-mod regression51/51.
- Linux Godot4.7.2/Xvfb/Mesa:40/40 combined range/skin checks;14 actual images inspected. All four first-frame skins are correct while the sprite atlas still says deepcore. Baseline skin replay fails8 of18 checks: all four immediate selections and restorations. Production scripts are identical to the final rebased package.
- Final Mac tests cover actual CDP touch with three distant hits, stationary player, release cancellation, all four immediate skins/restoration and save/reload;667/844/932 previews, Apple Metal/DPR2. Ordinary WebKit independently covers unmodified startup/menu/save/reload. No physical-iPhone or FPS claim.
- Historical QA flag-order invariant failure remains known test debt; continue-on-error status is not a passing invariant claim. Author visual review; no new critic requested.

## Diagnostics retained

First Mac37150793904 passed native gates but browser fixture seeded workshops after entering The Deep, which ended its saved descent. Real reach guard correctly rejected mining. Second37151018728 proved actual-touch triple hits but exposed the same phase guard on repeated fixture use. Final fixture travels visibly via hub before re-entering; a local repeat proves both invocations have active descent, target and in-flight projectile. No production guard relaxed. Evidence11283523383 and11283638480 retained. Third37151279118 passed browser gates, then was superseded during ordinary startup to preserve the newly published door fix.

## Recovery

Local /workspace/scratch/fac602da740c/ricochet contains game,candidate-rebased,door-baseline,native-final,retained-mods,visual,baseline-headless,baseline-skin. Verified Godot executable /workspace/scratch/fac602da740c/runtime/Godot_v4.7.2-stable_linux.x86_64 was extracted from the intact6ab6c archive; the older executable was truncated. Existing run_rendered_isolated.py uses authenticated Xvfb and private process group. Headless skips skin checks because production creates no native renderer there; rendered/browser tests own skin acceptance.

Build .github/ricochet-range/build.py BASELINE OUT from the exact15.53 artifact. tools/review_ricochet_range.gd uses MODS_OUT and isolated XDG_DATA_HOME; RIC_RENDER=1 captures visuals, RIC_ONLY_SKIN=1 replays the skin regression. CI .github/workflows/ricochet-range.yml; publisher .github/ricochet-range/publish.py binds source, run, artifact, evidence hashes and27 public baseline files. Preserve LIVE1.0.4/Worn and DEV saves.

Player test: refresh DEV → Continue; select Ricochet and shoot a farther rock face. Release cancels. Check chosen workshop skin when the ordinary tool returns. No reset.

Final Mac37151451383 passed input/414core/22mechanics/48browser observations and ordinary WebKit26.5 startup/save/reload. All34 actual final Mac images inspected. Candidate11284088414 SHA2568b76b0067ea0a8a1aa84b9c34fad69745ebb7c119c09c436e1ad11bf153fd7c8; evidence11283589455 SHA256614b254cd0c6c0794217c8cff4603e924ed99d0046de67e0ddaf17539511e42b. Local/Mac9 file manifests identical. Immutable acceptance bindings passed. Published927d1a6e6db0c82462f5953f6c5d341653a00d08/run37151837822. Receipt11284755037 verifies all27 public hashes, unchanged LIVE1.0.4/Worn and preserved DEV save namespace. Rollback11284092358 retains DEV15.53. No pending jobs or approvals; do not repeat accepted unchanged tests/publication.
