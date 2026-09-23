# DEV15.6 — depth-one terrain CPU improvement

Mats requested an FPS improvement for DEV after an iPhone video of DEV15.5 in Emberdeep Works. LIVE1.0.0 is outside this change. Canonical source: Corpax88/Ever-Deeper, branch `codex/fps-dev15-6-20260923`, export commit `6073b9d4dc11034d60305d5eb49785c033e836ed`. This handoff supersedes earlier completed-task notes for subsequent source work.

## Change and measured result

Depth-one mining impacts and moving drops previously caused every visible terrain section to execute its drawing code again. The world now reuses the existing bounded LitDrawSections cache for unchanged terrain. Four drawing passes, ordering, bounds and dynamic effects are retained. Fingerprints include actual block dictionaries (including HP), a one-cell neighbor halo, void flags, hidden areas and discovery state. A generation invalidates configured biome resources. Temporary cell signatures are reused across overlapping halos within each draw request, never across frames. Existing section recycling bounds the visible cache.

Runtime ownership: `scripts/world/mossvein_mine.gd`; other runtime changes only stamp DEV15.6. No gameplay, save format, approved assets, hero, animation or lighting changes. All 21 approved native resources retain their locked hashes.

Run `35926247469` passed. Same-package reference/candidate/reference held-touch mining on Mac Chromium/ANGLE Metal (Apple Paravirtual GPU), 844×390 CSS / DPR3, canvas2532×1170, produced 88 impacts in each window. Section setup plus callback CPU was 180,946 versus 130,386 microseconds per second compared with the faster reference: **27.94% less measured section CPU**. Frame p95 was22/25ms in references versus20.6ms cached; means remained about59FPS. Occasional stalls remain; this is not a physical iPhone FPS claim.

The fixed seed4608 and durable target make sustained hits comparable. Timed windows exclude setup/screenshots/readbacks. This workload excludes actual block breaking/loot and persistence. The user's26–37FPS and isolated250ms/223msCPU event are not established as resolved. The six-second synchronous autosave is only a separate possible cause, deliberately unchanged.

## Validation and acceptance

- Five exported core cases: input, overhaul, touch, layout, build-flavor; all passed.
- 28 Skills/save checks passed.
- 25 actual Chromium checks passed, including17 exact full-frame reference/cache pairs covering intact/damaged/removed/restored blocks in all four depth-one biomes and camera movement. Real held touch, release and movement passed.
- Ordinary Apple WebKit menu, new game, saved menu/reload and new-game confirmation passed without QA arguments.
- Ten final images independently inspected: scoped code9/10, visuals8/10, no blocker. Existing sharp rectangular lighting/terrain transitions are unchanged and not claimed fixed.
- Historical protected-file differences remain reported, not relabeled as passing.

The named nonpersistent `--qa-fps-review` suite and `.github/workflows/fps-dev15-6.yml` are the reusable route. The original renderer remains the opt-in `cache_terrain_draws=false` reference. Do not repeat export/testing for this unchanged accepted candidate.

Two initial fixture attempts were rejected for pause-independent minimap/guide pulses and HUD status fade. The final fixture freezes those clocks and sets time_scale0 only for exact screenshot comparisons, restoring1 before every timed workload. No cropping, masks or relaxed pixel tolerance. Candidate3e255/run35898737919 then passed all16 biome pairs but achieved13.54% section CPU reduction, below the20% gate. The accepted6073 refinement hashes overlapping neighbor cells once per draw and passes that same gate. Prior rejected artifacts remain in their runs.

## Exact artifacts

- Candidate10779057126, ZIP sha256:f5b90f89f9ff99e9e160519dc6de3c02a9e5da788b557b977ae2730be2f30580.
- Build10779530793, ZIP sha256:8231d627f2ee14512c37da9e5b12800525e76cef360dcffc8101a44a476e8879.
- Browser10779826460, ZIP sha256:6efdd95ef62fe6cec81aa0276cd15857249aa88fa3d4a8ad14744a629e1139ad.
- PCK259857348 bytes, SHA256fe433feaedbbaf383e61f8c9d9ae825c2cd2753c50f8b8fd4db38a894133580c.

Publication evidence lives on main under `.github/fps-dev15-6/`. The DEV-only publisher preserves nine LIVE1.0.0 and nine Worn files and verifies all27 public hashes. Publication status/receipt is appended below when confirmed. The first staging run35927336774 stopped before deployment because the locally reconstructed Worn manifest had an extra trailing newline. Only its evidence pin was corrected to the exact unchanged committed bytes; no Worn file or accepted candidate changed.

Next user test after publication: refresh DEV to15.6 on the same iPhone, play/mine in Emberdeep for at least two minutes with SHOW FPS, and compare sustained FPS and long spikes. No new LIVE release is authorized by this FPS task.

## Published and verified

DEV15.6 is published at https://corpax88.github.io/Ever-Deeper/dev/. Publication commit f9b15ce72cb01420f510a793837b72e93ded7c5c, run35927487060: package/deploy/verify all succeeded. All27 public file hashes match; nine LIVE1.0.0 and nine historical Worn files are unchanged. Receipt artifact10779323154, ZIP sha256:33d0df61c64be0918c538506edd2609a6840e89b89895ae98d93de273075177a. The previousDEV15.5 is retained by the publication rollback artifact. This scoped task is complete. Do not rebuild or republish the unchanged candidate. Next step is physical iPhone comparison in Emberdeep.
