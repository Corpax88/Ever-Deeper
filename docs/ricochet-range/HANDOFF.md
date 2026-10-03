# Current candidate: DEV15.54, rebased onto published treasury door DEV15.53

Preserves source5ac6a3cbe16b53ea8e54ac1776998765d97b3857 and exact artifact11284031991/run37150590876. Prior third Ricochet browser run37151279118 passed all actual-touch and skin gates; final combined package requires its own Mac run. Previous15.52-based candidate must never be published. Earlier diagnostic record below.

# Ricochet range and workshop skin — DEV15.53 candidate

Mats reported short Ricochet range and a temporary wrong pickaxe appearance in IMG_1953.jpeg. Canonical baseline is DEV15.52 source5d7a30fe98215af40ad2673dd8b141221f5fb4a0; main is publication carrier only. Candidate sourceaa749d466117900bc800f6b745d7964e8c984e7d on codex/ricochet-range-20261003. Standing GitHub and tested DEV authorization applies.

Launch reach256→512 world pixels (4→8 tiles); bounce distance192→384 (3→6 tiles). Projectile speed remains1200px/s and three distinct contacts remain the cap. Lifetime is derived from the maximum route plus250ms, so a long valid route does not expire at the old800ms cap. The candidate snapshot spans the complete possible route. Normal damage, buried-ore reveal, stop on release, movement, collision and mod artwork remain intact. Distant ore still follows the existing close-range direct-strike rule; Ricochet's projectile bounces on rock faces as designed.

Native pickaxe presentation now resolves the requested native gear immediately instead of waiting for fallback sprite atlases. Four workshop skins retain their saved identity through Ricochet and restore on the first mod-off frame. Ricochet still deliberately shows its approved cannon while selected, just as before; this change repairs delayed normal-skin presentation and does not redesign the mod weapon.

## Evidence and limits

- Exact final PCK325831902bytes/SHA256a9af6c9a7dfd0486fb307805d70818adb514f80cf030a2b0cd867b9b21dae2d3; builder verifies every unchanged baseline resource payload.
- Native headless22 range/flight checks passed, including eight real-tick long-distance bearings, three long contacts, lifetime beyond800ms, buried-node HP and cancel-on-release. Original DEV15.52 fails11 of these checks.
- Retained Chainbreaker/five-mod regression suite51 passed.
- Linux Godot4.7.2 with Xvfb/Mesa llvmpipe:40 combined range/skin checks passed;14 actual final-candidate images inspected. Production scripts match final package; final package additionally adds browser-only fixture commands. All four first-frame skin checks show the requested native gear while the sprite atlas still says deepcore, proving independence from that loader. Baseline visual skin-only replay fails8 of18 skin checks (all four immediate selections and restorations); original report retained.
- Mac37150793904 pending; input/core, native range, real-touch long shots, all four native skin selections/restores and ordinary WebKit must pass before DEV publication. No physical iPhone/FPS claim. Author review, no new critic requested.
- Known inherited QA flag-order invariant remains test debt, not a passing check.

## Recovery

Scratch `/workspace/scratch/fac602da740c/ricochet` contains game,candidate-final,native-final,retained-mods,visual,baseline-headless,baseline-skin. Use verified executable `/workspace/scratch/fac602da740c/runtime/Godot_v4.7.2-stable_linux.x86_64`; the older6ab6c runtime executable was truncated, its archive was valid. Local Xvfb helper uses the recovered6ab6c Xvfb package. Native headless deliberately skips skin checks because production does not create native renderers in a headless display; actual graphical/browser tests own skin acceptance. An early fixture failed by assuming that renderer existed; fixed in the harness, not production.

Build `.github/ricochet-range/build.py BASELINE OUT` using exact DEV15.52 artifact11283079175/run37148602793. `tools/review_ricochet_range.gd` with MODS_OUT and isolated XDG_DATA_HOME; RIC_RENDER=1 under graphical runner captures range and skins; RIC_ONLY_SKIN=1 isolates the skin regression. `tools/review_chainbreaker_rock.gd` retains other mod checks. CI `.github/workflows/ricochet-range.yml`. Never rebuild historical main or publish unreviewed bytes. Recheck public baseline before publication in case the separate treasury-door task advances DEV.

Player test after publication: refresh DEV → Continue. Select Ricochet and shoot a more distant rock face; release cancels. Check the chosen workshop skin when the ordinary tool returns. No reset.

First Mac run37150793904 passed native gates but failed browser range because the fixture built workshops after entering The Deep; relic-seeding ended the saved descent, so the real reach guard correctly rejected mining. Fixture now explicitly re-enters after seeding. No production behavior was relaxed. Failure evidence11283523383 is retained.

Second Mac37151018728 verified real-touch long-range triple hits, but the repeated cancellation fixture exposed the same phase guard while already visually in The Deep. The fixture now travels visibly through hub before re-entering; a local real-API repeat regression verifies both invocations have an active descent, the distant target and an in-flight projectile. Evidence11283638480 retained. Production code unchanged between these test-fixture revisions.
