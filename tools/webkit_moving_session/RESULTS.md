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
