# Floor-detail command order — stopped at headless opportunity gate

Isolated source base: DEV11 `8f5680defb9083bbe1e044d39a10612f2186e7f3`.
Branch: `codex/dev11-floor-detail-order-study-20260917`.
Production is unchanged. No graphical comparison, renderer draw count, timing,
FPS result or adoption exists for this candidate.

The completed Mac sample and primary-source trace are separately pinned at
[`f9c02a9fe955b997aedbb979aec93d20aee74a83`](https://github.com/Corpax88/Ever-Deeper/tree/f9c02a9fe955b997aedbb979aec93d20aee74a83/tools/mac_cpu_sampling).
They identify main-thread waits in ANGLE's provoking-index conversion buffer
reuse. Persistent mesh substitution was rejected by source inspection: Godot's
rectangle path already has a persistent six-index quad, while mesh commands
retain flat varyings and start their own unbatchable draws.

This distinct candidate only moves floor-detail lines after solid-cell commands
within each existing four-cell pass-1 CanvasItem. It calls the original floor
and rock/ore/damage drawing functions, keeps each family's relative order, and
retains the same CanvasItem, geometry union, material and light-culling bounds.
The surrounding floor and projecting-edge passes remain unchanged. Nonstandard
materials, modified standard shader code, inherited material, unbound source or
nonstandard strip bounds use the original function. The tool subclass is
attached to the existing scene node before it enters the tree; it does not
change production files or install a runtime feature flag.

`audit.gd` checks every possible line offset, the actual authored rock/ore/damage
extent, and every moved line's intersections with intervening solid cells in
nine generated Deep view inventories. The damage bound uses the exact engine's
maximum width, clamped miter factor and antialias feather. `check.gd` exercises
the actual guard against normal and fallback resource states using the exact
published PCK. `run_headless.py` binds PCK bytes and unchanged production-owner
hashes, retains logs/receipts, and requires exit, marker and report gates.

The predeclared opportunity threshold was a median of at least five fewer
command-family runs before considering graphics. The model distinguishes each
strip independently from concatenating strips so existing cross-item batching
is not ignored. It does not model exact renderer light-specialization/clipping
splits and is not an actual GL counter.

The first headless run passed geometry and eligibility but **failed opportunity**:
only 0–1 local run reductions per view, while concatenating strips increased
runs by 3–14, median 7. The candidate moves interruptions to strip boundaries and
can break existing batching. It has therefore stopped before any graphical gate
or performance trial. Do not change ordering heuristics, widen strip scopes or
start a mesh trial under this authorization. [RESULTS.md](RESULTS.md) retains the
exact results and evidence limits.

Reproduction of the completed headless check, if independently requested:

```sh
python tools/floor_detail_order/run_headless.py \
  --godot /path/to/Godot_v4.7.2-stable_linux.x86_64 \
  --pack /path/to/exact-DEV11/index.pck \
  --output /tmp/ever-deeper-floor-detail-audit-unique
```

No renderer or timing harness was prepared after the stop gate failed.
