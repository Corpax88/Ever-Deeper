# Private Worn UV component audit — 2026-09-16

The prepared target contains 29,681 disconnected indexed-edge surface components,
but its existing smart-project atlas contains 152,512 UV islands. Most of the
excess charts are cuts within connected groom strands. Disconnected strands are
also real; joining their geometry or overlapping their normal/AO charts would
not be a justified correction.

This was one read-only Blender 4.5.3 process. It exited 0 in 71.898 seconds,
with peak child RSS 1,234,124 KiB (about 1.177 GiB). The 120-second cap was not
reached. Resource usage came from Python child `getrusage`, because GNU time is
absent. This is an audit resource measurement, not a runtime/bake performance
comparison. No renderer, bake, UV operator, export or `.blend` save ran. Original
scene/geometry/UV/material/rig fingerprints and the prepared file hash were
unchanged. Repository transfer/helper files were left untouched.

| Group | Evaluated native components | Prepared components | Prepared UV islands |
| --- | ---: | ---: | ---: |
| Face | 1 | 1 | 1,670 |
| Eyes | 10 | 10 | 740 |
| Cloth | 21 | 19 | 301 |
| Groom including roots/brows | 29,306 | 28,158 | 144,718 |
| All 629 source objects / whole target | 30,839 | 29,681 | 152,512 |

Edge-connected and vertex-connected surface component counts match in both the
evaluated native source and prepared target. Point-only contact does not explain
the count. No indexed mesh edge with more than two incident polygons was found.
Counts use indexed topology; coincident positions were never welded.

| Fiber source | Evaluated components | Prepared components | Prepared triangles | UV islands |
| --- | ---: | ---: | ---: | ---: |
| `v17 fine curved facial groom` | 25,100 | 23,953 | 180,286 | 116,938 |
| `v26 swept short hair fibers` | 4,200 | 4,199 | 46,534 | 27,607 |

Every retained fiber component uses 2–11 UV islands. The median is 5 for facial
groom and 6 for hair. Of the 144,545 fiber islands, 92,848 (64.23%) contain one
triangle. Thus the atlas has mostly fragmented small fiber charts, rather than
144,545 individually disconnected fiber meshes. Across the whole target, UV-cut
adjacent face pairs have median normal angle 90.34 degrees; only 243 of 196,881
pairs are within one degree. Simply flattening or stitching the existing planar
projections is not a defensible unwrap.

The source fibers are uniform 24-triangle components with Euler
characteristic 0 and eight boundary edges each. Every retained target fiber
component still has Euler characteristic 0, now with six boundary edges; it has
4–18 triangles, one material, and positive world area. This is consistent with
uncapped tubes. The audit did **not** separately prove two simple boundary
cycles, manifold vertex fans, orientability or lack of self-intersection. Those
conditions must be checked before using an annular-strip parameterization.

The prepared LOD has 1,148 fewer fiber components than its evaluated native
donors (1,147 facial, 1 hair), and 1,158 fewer components overall. This is an
existing preparation difference, not a change performed by this audit. Exact
missing/merged/collapsed component attribution was not measured. The prepared
LOD remains an unapproved derivative; UV correction cannot restore any geometry
already removed during preparation.

A defensible next private UV-only case would:

1. On a disposable target copy, validate every selected fiber component as an
   orientable annulus with two simple boundary cycles, valid vertex fans and
   positive-area triangles. Fail closed on components outside that topology.
2. Add one deterministic longitudinal **UV seam** joining the boundary cycles;
   unwrap that strand as one unique strip chart. Do not join mesh vertices,
   retriangulate, recalculate corner normals, alter skin weights/materials or
   stack charts. Distinct strands need unique normal/AO transfer even when their
   Principled colors are constant. A changed UV tangent basis requires a fresh
   matching normal bake later; previous maps cannot establish its fidelity.
3. Keep nonfiber chart topology unchanged in this first case. Repack only the
   derived UV layer with an explicit, measured per-side gutter. Preserve the
   original layer/file and save a loop-indexed patch plus geometry/material/skin
   hashes. Reject new zero-area positive-world-area faces, overlaps, out-of-bounds
   UVs or inadequate separation; report distortion and face/eye texel allocation.
4. Measure actual chart-interior separation and atlas-edge gutter in pixels;
   do not assume a Blender margin argument equals that distance. Account for
   rasterization and the deepest sampled mip/filter footprint before claiming
   the result is safe for rendering. The existing positive-world-area zero-UV
   face slivers also remain an unresolved separate condition.

If every fiber topology guard passes, one chart per fiber would reduce the full
atlas to 36,119 charts while leaving the other 7,967 chart boundaries intact.
That is a hypothesis, not an executed unwrap or quality result. One chart per
all 29,681 target components is only an optimistic counting bound: closed or
complex surfaces can reasonably require more charts.

| Layout hypothesis | Atlas | 2 px per-side square padding floor | 4 px per-side square padding floor |
| --- | ---: | ---: | ---: |
| Existing 152,512 charts | 1024 | 232.71% | 930.86% |
| Fiber strips; 36,119 total charts | 1024 | 55.11% | 220.45% |
| Fiber strips; 36,119 total charts | 2048 | 13.78% | 55.11% |

These are zero-size rectangular/AABB-chart padding budgets, before useful chart
area or packing waste, not general shape-packing proofs. They show why margin
removal alone is insufficient and why the required filter/mip gutter matters.
A 1024, 2-pixel case can be a bounded layout feasibility test after the strip
guards pass; it is not yet a defensible full transfer. At 4 pixels per side,
the proposed rectangular chart count already exceeds a 1024 atlas. A 2048 layout
has more room, but neither that resolution nor its memory cost is approved.
Do not bake at either resolution until useful face/eye coverage and sampling
requirements are measured. No texture or rendering acceptance is inferred here.

Reproduction (choose a fresh output path and coordinate the graphical slot):

```sh
python /workspace/scratch/4e99473f21fc/private-uv-components-c1/run_audit.py \
  --output /workspace/scratch/4e99473f21fc/private-uv-components-c1/repeat-audit
```

The wrapper supplies the Blender executable, immutable prepared file, two
threads, `--python-exit-code 1`, and `timeout --signal=INT --kill-after=15s 120s`.
The audit reads the previously retained UV island arrays, verifies exact live
UVs, tessellation and world triangle areas, then measures all source meshes.
`audit/report.json` contains all 629 source rows; `audit/target-connectivity.npz`
retains face-to-component/chart assignments and topology counts.
`component-summary.json` records the compact comparisons and padding arithmetic.
Small independent graph fixtures check shared-edge versus point-only contact
and nonmanifold-edge connectivity in `pure-connectivity-check.json`.

Prepared file SHA-256:
`2e7da103c3b4d16cf159d68525f1853630058a85747964a9f8305eb54aeedd91`.
Audit source SHA-256:
`33a62422ad51497c1ae0a21b345ff6ba313487888d65e386ee22646f30b607ad`.
Completed report SHA-256:
`58922ea7283fb2544a20a1051e7ec61d60d4d8ec7f9aacd37d457fff79e0a178`.
