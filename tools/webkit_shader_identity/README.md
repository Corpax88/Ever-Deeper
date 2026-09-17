# Bounded WebKit shader/program identity diagnostic

Prepared for independent review only. There is no `REQUEST.json`, browser run,
Godot rebuild, production change, warm-up implementation or publisher in this
preparation. The parent agent must review and gate a request before a session.

## Evidence and specific question

Completed resource run [35225485863](https://github.com/Corpax88/Ever-Deeper/actions/runs/35225485863)
observed two synchronous `getProgramParameter(program, LINK_STATUS)` calls lasting
449.70 ms and 260.02 ms. Its selected host-call unions occupied 467.62 ms and
269.50 ms of the respective 557.54 ms and 305.48 ms callbacks. A third 264.00 ms
callback had no selected-call overlap and remains unattributed. The original
measurement did not capture program identity or GLSL, so no material, variant,
repeat compilation or warm-up target was identified. The closed report remains
at `1069698e7889bc2859f650213904f6911897f380` on the resource-study branch.

This extension asks which original shader texts and shader/program objects are
associated with any observed status wait, and whether equivalent source pairs
or the same program object recur. It does not assign a material from a guess,
implement warm-up, or measure a performance improvement. A fresh random route
without a comparable status wait can be inconclusive. The third hitch and all
unwrapped time remain unattributed.

## Exact package and retained harness

Use original DEV11 source `8f5680defb9083bbe1e044d39a10612f2186e7f3`, candidate
run `35186932201`, artifact `10481858878`. The identity-file SHA256 is
`027b128fe5fa70d7814c0f0952ee06549f447afc9769426c3b5696c631579a7a`; the PCK SHA256
is `5b77b3a219011cb676895e41830c8dab32bec2346db93102c7894a3c084414e9`.
`package-pins.json` retains all nine exact sizes/hashes and the production tree
binding. The workflow reuses the original artifact; it does not export the game.

The preparation starts from resource preparation
`667b293f240fe350e7530586c531549d46310926`. `observer.js`, `resources.mjs`,
`codec.mjs`, `check.mjs`, `ocr.swift` and `package-pins.json` are byte-identical.
Navigation helpers, NEW GAME → surface → DEV drawer → ENDLESS LAYER 12 route,
save/mechanics block, and raw measurement block are hash-bound. The observer is
still SHA256 `35db05eed667a6b95ec235d2b0673ea2ddf48cf7ccfa84ef193ed04ba0bf4424`.
It reports engine-loop callback cadence, not presented or physical-device FPS.

## Narrow hook contract

The same seven methods retain their selected host-call timers: `texImage2D`,
`compressedTexImage2D`, `texStorage2D`, `compileShader`, `linkProgram`,
`getShaderParameter(COMPILE_STATUS)` and `getProgramParameter(LINK_STATUS)`.
Only `shaderSource` and `attachShader` gain metadata wrappers. The other status
queries are forwarded without timing or identity work. No draw, buffer, state,
texture-identity, shader-type, info-log, completion query, readback, flush or
finish hook is added. No extra GL call or query is issued.

The exact shipped `index.js` dispatches both new methods with original opaque
objects; `GL.getSource` constructs a JavaScript string. `prepare.py` checks those
exact dispatch bodies and the absence of `detachShader`. Consequently replay can
follow the two attached shaders without an unobserved detach dispatch. A changed
export cannot pass these assumptions. Existing absent `texSubImage2D` and
`compressedTexSubImage2D` checks remain: these two names are not in the shipped
dispatch, while the same seven measured methods are present.

Every original method executes exactly once with its original receiver,
arguments, return value and exception. Metadata is recorded after forwarding.
The original seven timers retain the same two `performance.now()` boundaries;
identity writes happen after their end timestamp. Metadata-only hooks add no
clock reads. Non-string source arguments are forwarded without instrumentation
coercion and then reject the diagnostic. Unexpected metadata errors are latched
without replacing the original return/exception or dropping the original call.

Two WeakMaps assign dense local IDs to original shader/program objects. They
do not retain those opaque objects strongly. Numeric event arrays and source
reference slots are allocated before game startup. The original immutable GLSL
strings are retained by reference; no source copy, hash, regular expression,
JSON conversion or logging runs in the hooks. WeakMap insertion can allocate,
and retaining strings changes memory lifetime, so this probe has additional
overhead and can affect scheduling or GC. It is not an overhead-free control.

| Bounded storage | Limit |
|---|---:|
| Original selected host-call spans | 8,192 |
| Shader IDs | 1,024 |
| Program IDs | 512 |
| Source versions | 1,024 |
| Association events, including startup | 8,192 |
| One source string | 262,144 UTF-16 code units |
| All retained source versions | 16,777,216 UTF-16 code units |

The previous run observed 86 startup plus four timed compile calls and 43 startup
plus two timed link calls. The identity limits leave room above those observed
call counts, but source volume was not previously measured. Any capacity breach,
missing association, unsupported argument or restoration error rejects the new
diagnostic. Original game calls continue. There is no automatic retry with a
larger limit. The total source limit counts every captured version, even repeated
references to an identical string; it bounds retained code units, not total VM
or serialized-JSON bytes.

## Associations and post-window interpretation

Raw events encode source assignment, compile, attach, link, selected shader
status and selected program status. IDs and event sequence are local to this
page. `source` and `attach` events have no added timestamps; selected timed rows
point to their precise association event. Startup counts establish the boundary
between pre-window and active records. `stop()` freezes all identity tracking
before capture/serialization or the later untimed draw census.

`identity.mjs` runs in Node after the raw window. It replays original source
versions and compile history, then snapshots each program's two attached,
compiled shader versions at its original link. A later source assignment without
compile cannot retroactively change that snapshot. Each selected status query is
bound to its shader's compiled version or program's latest original link.
Missing history fails rather than guessing. Different objects with identical
source pairs are distinguished from a relink of the same program object.

Full original GLSL remains in `resource-capture.json`. Post-window analysis hashes
UTF-8 and UTF-16LE representations; the latter preserves original code units,
including unusual surrogate sequences. It extracts raw `#define`/`#undef` lines
without claiming all conditional branches are active. Stage/type is not queried;
a material or resolved specialization is not inferred automatically. The output
provides stable source hashes and original text for a later source-owner review.

Godot's [shader implementation](https://github.com/godotengine/godot/blob/4.7.2-stable/drivers/gles3/shader_gles3.cpp#L307)
compiles source, attaches shaders, links, then queries status. The
[missing-specialization path](https://github.com/godotengine/godot/blob/4.7.2-stable/drivers/gles3/shader_gles3.h#L183)
can invoke this synchronously. Those call sites motivated collecting identity;
they do not prove which game material caused the observed waits. Primary-source
and exact dispatch bindings are in `source-bindings.json`.

## Session gates and evidence

The established actual 60-second route, 1696×780 canvas, normal effects/loadout,
trusted taps and held ArrowDown+Space mining remain. Untimed drawer drags remain
explicitly disclosed untrusted DOM TouchEvents. Before/after actual draw censuses
restore their methods before timing. Seed preservation, real mining/descent,
persisted save checks, visibility and input-release gates remain unchanged.

Only one actual game WebGL context is allowed. Nine method descriptors now must
restore exactly, then the resource getContext wrapper restores to the unchanged
observer, which restores native getContext and requestAnimationFrame. The raw
clock receipts, span/count/drop checks, nested-span unions and callback data are
unchanged. New association work appears in overall callback duration but is
outside the existing selected host-call spans. Any remaining wall time is
unattributed, not a measurement of simulation, compilation, GC or exclusive GPU
time. Means do not establish stable minimum 50 FPS.

The workflow retains raw callbacks, selected spans, full source/events, derived
identities, clock receipts, screenshots, OCR/input receipts, saves, process and
source/package identities, errors, restoration, exit and closed hashes. No CPU
sampler or renderer switch is added. Success requires one explicit
`WEBKIT_SHADER_IDENTITY_COMPLETE` marker and a clean browser exit. Failures are
retained. No second measured run is automatic.

## Preparation and review boundary

```sh
python3 tools/webkit_shader_identity/prepare.py --candidate /path/to/original/candidate
node tools/webkit_shader_identity/check.mjs
node tools/webkit_shader_identity/check-resources.mjs
node tools/webkit_shader_identity/check-identity.mjs
node --check tools/webkit_shader_identity/run.mjs
node --check tools/webkit_shader_identity/resources.js
```

These source/mock checks cover unchanged package/route/observer/timed block,
forwarding once, receiver/argument/result/exception identity, all-nine descriptor
restoration, rollback, unselected queries, zero selected calls, clock unions,
nested spans, bounded overflow with continued original calls, metadata freezing,
source reassignment/recompile/relink, equivalent fresh programs, non-string
coercion once and malformed/missing association rejection. They are preparation
evidence, not a real WebKit, graphical or timing pass.

After independent review, only a newly added `tools/webkit_shader_identity/REQUEST.json`
may descend directly from the reviewed preparation on
`codex/dev11-webkit-shader-identity-20260917`. The parent agent must verify the
request-only diff before advancing its ref. The runner also verifies `HEAD^`
equals `preparation_sha` and the commit changes exactly that added request file.
Required fields include `sessions: 1`, exact production `source`,
`diagnostic_only: true`, `probe: "selected_webgl_shader_identity_v1"`, reviewed
`preparation_sha`, explicit authorization and the independent review binding.
The branch-specific workflow accepts only attempt 1. No request is included now.
