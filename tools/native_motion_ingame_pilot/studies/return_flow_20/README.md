# Study20 — reported lag / continuous-return timing

Completed bounded review: [REVIEW.md](REVIEW.md) and
[current checkpoint](../../../../docs/premium-polish/hero-flow-20-20260919.md).
The resumed150-frame capture passes with identical gameplay. Do not rerender
the63native loop/bridge images solely to resume; recover the saved evidence.
Deliver ordinary held mining separately from the intentionally interrupted test.

`review_flow.py --game GAME --baseline BASELINE --native LOOP --old-native OLD`
checks gameplay parity and creates exact crops plus two timestamped sheets.
The existing19 packager now accepts `--first-frame 41 --frame-count 82 --repeat 4`
for the normal60Hz MP4.
For the looping GIF, use the same82frames once and `--gif-fps 50`.

Mats reports that19looks like it lags. Investigate delivery and animation
separately. No FPS work or device-performance claim is authorized by a capture.

Confirmed delivery defect: saved19GIF has30frames,1000ms, then a truncated-data
decode failure; intended55frames/1833ms. Its MP4 is intact110frames at60Hz.
The independent critic also identifies real authored holds: contact.42–.52
(68ms), ready.88–1.0(82ms). The rapid fixture intentionally cancels/restarts;
frame33–35repeats cell7 for50ms. That fixture is not ordinary held mining.

One bounded correction preserves model, poses, .68s cycle and .42impact:
contact hold becomes.42–.445(17ms), and return reaches ready at1.0with no
82ms plateau. No camera, pose-path, gameplay damage or cooldown changes.
The isolated consumer reads `ready_progress` from the atlas metadata; old18B
banks retain.88. Regenerate the13-image exact walk bridge because cell31's
return pose changes with the timing. Never reuse its old pose-specific bank.

Render via18's exporter with `--continuous-return --loop`; pack via18's
packager, which transfers the ready progress. Render19's walking bridge with
`--continuous-return`; package it with19's packager. Capture uninterrupted
actual gameplay using19/capture_continuous.gd (marker CONTINUOUS19_COMPLETE),
then19/capture.gd with `--candidate --rapid` and the new loop/walk directories.
Run only one heavy engine at a time. Compare recorded gameplay rows and retain
actual timestamps. Give the independent critic the new timing/image evidence.

Repair preview delivery by encoding to a closed temporary file, decoding every
frame and asserting the expected count/duration, then atomically install it.
Use verified60fps MP4 for judging ordinary mining; GIF is not a device FPS test.
General walking/view/gear coverage and normal-speed quality remain open.
