# Isolated DEV11 WebKit hitch attribution

This is an explicitly instrumented diagnostic build based on production
`8f5680defb9083bbe1e044d39a10612f2186e7f3`. It is never published as the game.
The unchanged WebKit baseline remains separately preserved at study commit
`48040cfed84a74009513936b3bd1cabaa5ff69b7` and run35207448460.
That baseline contains three long engine-loop intervals (440.00,202.28,280.40ms),
with preceding synchronous callbacks370.66,196.54,232.12ms. Mean callback wall
time9.2234ms and mean cadence59.086Hz do not certify stable50 presented FPS.

Only the real `_generate_stream_window`, `_rebase_stream_window`, and
`save_game` owners receive wrappers. Their full original bodies, early returns,
save error codes, order, assets, RNG, physics, materials, lights and effects are
byte-preserved. One extra autoload stores512 fixed-size numeric records. It has
no process/physics hook, per-frame callback, timed string/JSON allocation, log or
file write. Generation inside rebase remains nested and is never double-counted
as exclusive total time. The recorder is inactive during ordinary navigation.

The web bridge only controls this recorder and reads its clock/buffer. It cannot
move the player, change worlds, request a save or change game settings. Five
synchronous JS-before/engine-tick/JS-after clock brackets are retained before
and after timing; none runs during the60-second observer window. Offset bounds
include an explicit0.05ms browser timestamp quantization allowance. Inconsistent
brackets, width≥5ms, overflow, open spans, invalid nesting or missing real owner
events fail the attribution gate. This follows the official
[JavaScriptBridge callback API](https://docs.godotengine.org/en/stable/classes/class_javascriptbridge.html)
and retains the callback reference as required by
[JavaScriptObject](https://docs.godotengine.org/en/stable/classes/class_javascriptobject.html).

`observer.js` is byte-identical to the successful unchanged test:
`35db05eed667a6b95ec235d2b0673ea2ddf48cf7ccfa84ef193ed04ba0bf4424`.
The source-verified UI route, trusted taps/held Down+Space,
explicitly untrusted untimed GUI touch drags, actual draw census outside timing,
save/mechanics checks, visibility/error gates and browser exit/marker remain.
The source guard hashes the reviewed GUI sections and compares the two whole
modified owner files against exact transformations of the pinned originals.
Any other runtime/asset change fails. This does not assert determinism between
two fresh random game seeds.

Workflow `dev11-webkit-hitch-probe.yml` triggers only from this branch's REQUEST.
Preparation is checkpointed and ref/tree verified first. REQUEST names that
parent and authorizes one session. Linux uses ordinary Godot4.7.2, existing Web
DEV export flags, matching templates and two permitted curl retries. It retains
toolchain hashes, parser/recorder checks, source diffs and packed state/world
functional gates. No Production export, publisher or release is included.
Mac15 uses the same pinned Playwright dependency and848×390/DPR2 mobile WebKit
setup. All nine new diagnostic export files and their identity hash are checked.
The diagnostic PCK is intentionally distinct from the preserved unchanged PCK.

CPU/GPU sampling is not part of this bounded probe. Phase timings are wall times
including wrapper/recorder overhead and synchronous waits. The overlap analysis
uses interval unions; it preserves unmatched callback time without assigning it
to GPU, driver or any unmeasured owner. The browser metric remains engine-loop
callback cadence, not presented FPS. No optimization benefit can be inferred
from a comparison with a different fresh-seed run. A run without a recurrent
stall or without matching selected-owner spans may simply leave attribution
unresolved. There is no automatic second run or alternative probe.

Local preparation checks:

```
python3 tools/webkit_hitch_probe/prepare.py verify --output /tmp/hitch-source.json
python3 tools/webkit_hitch_probe/prepare.py recorder-check --godot /absolute/Godot --output /tmp/hitch-recorder.log
node tools/webkit_hitch_probe/check.mjs
node tools/webkit_hitch_probe/check-phases.mjs
```

The first workflow35210964673 stopped at binding, before Mac. Import/export,
recorder/parser and the packed state187/world461 checks passed. Godot generated
`scripts/ui/feedback_placement.gd.uid` for an unchanged existing8f script whose
sidecar was absent from Git. The initial guard correctly reported this extra
file; no timing was accepted. The corrected guard records only that exact
generated UID as import metadata, requires an uncommitted valid UID and the
owner's byte identity with8f, and rejects all other runtime differences. The
game still preloads that helper by its original `res://` path. This binding
correction does not change the recorder, observer, wrappers or exported inputs.
First build artifact10492855609/SHA256
`981b0b16c801fb239f69ace31bfd03d017cf26f26a140c4dfaaa7e6650426a2e`
and its original error are preserved. The skipped Mac job supplied no samples.

The corrected build's Mac run35211444182 stopped before timing at the surface.
The retained trusted NEW GAME tap did close the modal. `00-surface.png` shows the
ordinary game, but exact unique `DEV TOOLS` had Vision confidence0.5. The old
generic0.6 check misleadingly called this a menu-close failure. Browser exit0,
no runtime/GL errors,633 advancing callbacks, inactive phase buffer/count0 and
no raw timed samples are preserved (Mac artifact10491948105, SHA256
`c60f642af07cc5434bcec7293b7264f508fa4f8282b00b16a2494b18c7b074db`).
Its PCK is exactly the prior candidate's
`82b8127c7551757c7e8b11e9ec994abeac3a2795543225540e5fa16b22e14b81`.

The navigation correction is limited to unique exact `DEVTOOLS`>=0.5 inside
CSS center inset88..130/82..104, corroborated350ms later at the same center
(<=2CSS px). The full retained button bounds are69..148/75..110 at the checked
848x390/DPR2 viewport. `_build_toggle` supplies the exact text, and `_apply_layout`
places it below PremiumHud's menu row. Start-modal absence, persisted surface,
visible loop advance and actual drawer/title remain required. Generic0.6 is
unchanged. Review of every remaining target against the successful original
OCRs found NEW GAME/NO EXPEDITION FOUND/CLOSE DEV/DEVELOPER TOOLS all1.0;
Layer12 already uses the exact two-image0.5 gate, and THE DEEP entry already
accepts its observed0.5 text with persisted scene proof. No speculative global
OCR relaxation is made. The drawer/depth/draw/timing/save route after DEV opens
is byte-identical to the successful baseline; the raw observer stays exact.
All nine diagnostic package files are now pinned to the verified run35211444182
candidate (the prior two exports already match exactly). A navigation-only
correction must reproduce every byte/hash before Mac can run.

The existing full-project invariant check flags `project.godot` for the extra
diagnostic autoload and the already known baseline `player_visual.gd` mismatch;
the protected runtime expectations are not relaxed. The recorder/parser/source
checks pass, including a105ms nested-interval union rather than a175ms sum.
The two packed functional suites and original-route browser gates are concrete
checks for the touched save/streaming owners, not a production release signoff.
