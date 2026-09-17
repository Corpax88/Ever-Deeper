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
An unexplained failure stops the retry; no further attempt is authorized.

The untouched raw ZIP is713174 bytes, SHA256
7b27bcafaeb99d8db80aa26dc2d555f3240540430a01c0f4089d16021392ee2b.
Every ZIP CRC and all22 closed-file manifest hashes passed. Failure archive:
Ever-Deeper-DEV11-WebKit-navigation-failure-20260917.tar.gz,725425 bytes,
SHA256 fa7a000e7daa3a5daa2f8189caaa393010992d973c4ff347308397b8320579cb.
It is saved as Library libfile_d77ddcfdee5c8191bd7fa754d7f42674.

There are no current Deep browser timing or attribution results from this run.
The native Godot ANGLE bounded-pool wait remains inapplicable as browser evidence.

