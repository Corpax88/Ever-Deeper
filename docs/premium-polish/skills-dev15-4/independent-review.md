Accepted: DEV15.4 silver tooltip headings

Source: 666cecf24214c2b144c5bc8403cfd526e625c416
Code quality10/10. Scoped visual quality9/10. No blockers.

All five actual tooltip headings render in consistent light steel/silver with readable contrast against the dark tooltip panel.
Tooltip body and right-hand skill labels remain warm cream; only tooltip heading color changed.
Typography, shadows and tooltip layout remain consistent, with no heading clipping in the five inspected captures.
Single local font_color override #cbd1d8 on _tip_title meets the authorized scope without changing gameplay, saves or skill values.

Inspected:
/tmp/metal-headings-browser/dev15-4-browser/tooltip-mining-844.png
/tmp/metal-headings-browser/dev15-4-browser/tooltip-running-844.png
/tmp/metal-headings-browser/dev15-4-browser/tooltip-carrying-844.png
/tmp/metal-headings-browser/dev15-4-browser/tooltip-prospecting-844.png
/tmp/metal-headings-browser/dev15-4-browser/tooltip-stamina-844.png

Limits:
Acceptance covers tooltip heading color only, not whole-game visuals, animations or sustained FPS.
Inspected five final Chromium tooltip captures at844x390; no physical iPhone verification.
Public-byte verification remains publisher responsibility.
