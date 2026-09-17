# Bounded WebKit resource-call attribution

The one independently reviewed session completed as run **35225485863**, measured
request `f311ec95fd43018c0e2747c9113fce3d882d9610`, preparation `667b293f`.
[Results](RESULTS.md) attribute much of two large callbacks to LINK_STATUS host
calls; a third remains unattributed. No further session or runtime change is
authorized by this result. It is an attribution diagnostic, not a runtime
optimization or an FPS acceptance test. The prior phase diagnostic and all of its
failure evidence remain separately preserved. The contract below describes the
measured preparation; post-run analysis and report files were added afterward.

Use the original DEV11 candidate from run 35186932201, artifact 10481858878,
source `8f5680defb9083bbe1e044d39a10612f2186e7f3`. Its identity-file SHA256 is
`027b128fe5fa70d7814c0f0952ee06549f447afc9769426c3b5696c631579a7a` and PCK SHA256
is `5b77b3a219011cb676895e41830c8dab32bec2346db93102c7894a3c084414e9`.
`package-pins.json` fixes every byte count and SHA256 for all nine exported files.
There is no Godot build step, production code edit, renderer switch or publication.
The workflow downloads the existing artifact and serves its bytes unchanged.

## Question and coverage

The completed diagnostic run 35218778984 had three large callbacks with no overlap
with its synchronous generation, stream-rebase or save spans. This probe asks
whether a new long callback includes a slow synchronous texture/shader host call.
It cannot assign the remaining time to simulation, GPU execution or garbage
collection. A fresh random run without a comparable hitch is inconclusive.

Only seven methods on the actual game canvas's WebGL context are wrapped:

| Method | Selected calls |
|---|---|
| `texImage2D` | All calls |
| `compressedTexImage2D` | All calls |
| `texStorage2D` | All calls |
| `compileShader` | All calls |
| `linkProgram` | All calls |
| `getShaderParameter` | `COMPILE_STATUS` only |
| `getProgramParameter` | `LINK_STATUS` only |

The unchanged shipped `index.js`, SHA256
`33c94cb3175f3333b82e2a3be5e8e86f77986f0aa2042b1631f6367a4e5bb6ba`, directly
dispatches all seven. It contains neither `texSubImage2D` nor
`compressedTexSubImage2D`; the proposed 2D subimage hooks were therefore omitted.
Those absences are checked against the real candidate before the browser starts.
Texture arrays/3D uploads, mipmap work and other host methods remain unmeasured.

Godot's [shader owner](https://github.com/godotengine/godot/blob/4.7.2-stable/drivers/gles3/shader_gles3.cpp#L323)
calls the status reads immediately after compile/link, so a host wait in the
query must not be missed. Its [texture owner](https://github.com/godotengine/godot/blob/4.7.2-stable/drivers/gles3/storage/texture_storage.cpp#L2051)
contains both ordinary and compressed upload paths. `bufferData` is deliberately
excluded: the [canvas renderer](https://github.com/godotengine/godot/blob/4.7.2-stable/drivers/gles3/rasterizer_canvas_gles3.cpp#L377)
updates a STREAM_DRAW uniform buffer during rendering. This is not a low-frequency
call. All buffer, draw, binding, uniform and state methods remain unchanged;
there is no general `getParameter`/`getError` interception.
Primary-source content hashes and exact links are in `source-bindings.json`.

## Forwarding and measurement

`resources.js` executes immediately after the byte-identical `observer.js` in
one init script, fixing getContext wrapper order. It observes only the actual
`canvas` context and requires that it is the identical single context recorded
by the established observer. A second context or method replacement fails the
diagnostic. No game command is exposed or injected.

Every wrapper forwards exactly once with `Reflect.apply(original, this, arguments)`.
Arguments, receiver, result and thrown exception are preserved. The diagnostic
issues no additional GL call, readback, finish, flush, error clear or state change.
Original own-property descriptors are retained and restored; inherited methods
return to having no own property. Failed installation rolls back the attempted
method changes and blocks timing, while returning the original getContext result.

The 8,192-record capacity is allocated at initialization. Each selected timed call
adds two `performance.now()` reads and fixed numeric writes. Counts, method ID,
start/end timestamps and success flag are retained, including nested calls. There
is no explicit array/string allocation, stack capture or logging inside a timed
wrapper. Original calls continue if capacity is exhausted, but any drop rejects
the diagnostic. Untimed calls update only counters; nonselected status queries
take only the forwarding branch. These hooks and the unchanged loop observer
still add overhead and can affect scheduling or first-use behavior.

Startup must exercise texture, shader and status hooks before timing. It provides
non-vacuity evidence without pre-mining or warming later gameplay effects. A valid
window may have zero selected calls. The raw observer starts its usual one-minute
measurement; the resource recorder stops in the promise continuation after its
last callback, before export/conversion of records. All JSON conversion, analysis,
file writes and screenshots occur outside the raw timed window.

Both recorders use the same window's monotonic `performance.now()`. Before/after
receipts retain `timeOrigin`; their order must enclose every raw callback and
resource span. There is no engine-clock conversion. Raw values are kept without
artificial precision or a claimed statistical confidence interval. Analysis
clips selected spans to callback boundaries and uses interval unions, including
nesting; per-method totals are inclusive and must not be added as exclusive cost.
Time outside selected calls remains explicitly **unattributed**.

## Route, gates and cleanup

The corrected NEW GAME → visible surface → DEV drawer → ENDLESS LAYER 12 route,
its two-original OCR confirmations and persisted-state checks are copied from
the completed phase run. Navigation helpers, route and final save/mechanics
blocks are hash-checked against that version. The small drawer drags are untimed
DOM TouchEvents and explicitly untrusted; the taps and held ArrowDown+Space
mining input use the existing trusted Playwright path.

The raw observer is unchanged at SHA256
`35db05eed667a6b95ec235d2b0673ea2ddf48cf7ccfa84ef193ed04ba0bf4424`.
It reports engine-loop callback cadence, **not presented FPS**. The actual canvas
remains 1696×780 with the same loadout, seed-preservation and normal visual/effect
settings. The untimed draw census still requires real draw calls and restores
its methods before timing. The new hooks never wrap draws during timing.

Success requires the ordinary-user Mac branch, first workflow attempt, one-session
request immediately descended from its reviewed preparation, exact artifact and
source identities, real 60-second raw window, zero drops/errors, held trusted input,
no hidden/blur/resize/context interruption, mining/descent/save progression,
release of keys, descriptor restoration and clean browser-process exit. Resource
getContext is restored to the observer's wrapper first; the observer then restores
native getContext and requestAnimationFrame. The explicit completion marker is
required in the closed log. Failure evidence is retained and no retry is automatic.

The report keeps raw resource spans, all raw callbacks, time receipts, inclusive
per-method counts/durations, callback overlap unions, every >100 ms callback or
interval, screenshots, navigation/input receipts, saves, process identities,
closed-file hashes, console errors and cleanup results. Full raw data supports
other post-run thresholds without another measurement. No CPU sampler or
exclusive GPU timer is part of this probe.

## Preparation checks and review boundary

```sh
python3 tools/webkit_resource_probe/prepare.py --candidate /path/to/original/candidate
node tools/webkit_resource_probe/check.mjs
node tools/webkit_resource_probe/check-resources.mjs
node --check tools/webkit_resource_probe/run.mjs
node --check tools/webkit_resource_probe/resources.js
```

These read-only/mock checks cover the exact candidate, source/route binding,
forwarding once with identical objects and receiver, return/exception identity,
unselected-status forwarding, inherited and own descriptors, installation failure,
second-context rejection, capacity overflow without dropping game calls, nested
spans, zero-call observations, clock/counter failures and the full simulated
observer/census/start/stop/restoration lifecycle. They do not constitute an actual
WebKit or graphical pass.

After independent review of the pinned preparation, the authorized single session
is triggered only by adding `REQUEST.json` on
`codex/dev11-webkit-resource-probe-20260917`. Required fields are `sessions: 1`,
the exact production `source`, `diagnostic_only: true`,
`probe: "selected_webgl_resources_v1"`, and the reviewed `preparation_sha`.
The request also records the parent agent's authorization and independent review.
No request was included in preparation `667b293f`; root independently verified the
request-only child before advancing its branch to launch the completed session.
