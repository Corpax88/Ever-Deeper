# Unchanged DEV11: bounded Mac CPU stack preparation

The one authorized session has now completed and its raw artifact has been
independently verified. See [RESULTS.md](RESULTS.md) for the exact run, measured
ANGLE/Metal wait path, profiler overhead and limits. The preparation description
below records the reviewed launch design; it is not authorization to rerun it.

This is a diagnostic preparation, not an optimization, completed profile or FPS
approval. No production source, shader, asset, light, gameplay input policy or
published package changes. The approved native v28 hero remains intact.

## Exact scope

- Runtime source: `8f5680defb9083bbe1e044d39a10612f2186e7f3`.
- Published DEV11 PCK: 221,013,680 bytes,
  `5b77b3a219011cb676895e41830c8dab32bec2346db93102c7894a3c084414e9`.
- Download the existing candidate artifact from QA run `35186932201`; do not
  export/rebuild it. Its complete artifact identity must hash to
  `027b128fe5fa70d7814c0f0952ee06549f447afc9769426c3b5696c631579a7a`.
- Godot 4.7.2 official universal Mac engine, `gl_compatibility`, 1696×780 actual
  framebuffer, normal real-time clocks, Dummy audio as in prior sessions.
- Exactly one 60-second Deep `held_mining_v1` session, seed 4608, depth-12 entry,
  normal companion, autosaves and real mining. No movement/physics shortcuts.
- Exactly one `/usr/bin/sample PID 10 5 -file sample.txt`, beginning 15 seconds
  after the route-ready receipt. All threads are sampled for ten seconds at a
  requested 5-ms interval. No second trial, no alternate sampling tool.

The exact established route is `tools/review_premium_session.gd`, SHA256
`c3a787767ff0dbfc5c13b2d9283ce0ae7b5a1a77d287a1a5c5e49512ef5b9edb`.
`run.py` verifies it before generating a separate external script. Additions are
boundary receipts, raw chronological frame-array copies at existing window
boundaries, and a stderr mirror at the original final completion point. The
timed input loop and production scripts are retained. All original route code
and the generated script accompany the evidence for direct comparison.

## Review and launch boundary

Branch: `codex/dev11-mac-cpu-sampling-20260917`. The workflow can run only there.
The preparation checkpoint contains **no `REQUEST.json`**; ordinary changes to
these prepared files do not trigger the workflow. After reviewing/checkpointing
the preparation, root can trigger the one authorized session by adding
`tools/mac_cpu_sampling/REQUEST.json` with a short record of that authorization.
The workflow also declares manual dispatch. No run has been triggered locally.

The existing Mac display setup uses only advertised desktop modes. The PCK runs
from an empty directory with an external harness, without importing source or
loading source resources as a substitute for the package. This is a fresh
GitHub-hosted Mac; the route supplies its isolated save path before creating
Main. Initial engine user-data location is recorded, and no HOME override is
used. Caches outside the evidence directory are not uploaded.

## Capability and success gates

The current [official macOS-15 runner inventory](https://github.com/actions/runner-images/blob/main/images/macos/macos-15-Readme.md)
lists Xcode/command-line tools, but does not prove that this runner allows
sampling this binary. Runtime preflight therefore records the actual installed
`sample` usage and confirms duration/interval/output syntax before launch. It
also verifies ordinary `/usr/bin/time -l` and records `xcrun --find xctrace` only
as availability information. **xctrace is not used.** No sudo, privilege change,
debug entitlement change, service, remote debugger or alternative attach path.
If sampling is denied or unsupported, preserve the failure and stop.

The actual `Popen` child PID is bound to in-engine receipts, process listings
before/after sampling, and the raw sample's Process header. Record real sampling
start/end timestamps and require the invocation to finish within the moving
route. Raw call graph, binary-image list, tool stdout/stderr and `/usr/bin/time
-l` resource report are retained. A sampler timeout is failure.

Successful engine exit, no runtime/parse errors, explicit functional completion
marker, source/PCK/harness identity, real elapsed 60 seconds, all chronological
frame samples, correct framebuffer/renderer, movement, mining, persisted save,
zero orphan nodes and released mining input are required. The original route's
performance threshold remains reported but is not an attribution success gate.
Every early failure retains its partial files, diagnostic receipt and manifest.

## Interpretation limits

`sample` records stack occupancy, including blocked and sleeping threads. Stack
counts are not exclusive CPU milliseconds; totals across nested frames or
threads must not be summed as frame cost. Inspect the main thread and any
actually observed render/driver thread by their names/stacks; do not assume that
this engine configuration has a separate render thread. The effective thread
setting is recorded, not changed. Semaphore or driver waits do not by themselves
identify a GPU bottleneck, VSync, or a particular expensive draw pass.

The released engine may lack detailed symbols; raw addresses and binary images
must remain. Named driver functions may still identify submission/wait activity,
but generic Godot interpreter frames do not identify individual GDScript owners.
If symbols/stacks cannot answer the CPU attribution question, report that exact
limit. No GPU duration comes from this sampler. The previous Mac GPU timestamps
were unsupported, and this diagnostic does not repair them.

The sampler's CPU/resource usage and wall time are retained, as are frame times
covering before/during/after it. Sampling and later symbolication perturb the
session. One run has no unsampled control; any apparent FPS difference cannot
be assigned to sampler overhead, corrected away, or treated as a speed gain.
This is virtual-Mac native execution, not Safari or physical-iPhone acceptance.

## Local preparation check

`--prepare-only` binds the actual PCK/identity and generates the harness without
launching the game or a sampler. Use the exact Godot binary with `--headless
--main-pack PCK --script GENERATED --check-only` from an empty directory to
validate GDScript syntax. These checks cannot establish macOS sampling access,
symbol quality or graphical correctness. No local renderer is used.

Preparation validation on 17 September 2026: the generator binds the retained
published PCK and artifact identity; the generated GDScript passes Godot 4.7.2
`--headless --check-only` with exit 0. The timed input-loop text is byte-identical
to the pinned route. Python compilation and workflow YAML parsing pass. Twelve
synthetic failure cases reject missing completion, runtime errors, wrong PID or
PCK, unreleased mining, insufficient real duration, an out-of-route sampler,
missing raw samples, wrong framebuffer, software renderer, stalled movement and
false functional completion. An incorrect raw-sample PID is also rejected;
anonymous engine frames stay explicitly unresolved. These are parser/gate checks,
not a claim that a Mac sampling run or graphical session has occurred.
