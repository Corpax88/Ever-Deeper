# Completed actual WebKit baseline: cadence passes, intermittent stalls remain

[Actions 35207448460](https://github.com/Corpax88/Ever-Deeper/actions/runs/35207448460),
job 105156583550, attempt 1, succeeded. Preparation 6f4e6849515c949e3f0b675a871930ef7b5c163b
and request 108b5196a9311cf41f1e6088e82ed79e92c31d2e were independently tree/ref verified.
The exact unchanged DEV11 source is 8f5680defb9083bbe1e044d39a10612f2186e7f3; PCK SHA256
5b77b3a219011cb676895e41830c8dab32bec2346db93102c7894a3c084414e9. All nine original
exported files passed their pinned identity checks. No gameplay, assets, effects,
renderer settings or package bytes changed. Playwright 1.62.0 ran WebKit 26.5 revision 2336
on an ordinary UID 501 ARM64 macOS 15.7.9 runner, headless with mobile viewport emulation.
The actual canvas/backbuffer was 1696×780, CSS 848×390/DPR 2. This is not a physical iPhone.
The current display inventory was empty; no specific GPU model is inferred.

| Retained interval span | Intervals | Mean cadence | p95 | p99 | Maximum |
| --- | ---: | ---: | ---: | ---: | ---: |
| Full 60.01378 seconds | 3546 | 59.086 Hz | 18.60 ms | 20.58 ms | 440.00 ms |
| First 30-second window | 1772 | 59.072 Hz | 18.80 ms | 21.00 ms | 440.00 ms |
| Second 30-second window | 1773 | 59.100 Hz | 17.90 ms | 20.46 ms | 280.40 ms |

There are 3547 raw callback records. The last interval crosses the exact 60-second
window edge, so it is included in the full record but not either closed 30-second bin.
Both window callback budgets pass. No warm-up or hitch samples were removed. These
are MainLoop_runner start intervals, not engine-render counters or presented FPS.
The selected callback can skip an iteration; pre/post actual draw evidence cannot
prove every timed callback rendered. A 59 Hz mean with a 440 ms stall does not certify
a sustained minimum 50 FPS. Conditional CPU sampling did not run because the configured
mean/p95 callback budget passed; no browser CPU-stack or exclusive GPU attribution
is claimed from this run.

| Strict interval threshold | Count out of 3546 |
| --- | ---: |
| >20 ms | 38 |
| >33.3 ms | 6 |
| >50 ms | 3 |
| >100 ms | 3 |

The three long intervals are retained in full:

| Relative interval start→end | Interval | Previous synchronous callback | Gap after that callback |
| --- | ---: | ---: | ---: |
| 0.82986→1.26986 s | 440.00 ms | 370.66 ms | 69.34 ms |
| 44.98320→45.18548 s | 202.28 ms | 196.54 ms | 5.74 ms |
| 46.04534→46.32574 s | 280.40 ms | 232.12 ms | 48.28 ms |

The first is early in actual movement, not at the observer's start/stop boundary.
The later pair clusters about 1.14 seconds apart mid-window; none occurs at completion.
Synchronous callback wall time has mean 9.223 ms, median 9.080 ms, p95=12.000 ms,
p99=12.340 ms and max 370.660 ms. It includes CPU work and synchronous waits; it is not
exclusive CPU utilization or GPU time. Observer forwarding, console reception and
timestamp storage have uncalibrated overhead. Of 3547 callbacks, 16 exceeded16.667ms,
11 exceeded20ms and3 exceeded50ms. Summed callback wall time is32.71552s, or54.51%
of the first-to-last-start interval span; that bookkeeping ratio is not CPU utilization.
No draw wrappers, screenshots, OCR,
save reads, profiling or percentile calculation ran in the measured window. The
ordinary game emitted unsupported-vibration notices while mining; all are retained.

Depth/biome attribution is unavailable: the record has pre/post depth 12→22 and saved
chunks 12–22, but no time-stamped transitions during the window. Source confirms that
_update_stream_depth() can synchronously rebase and regenerate the stream window;
RunState separately schedules normal saves with AUTOSAVE_BATCH_SECONDS=6.0. Neither
path is timestamped here. Similar cadence cannot distinguish generation, autosave,
first-use effects, browser work or driver waits. No causal transition/biome claim is
made. Relevant unchanged owners are scripts/world/endless_descent_world.gd and
scripts/state/run_state.gd at the pinned source above.

The specific remaining risk is intermittent 200–440 ms stalls during actual WebKit
movement/mining. Most of each long interval lies inside a synchronous game callback,
but its stack/cause is unknown. If performance work continues, it should first locate
those callback stalls with event/stack correlation, rather than assume a sustained
draw-throughput failure or reuse the native-only bounded-ANGLE-pool result. This
evidence alone does not justify a new rendering optimization or another timing run.

Root authorized a separate, explicitly diagnostic build after closing this baseline.
The chosen attribution probe records bounded preallocated spans around only real
_generate_stream_window(), _rebase_stream_window() and RunState.save_game() calls.
It will retain ticks, frame/depth/window identity, results, a record cap/drop counter,
and paired engine/browser clocks outside timing. The unchanged raw observer can
then match long callbacks to spans, accounting for nested generation inside rebase
without double counting. It changes no workload, input, visuals or quality settings.
Timings will be labelled as carrying diagnostic overhead; unspanned stalls remain
unattributed engine/browser/render work. This is an attribution test, not an adopted
optimization. No diagnostic result exists at this baseline-report checkpoint.

Normal UI preparation is fully evidenced: NEW GAME→Surface save→visible DEV drawer,
three untimed DOM touch drags (explicitly untrusted), exact Layer 12 text at confidence
0.5 in two settled originals with identical coordinates, then a trusted ordinary tap.
The menu closed and saved scene=endless/current_depth=12/active=true was verified.
Real trusted ArrowDown and Space events were held throughout the 60-second interval,
then released. Before/after checked EVDR saves have unchanged seed 2421325703 and show
+4092 mined, +57 swings, depth 12→22 and 493→942 metres, with stream anchors advancing 11→21.
Save progress brackets a slightly longer period than timing (pre/post checks and
settling); those totals are mechanical proof, not exactly-per-window production rates.
The standard/miner/original presentation was verified at entry. Actual untimed WebGL
draw checks counted 311 before and 410 after, each restored immediately. Original
entry/final images were inspected at 1696×780. All raw browser/input/scene/error and
restoration gates passed, the explicit COMPLETE marker appeared once, and browser
process 15762 exited 0 without a signal. No game or GL errors occurred.

Untouched success ZIP: 18,582,210 bytes, SHA256
fa5ccc0bd508144cdb533b098077832c003dca5a7edef9a3169c0dff6e415ac8.
Every ZIP CRC and 46 closed-file hashes passed, followed by independent source, input,
raw interval, draw-restoration and save-delta review. Raw 3547 records, all 38 intervals
over 20 ms, original 9 PNGs, original three saves, metadata and the chronological plot
are preserved. The four failed attempts below remain separately archived.

Closed success archive: Ever-Deeper-DEV11-WebKit-moving-baseline-20260917.tar.gz,
18,780,608 bytes, SHA256 a6071599ed575d962be8c63fb0e4e385fe2cf63b136792931f647b4d2f5131dd.
All 13 archive members were reverified against their manifest before persistent saving.
Archive Library ID: libfile_5aac5ceea2d88191b9a4f3f43c34404f. The inspected chronological
cadence-and-stalls.png is also saved as libfile_48a070915fe481918a01390dcc8b77dc.
The archive retains the untouched raw ZIP, original receipts and hashes, review.json,
all 38 slow intervals in CSV, plot, remote APIs/logs and verified preparation/request
receipts. Git-backed tested tools and the already pinned exported package are omitted.

# Preserved first navigation failure

One run was triggered at request a1225db9628e06122059d7be7453c6bc05ec2386:
[Actions 35203072075](https://github.com/Corpax88/Ever-Deeper/actions/runs/35203072075),
job105142222494, attempt1. All nine exported files and unchanged runtime tree passed.
WebKit26.5 revision2336 started on ordinary UID501, ARM64 macOS15.7.9. The single
actual canvas was1696×780 at CSS848×390/DPR2. No game or GL errors were recorded.

The harness failed before any timed window, mining key-down or CPU sampler:
\`mouse.wheel: Mouse wheel is not supported in mobile WebKit\`.
This is explicitly rejected by Playwright1.62.0 wkInput.ts. Browser exit was0.
The failure completion marker was present; the success marker was absent.

There is a second important failed precondition: the original start and post-DEV-tap
images are pixel-identical (zero changed RGB pixels). The visible drawer never
opened. OCR normalization gave image center approximately94×50px, correctly mapping
to CSS47×25 inside the visible button. The old harness did not record tap DOM events
and omitted the working capture-web.mjs focus/blur/focus sequence, so a precise
causal claim about the ineffective tap is unsupported.

The authorized correction aligns bringToFront, canvas focus/blur/focus and integer
CSS tap coordinates with that existing harness, records actual DOM/visual viewport,
hit target, focus and trusted touch receipts, and requires the visible DEVELOPER TOOLS
title plus CLOSE DEV button before any deeper navigation. Untimed scrolling reuses
capture-web.mjs's frame-spaced DOM TouchEvents, explicitly marked untrusted; ordinary
Playwright trusted taps and mining keys remain required. No game method is called.
Original successive drawer and Deep-entry frames plus the persisted depth12 save
must pass before timing. The raw loop observer/codec/timing contract is unchanged.
This is a bounded correction attempt, not a demonstrated tap-root-cause fix.
An unexplained failure stops that retry; no automatic further attempt was authorized.

The untouched raw ZIP is713174 bytes, SHA256
7b27bcafaeb99d8db80aa26dc2d555f3240540430a01c0f4089d16021392ee2b.
Every ZIP CRC and all22 closed-file manifest hashes passed. Failure archive:
Ever-Deeper-DEV11-WebKit-navigation-failure-20260917.tar.gz,725425 bytes,
SHA256 fa7a000e7daa3a5daa2f8189caaa393010992d973c4ff347308397b8320579cb.
It is saved as Library libfile_d77ddcfdee5c8191bd7fa754d7f42674.

There are no current Deep browser timing or attribution results from this run.
The native Godot ANGLE bounded-pool wait remains inapplicable as browser evidence.

# Preserved second navigation failure and explained modal ownership

[Actions 35204165281](https://github.com/Corpax88/Ever-Deeper/actions/runs/35204165281)
ran request b241e61a232687c68e336f3ff17ab209a1aa8804, job105145772399, attempt1.
All package and runtime identity gates passed. The new drawer guard stopped before
scrolling, timing, mining key-down, draw census or sampling: the DEV drawer/title
was not visually established. Browser exit was0; no game or GL errors occurred.

The retained receipt proves a trusted touchstart and touchend on the focused canvas
at CSS47,25. Actual viewport848x390, DPR2, canvas848x390CSS and screenshot1696x780
all agree, and the original start/post-tap images again have zero changed RGB pixels.
The page-init observer counted362 MainLoop_runner callbacks; its timed partial is
null. It was installed during navigation, not absent; these calls do not measure FPS.

Source inspection explains the blocked control. At exact source8f5680d,
scripts/ui/premium_menu.gd sets a full-rect MOUSE_FILTER_STOP and open_menu() calls
move_to_front(), explicitly because GUI picking follows sibling order, not z_index.
The visible DeveloperMenu has z_index190 while PremiumMenu has100, so visual order
does not give its standard Button input ownership over the active start modal.
The project has no emulate_mouse_from_touch override; Godot4.7.2 main.cpp defines
that setting true (Git blob2fc62fdc54303e51951a69317055aa2982f3f945;
[primary source](https://github.com/godotengine/godot/blob/4.7.2-stable/main/main.cpp)).
The DEV Button connects pressed to toggle_menu; no special touch handler is required.

For a fresh save, _request_new_game() calls _start_new_game() directly, closes the
modal, activates Surface and flushes its save. QuickTutorial is input-transparent.
Root explicitly authorized one corrected run after checkpointing this ordinary
NEW GAME-first route. It requires visible fresh-menu evidence, disappearance of
start-menu labels, the visible DEV toggle, committed scene=surface with endless
inactive, and loop advancement before the unchanged drawer/Deep12/input/save gates.
It does not change the package, observer, codec, timed window or sampler. Any new
unexplained failure stops the attempt; no automatic rerun is authorized.

Second untouched raw ZIP:714259 bytes, SHA256
8e2ffb3b82d7d82a4cd30e4649a9f1f71838cbced959fcd3cea1659f0735bbc6.
All ZIP CRCs and22 closed-file hashes passed. Durable bundle:
Ever-Deeper-DEV11-WebKit-modal-navigation-failure-20260917.tar.gz,724882 bytes,
SHA256 1ead7e21eb1f7711f74e0567e00eb1f782573b4e563aad646d792e1c307ff63b,
Library libfile_0f3c9cc494a081918537c8825c642207. It retains untouched ZIP, APIs,
job log, download verification, image comparison, source review and file manifest.

Neither failed run establishes sustained Deep browser cadence or a browser bottleneck.

# Preserved third failure: scroll overshoot before timing

[Actions 35205477642](https://github.com/Corpax88/Ever-Deeper/actions/runs/35205477642)
ran request c459fdfa89847b6b6d44e681b2cc47d68b50a567, job105150075595, attempt1.
NEW GAME and DEV taps were trusted and worked. The start modal disappeared, the
ordinary committed save reported scene=surface and endless inactive, and the visible
DEVELOPER TOOLS/CLOSE DEV drawer passed. Callback counter advanced301 to792 over the
start transition. No timed interval, mining key-down, draw census or CPU sample began.
Browser exit0, no game/GL errors, all nine package/source identity checks passed.

The failure was the bounded scroll route, not a label mismatch. The existing source
label is ENDLESS · LAYER12 (space before12 in actual text); its normalized predicate
ENDLESSLAYER12 was already correct. Original01-menu-1.png shows ENDLESS · LAYER1 as
the last visible row at about702 image pixels, with the next Layer12 row clipped below.
Original01-menu-2.png already shows resources/relics/reset. Scrolling worked but its
inertia carried the target past the next captured viewport; scans3–7 remain at the end.

TouchScrollContainer releases with coast=true when the last motion was less than120ms
ago, then _process continues velocity/deceleration. The retained last-move/release gaps
were about33ms. Root authorized a source-compatible correction plus one subsequent
unchanged-package run:100 CSS pixels per drag, engine frames after the final motion,
250ms stationary hold and further frames before release, then settling and capture.
The original scroll area is approximatelyCSS x83–485/y190–371; the corrected drag
at x180/y330→230 stays inside. Its100px step leaves over80px overlap, larger than a
38px button row; at most eight scans/seven drags. A DOM receipt must independently
show at least200ms between final move and release. Untimed DOM swipes remain untrusted,
while ordinary taps and measured mining keys must be trusted. No label threshold or
remaining save, entry, input, duration, restoration or exit gate changes.

Remaining predicates were checked against exact owners and retained originals:
NEW GAME/NO EXPEDITION FOUND from PremiumMenu and actual start OCR; DEV TOOLS/CLOSE DEV/
DEVELOPER TOOLS from DeveloperMenu and actual opened-drawer OCR; ENDLESS · LAYER12 from
LOCATION_ACTIONS; THE DEEP from the minimap location title and main's entry status,
also visible in the retained exact-DEV11 web08_deep_reentry_idle original. The Layer12
row and actual target scene still require new on-run original captures, not inference.
Save owner run_state.gd serializes scene, active/current_depth, standard/miner/original,
world_seed, mined, total_swings, deepest_metres and stream_anchor at the exact paths
the read-only decoder checks. The existing real-save codec/native parity remains valid.

Untouched raw ZIP:21592922 bytes, SHA256
bd176691d7ff752c12333f7010f9e0d455f2504133421284bc8d92ffa60cd125.
Every ZIP CRC and41 closed-file hashes passed. Original11 PNGs, surface save and all
input/observer receipts remain inside the raw ZIP. Durable failure archive:
Ever-Deeper-DEV11-WebKit-scroll-navigation-failure-20260917.tar.gz,21611463 bytes,
SHA256 9cec21d6b31d06a96ff5c21362c7ccc25cd3623d0fcbe148ca2c4c81b5699553,
Library libfile_f91e97631e1c81918f591d12d73f2378. No performance result is claimed.

# Preserved fourth failure: correctly read target below generic OCR threshold

[Actions 35206469423](https://github.com/Corpax88/Ever-Deeper/actions/runs/35206469423)
ran request b1e3e49706c8f1b33efe8b8213323ab5273c0232, job105153377962, attempt1.
All identity, ordinary Surface, visible drawer and stationary-release gates passed.
The seven actual release holds were344.30–361.74ms. Originals01-menu-3.png and
01-menu-4.png both clearly show ENDLESS · LAYER 12, at CSS181.13,322.56 and181.13,221.87.
Vision read the exact text ENDLESS • LAYER 12 both times with confidence0.5; normalized
ENDLESSLAYER12 was correct but the unchanged generic findText threshold0.6 rejected it.
Thus the non-coasting scroll correction worked; this failure was the OCR acceptance
rule. Both originals were inspected at1696x780. No extra run or threshold change
was made automatically. Browser exit0, no game/GL errors, no timing/draw census/mining
key-down/sampler; observer timed partial=null. Startup callbacks are not FPS evidence.

Untouched raw ZIP:21613955 bytes, SHA256
3d64fa234b5ba3933eda5eb5578b15a36afdfb41defbb7a28e72052f8caca042.
All ZIP CRCs and41 closed-file hashes passed. Durable archive retains all11 original
PNGs, surface save, action/OCR/observer receipts, raw logs and checkpoint identity:
Ever-Deeper-DEV11-WebKit-OCR-navigation-failure-20260917.tar.gz,21631398 bytes,
SHA256 54c03353dc144e001d15e78be623596774be919c905a3048768bf109796f881e,
Library libfile_c1b90a47597c8191b38f4cf0be32e330. The package remains unchanged and
none of the four navigation failures establishes a browser performance bottleneck.

Root subsequently authorized the concrete target-only correction and one corrected
Mac run. Generic findText remains0.6. A dedicated lookup requires unique exact
ENDLESSLAYER12 with confidence at least0.5, center insideCSS x100–264/y210–350 (inset
from the actual scroll/left-button bounds), then the same target in a second settled
original with center difference at most2 CSS pixels and the drawer still verified.
Both OCR records and original image names are retained in deep-target.json before
the ordinary trusted tap. Persisted endless/depth12/scene, actual draws, real60-second
input, mechanics, restoration and process-exit gates remain unchanged. No outcome
is assumed from this navigation correction.
