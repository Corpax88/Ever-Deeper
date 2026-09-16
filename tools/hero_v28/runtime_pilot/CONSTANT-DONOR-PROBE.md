# Constant-material donor experiment

`constant_donor_probe.py` is an isolated review helper. It does not edit the
production exporter, save a Blender file, export a GLB, or change production
hero assets. All generated evidence must be outside this git checkout. Native
Blender files remain private. Successful source checks do not establish that
the helper has run, that its bake is equivalent, or that a runtime asset is viable.

The retained inventory predicts 369 constant-material donors across 19
materials. Consolidating only these should leave one helper plus 260 unchanged
procedural, UV or attribute-dependent donors. Live connected-socket validation
is authoritative; unused TexCoord nodes do not cause rejection.

The helper accepts only a direct, unmuted Principled BSDF with **every input
unlinked**, no connected volume/displacement, no nonzero authored normal,
tangent or displacement defaults, and no material/node animation or drivers.
Different ray-visibility/shadow-terminator settings and viewport/render modifier
mismatches are rejected. Other source materials and coordinates remain intact.

Evaluated polygons, loops and edges are copied at the current pose into one
static world-space mesh. The helper preserves evaluated material assignments,
smooth flags, sharp edges, transforms, winding and corner normals; it applies
inverse-transpose normal transforms and handles reflections explicitly. It
validates the resulting tessellation against each original face's oriented
triangles. No vertices are welded or polygon faces triangulated during copying.
Custom normals have a checked component tolerance of 0.0003. Source vertices,
modifiers, weights and the 17-bone rig are never edited. Only the originals
represented by the helper are hidden during the bake, then restored. All other
native surfaces remain available as AO occluders. The helper is then deleted.

Run the following in **separate, serialized processes**, after other performance
work has stopped. Use an empty output directory for every run. These are proposed
commands, not a record of completed Blender execution:

```sh
env OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=2 \
  timeout --signal=INT --kill-after=15s 300s \
  /tmp/ever-deeper-runtime-20260915/blender-4.5.3-linux-x64/blender \
  --background /workspace/scratch/5a78be25fc28/worn-native-runtime-b1/prepared.blend \
  --threads 2 --python-exit-code 1 \
  --python tools/hero_v28/runtime_pilot/constant_donor_probe.py -- \
  bake --mode separate --scope sample --channel albedo --size 256 --threads 2 \
  --output /workspace/scratch/5a78be25fc28/constant-donor-probe-b1/separate

env OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=2 \
  timeout --signal=INT --kill-after=15s 300s \
  /tmp/ever-deeper-runtime-20260915/blender-4.5.3-linux-x64/blender \
  --background /workspace/scratch/5a78be25fc28/worn-native-runtime-b1/prepared.blend \
  --threads 2 --python-exit-code 1 \
  --python tools/hero_v28/runtime_pilot/constant_donor_probe.py -- \
  bake --mode merged --scope sample --channel albedo --size 256 --threads 2 \
  --output /workspace/scratch/5a78be25fc28/constant-donor-probe-b1/merged

python3 tools/hero_v28/runtime_pilot/constant_donor_probe.py compare \
  /workspace/scratch/5a78be25fc28/constant-donor-probe-b1/separate \
  /workspace/scratch/5a78be25fc28/constant-donor-probe-b1/merged \
  --output /workspace/scratch/5a78be25fc28/constant-donor-probe-b1/comparison.json
```

The default sample contains the original right boot sole, rounded jaw beard,
short hair roots and facial groom. This covers Bevel, Solidify, Subdivision,
multiple material slots and unused coordinates, using four donors versus one.
Only those selected donors supply projection pixels; all native source meshes
remain present for occlusion. `--donor 'exact name'` can be repeated to choose
a different fixed sample. Both processes must use identical arguments apart
from mode/output.

Each run saves the opaque RGB channel PNG, unquantized image-buffer `rgba.npz`,
the legacy Blender serialization as `<channel>-raw-rgba.png`, and a JSON
report with source/script identities, material decisions, selected donors,
normal error, build time, blocking bake time and script wall time. Script wall
time excludes Blender startup and loading the source file. The report is saved
before the bake so a timeout retains useful settings. Redirect each process's
stdout/stderr to a separate private log to count Cycles initializations.

Comparison rejects different sources, scripts, targets, channels or settings;
it reports raw RGBA maxima, RMSE, alpha differences and both timings. Albedo RGB
is scene-linear, not PNG-encoded bytes. `--max-abs VALUE` adds an explicit numeric
limit and returns exit code 2 if it fails. There is no implicit approval threshold.
For guarded runs, `--require-rgb-exact` separately requires identical encoded
RGB8 pixels and verifies each saved PNG against its retained raw RGB. It does
not change the meaning of the raw-RGBA comparison or make its failures pass.
AO sampling noise can change after object regrouping even with the fixed seed.
The probe uses a float image buffer to expose differences before quantization;
the corrected opaque output is an isolated pilot contract, not a change to
production textures or sprite transparency.

Inspect the paired PNGs and numbers first. Then repeat the bounded pair for
`--channel normal` and `--channel ao`, using new directories. Normal preservation
checks and albedo equality alone cannot establish AO equivalence. Only after
those checks should `--scope full` select all 629 original donors for baseline,
or the merged constant group plus the unchanged dependent donors for the
candidate. Full scope is opt-in and may require a separately chosen time budget.
Its timings remain offline bake evidence, not Godot or physical-device FPS.

## Polygon preservation correction

The initial four-donor separate albedo probe completed, but the merged helper
correctly stopped before baking on a maximum corner-normal error of 0.0024516284.
The private geometry diagnostics found all sampled corners were already smooth;
forcing smooth flags did not fix it. Unchanged local polygon copies roundtripped
within 1.79e-7, while explicit triangulation reproduced the larger error. All
four source transforms were identity, world-position roundoff was zero and
`mesh.update()` introduced no further normal change. This was an avoidable
polygon-topology change, not evidence for relaxing the tolerance.

The corrected helper therefore preserves the evaluated polygon/loop/edge
topology and checks exact tessellation, smooth flags, material indices and
corner normals before baking. The 0.0003 limit is unchanged. Diagnostic JSON
and the original triangulating helper snapshot remain private evidence; they
are not production assets.

The corrected helper passed a 15.69-second geometry-only validation. The four
sample donors retain 518,514 polygons and 1,037,212 evaluated triangles with
maximum corner-normal error 1.78814e-7. All 369 qualifying donors retain 646,551
polygons and 1,287,070 evaluated triangles with maximum error 0.0000425875.
Both runs preserved exact oriented tessellation, smooth flags, sharp edges,
material indices and source/target/rig fingerprints after cleanup. These are
geometry checks, not rendered material or animation acceptance.

The fresh corrected-helper albedo pair used identical 256px/8-sample settings.
Four separate donors took 34.176 seconds to bake (34.666 seconds script total);
one merged donor took 10.748 seconds to bake (16.096 seconds total including
4.826 seconds preparation). The logs show four versus one Cycles initialization.
This is one offline bake pair, not runtime performance evidence.

The declared 1e-6 raw-RGBA limit **failed**. Raw RGB is bit-for-bit identical,
but 65,013 alpha texels differ, including 126 colored edge/padding texels. PNG
serialization changes RGB in those same 126 texels, with maximum encoded
channel difference 201/255. The failed pair is retained unchanged. Alpha's
actual material/export contract and serialization require diagnosis before
accepting this bake optimization; alpha must not simply be dropped from the
comparison. Normal and AO bake pairs have not run.

The subsequent read-only opacity audit verified that all 19 eligible materials
and all 32 native source materials have an unlinked Principled Alpha of exactly
1.0 and an unlinked Transmission Weight of 0.0. The newly created export material
also has Alpha=1.0 with no image-Alpha connection. The pilot runtime replaces
imported materials with its opaque StandardMaterial3D; its transparent viewport
provides geometric silhouette coverage. These facts establish an opaque RGB
data contract for the pilot maps, not for the production 2D sprite atlases.

Serialization-only trials on the retained raw arrays found that setting the
generated float image's alpha mode to STRAIGHT, PREMUL, CHANNEL_PACKED or NONE
does not prevent the PNG RGB alteration on this save path. All four variants
retain the same 126 differing RGB pixels. A controlled RGB=(0.2,0.1,0.05), A=0.25
buffer saves as encoded RGBA=(255,255,253,64). An explicit RGB data serialization
path therefore needs separate verification; changing a mode or relaxing the
failed RGBA comparison is insufficient. The failed raw buffers and PNGs remain
unchanged in private evidence.

## Explicit opaque RGB output

The isolated helper now guards every live source material before any bake
override: one active direct Principled surface, Alpha unlinked and exactly 1.0,
Transmission Weight unlinked and exactly 0.0, no connected volume/displacement,
and no animated/driven material tree. The temporary target has the same opacity
guard. Connected color/normal inputs and unused nodes do not affect this check.
Unsupported or translucent material graphs stop the probe before baking.

The RGB writer bypasses Blender's float-image PNG serialization. It writes PNG
color type 2, RGB8 with no alpha channel, and never multiplies or divides RGB by
bake alpha. Albedo uses the piecewise scene-linear-to-sRGB transfer. Normal, AO
and scalar data maps retain linear encoding. Quantization clamps to [0, 1] and
rounds nearest with half values rounded up; clipping counts are reported. Only
albedo receives an sRGB PNG declaration. Blender's bottom-first pixel rows are
flipped to PNG top-first order. Raw RGBA and its legacy PNG remain separate
diagnostic evidence. No production exporter or 2D sprite code was changed.

Pure-Python verification passed known numeric swatches, independent Pillow PNG
decoding, row orientation, alpha independence, refusal to overwrite evidence,
malformed-buffer rejection and nine opacity-guard rejection cases. In particular,
linear [0, 0.0031308, 0.18, 0.5, 1] encodes to sRGB bytes [0, 10, 118, 188, 255]
and linear data bytes [0, 1, 46, 128, 255]. RGB=(0.2, 0.1, 0.05) produces
[124, 89, 63] for alpha 0, 0.25 and 1 alike.

The untouched failed albedo buffers produce exactly identical corrected RGB
PNGs: zero differing encoded RGB pixels and identical PNG file bytes. Both
PNGs were inspected. Hashes confirm every original failed-pair file remains
unchanged. The original raw-RGBA maximum remains 1.0 against the declared 1e-6
limit, with 65,013 differing alpha pixels; that criterion still **fails**. This
is a verified correction to the opaque map output contract, not a relabeling
of the failed RGBA test. No new Blender process or rebake was needed for this
serialization verification.

## Fresh normal and AO sample pairs

Four fresh processes completed in serialized order with identical 256px,
8-sample, 2-thread settings. Every run passed the live opacity guard for all
32 source materials. Separate and merged runs have matching prepared-source,
helper and settings signatures. The declared bounds were unchanged: exact
encoded RGB8 equality, and a separately reported raw-RGBA maximum of 1e-6.

| Channel | Raw RGBA maximum / 1e-6 result | Corrected RGB8 result | Separate bake / total | Merged bake / total |
| --- | --- | --- | --- | --- |
| Normal | 1.19209e-7 / pass; alpha identical | Exact equality | 6.950 / 7.457 s | 3.946 / 9.462 s |
| AO | 1.0 / fail; only alpha differs | Exact equality | 6.394 / 6.837 s | 4.251 / 9.850 s |

Both saved RGB PNG pairs were verified against their retained raw buffers and
visually inspected. The merged geometry still meets the unchanged 0.0003 normal
limit, with maximum error 1.78814e-7. Each pair logs four Cycles initializations
for separate donors and one for the helper. Preparation took 5.044 seconds for
normal and 5.094 seconds for AO; therefore neither sample improved total script
time, despite lower blocking bake time. No runtime/FPS conclusion follows.

The normal buffers share 103 components slightly above one (maximum
1.000009894), reported and identically clamped by the explicit RGB8 encoding.
AO raw RGB is bit-for-bit identical. Its 64,960 differing alpha pixels include
43 nonblack pixels and 64,917 black pixels. The raw-RGBA criterion remains failed;
the guarded opaque output criterion passes independently. The AO sample has
only 243 nonblack pixels, including 219 fractional pixels and 134 distinct
scalar levels. This sparse sample cannot establish whole-character AO fidelity.

These are bounded sample results. Full-scope bakes, native/runtime visual and
animation comparison, physical-device performance and production acceptance
remain untested. No full-scope bake, GLB export, production hero edit or native
source publication was performed.
