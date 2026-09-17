# Proposal only: time selected synchronous WebGL resource calls

The completed phase probe excludes the three synchronous generation/rebase/save
bodies as the direct source of its three large callbacks. It does not identify
the remaining owner. The smallest next positive discriminator is one bounded
measurement of selected WebGL texture/shader host calls during the established
real moving route. No implementation, request or run of this proposal exists.

Use the **unchanged original DEV11 exported package**, source `8f5680d`, PCK SHA256
`5b77b3a219011cb676895e41830c8dab32bec2346db93102c7894a3c084414e9`, retained
QA run 35186932201 / artifact 10481858878. Verify its original identity and all nine
files. No new Godot build, driver flags, effect changes or gameplay commands are
needed. Use the corrected real NEW GAME / DEV / Layer 12 navigation, trusted Down+Space
and the byte-identical 60-second raw engine-loop observer on the existing Mac runner.

## Why these calls, and why not every buffer update

The exact shipped `index.js` (SHA256
`33c94cb3175f3333b82e2a3be5e8e86f77986f0aa2042b1631f6367a4e5bb6ba`) directly
dispatches Emscripten GL operations through the actual `GLctx` methods. The public
Godot 4.7.2 source shows shader compilation immediately followed by status reads,
and program linking immediately followed by link-status reads. Measuring only
`compileShader`/`linkProgram` could miss a wait inside their status queries.
[Shader owner, lines 323–325 and 427–429](https://github.com/godotengine/godot/blob/4.7.2-stable/drivers/gles3/shader_gles3.cpp#L323).

Texture upload branches choose compressed or ordinary texture-image methods;
omitting compressed uploads would leave a known gap for compressed resources.
[Texture owner, lines 2051–2073](https://github.com/godotengine/godot/blob/4.7.2-stable/drivers/gles3/storage/texture_storage.cpp#L2051).

Do **not** classify every `bufferData` call as low frequency. Godot calls it for
the canvas state uniform buffer with STREAM_DRAW in the rendering path.
[Canvas owner, line 377](https://github.com/godotengine/godot/blob/4.7.2-stable/drivers/gles3/rasterizer_canvas_gles3.cpp#L377).
This first probe should therefore omit bufferData, bufferSubData, all draw calls,
uniform/state/bind calls and general getParameter/getError calls. Source bindings
and the shipped JS hash are recorded in `next-source-bindings.json`.

## Narrow measurement contract

Wrap only the actual game canvas context's `texImage2D`,
`compressedTexImage2D`, `texStorage2D`, `compileShader`,
`linkProgram`, `getShaderParameter` for COMPILE_STATUS, and `getProgramParameter`
for LINK_STATUS. This intentionally does not cover texture arrays/3D uploads,
mipmap generation, draws or every possible synchronous WebGL call. All seven
selected methods have direct dispatches in the retained shipped JS. It contains
no `texSubImage2D` or `compressedTexSubImage2D` names; these are omitted from this
first proposal instead of installing inactive hooks without an observed caller.

Each wrapper calls the original function exactly once with `Reflect.apply`,
the unchanged receiver and original `arguments`, and returns the exact result
or propagates the original exception. It must not copy texture/shader data,
reorder calls, change bindings, clear errors, flush/finish the context, cache
resources or issue any extra GL command. Test receiver/argument identity,
return/exception propagation and descriptor restoration with a fake context.

Only two `performance.now()` reads and numeric buffer writes are added around
selected calls while active. Preallocate 8,192 records outside timing with method
ID/start/end/success flag and fixed per-method counters; cap and report drops.
No stack collection, strings, JSON, file IO or data copies occur in timed wrappers.
Actual counts are retained; overflow invalidates the probe while original calls
continue normally. These observations include instrumentation overhead and are
not an FPS optimization benchmark.

Install wrappers when the real canvas context is returned during normal startup.
Retain untimed startup call counts to prove the hooks actually see texture/shader
work. Do not warm new effects or introduce a movement preflight: that could
consume the first-use hitch being investigated. Zero selected calls during the
actual window is a valid negative observation if the startup and restoration
proofs pass. Keep the normal untimed draw census before/after and require its
methods to be restored before timing. Restore context method descriptors and
the extra getContext wrapper in reverse order, before restoring the original
observer's getContext wrapper; prove every original method identity.

Both call spans and the unchanged raw observer use the same window's monotonic
`performance.now()` clock. Record its timeOrigin and outside-window calibration
receipts; no JS↔Godot clock conversion or timed bridge call is needed. Preserve
every raw interval and selected-call duration. Associate call spans with raw
callbacks by time overlap and take interval unions if any spans nest. Retain
unmatched callback time explicitly.

Require the same source/package, route, two-image OCR, saved depth 12 entry,
held trusted input, real 60-second duration, draw evidence, mining/depth/save,
visibility/error, successful exit and exact completion-marker gates. Save all
failed attempts and raw originals. One measured session after reviewed checkpoint;
no automatic second run, broad profiler or alternate renderer if it is inconclusive.

## What would resolve the question

A recurring long callback mostly covered by one of these host-call spans would
attribute that portion to that **synchronous WebGL operation's wall time**. It
could include browser validation, driver compilation, allocation/copy or waits;
it is not exclusive GPU execution time and does not identify GC or a particular
driver routine. A status-query wait would count where it is actually observed.

If the hitch recurs outside these spans, this narrow resource/shader hypothesis
is not supported for that event. The remainder must stay labelled **outside the
selected calls**, not simulation time: rendering, unwrapped draw calls and other
engine work remain there. A complete simulation-versus-render partition would
need a separately reviewed pre/post-draw boundary probe. No new hitch in the
fresh random run is inconclusive. Current evidence supports this bounded
diagnostic only, not a game optimization or stable 50 FPS claim.
