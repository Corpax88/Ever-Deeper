# Skills DEV15 independent review — round 1

Reviewed the initial native `skills.png`, `fresh.png`, and `map.png` captures under
`/workspace/scratch/15556b9375f7/runtime/skills-native/` against the approved
`42A25114-7292-4352-BD31-71556D8D420B.jpeg`. Reviewed the new Skills/training/meter/QA
scripts and their integration diff in main, RunState, player controller, HUD, and menu.
This is a review of the first native rendering, not acceptance of a final exported
web package or evidence of physical iPhone performance. The implementer was already
correcting the visual problems below while this review ran.

**Initial scores: code/state integration 7.8/10; visual fidelity 6.8/10.**
No critical save-corruption or player-immobilization defect found. The layout and
embedded-map issue prevent accepting this iteration as finished.

## Concrete findings

1. **Medium — resizing while Map is open overwrites its embedded layout.**
   `scripts/ui/miner_skills_panel.gd:show_map()` instantiates
   `scripts/ui/minimap_overlay.gd`; that component's `_ready()` connects
   `viewport.size_changed` to its own `_apply_layout()`. The Skills panel already
   has an earlier connection. A resize invokes the panel's `_layout()` first,
   setting the map rectangle inside the plate, then the minimap callback replaces
   it with viewport/HUD coordinates. That can put the map outside its plate.
   Give the embedded map explicit layout ownership or disconnect its HUD resize
   callback. Verify resize/rotation while Map remains open.

2. **High visual — progress captions overlap row borders.**
   `scripts/ui/miner_skills_panel.gd:_layout_row()` places the caption at
   `h * 0.48 + 16` with height30; in the landscape rows, visible text reaches
   the bottom copper edge. All four skill rows and Stamina show this in both
   fresh and populated native screenshots. Fit title, bar, and caption inside
   an inset row content area; preserve a clear bottom gap.

3. **Medium visual — row icon and material treatment depart from the locked target.**
   `_make_row()`, `_frame()`, and `_button()` in
   `scripts/ui/miner_skills_panel.gd` show bare glyphs rather than the target's
   independent square icon frames. Strong high-frequency copper flecks cover
   row backgrounds and compete with text. The reference has quieter dark iron,
   broader restrained copper edges, and a clearer selected-tab glow. Stamina
   also needs the visually separate footer treatment seen in the target.
   The hero/pet identity, cave composition, warm lighting, cream serif type,
   basic navigation, and live-data hierarchy are substantially recognizable.

4. **Low/conditional — running stamina depends on render/physics sample alignment.**
   `scripts/progression/miner_training.gd:_process()` reads a physics travel
   counter and passes render `delta` into
   `scripts/state/run_state.gd:advance_miner_training()`. The movement cost only
   applies when the counter changes on that particular render frame. Empty
   samples interleaved with multi-tick samples therefore undercharge time-based
   running cost. At120 render FPS/60 physics FPS it would halve running drain;
   the current project caps rendering at60, so this is not a demonstrated target
   device failure. Use a consistent physics tick or accumulated movement time
   if changing the cap, and preferably now for deterministic training.

5. **Low visual — resource thumbnails need stronger readability.**
   In `scripts/ui/miner_skills_panel.gd:_ready()`, the loaded ambercore image
   occupies very little of its thumbnail rectangle, while lunacore appears
   bright purple. The approved strip uses similarly prominent warm mineral
   silhouettes. The actual resource identities and live counts are useful;
   improve their visible sizing and account explicitly for any intentional
   color difference instead of treating current appearance as exact parity.

## Code assessment

The additive optional save section is sensibly bounded and older valid schema3
saves migrate mining/prospecting from recorded history. Level100 is correctly
bounded by257500 cumulative XP. Zero stamina retains movement and mining through
an effort floor. Menu routing reuses the existing world deactivation/resume
path and clears held movement/mining before opening. State remains owned by
RunState rather than the presentation component. Autosave requests reuse the
existing6-second batching instead of writing each frame. The unused
`_miner_cargo_count` field is minor cleanup, not a release blocker.

The reviewed native log ends in `MINER_SKILLS_COMPLETE 30`. Its assertions cover
calculation, save round-trip/migration, the direct Skills/Map/Inventory/Settings
routes, and stopped/resumed player control. They do not exercise real touch input,
actual movement-to-training sampling, exhausted mining damage, embedded-map
resize, or the final web package. Mockup-like XP values in the populated capture
are fixtures and do not establish gameplay progression.

## Narrow acceptance still needed

- Fresh and populated Skills renders after the row/material corrections.
- A real Map resize/rotation check and a touch open/tab/close/resume path.
- A short actual gameplay check showing movement and mining earn the intended
  skills and fatigue/recovery remains bounded without held-input leakage.
- Final target mobile viewport capture from the exact published candidate;
  physical iPhone smoothness must remain explicitly unverified until measured.

An extra isolated headless probe did not execute because the then-current local
Godot executable was truncated (30,539,776bytes; ELF section headers beyond EOF).
That failed invocation produced no behavioral evidence and is not counted as a
Skills code failure. Source review alone establishes the callback conflict above.
