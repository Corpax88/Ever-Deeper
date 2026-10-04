# Target label readability and truthful sales destination

The sale action now names the real destination: `Sell ore · Surface Assay`. The change is presentation only; goal, prices, inventory and transaction rules are unchanged.

Depth 1 target labels now use one reused, unshaded Label with cream text and a dark outline. The existing resource-colored brackets and all approved assets remain. The text stays at 24 logical viewport pixels across camera zoom (about 13.2 CSS pixels in these 2× mobile captures), selects a position clear of the native hero, and disappears when the target clears. `main._update_achievement_toast_anchor` reserves its transformed rectangle, including the outline, for skill, pickup and achievement placement.

## Rendered evidence

- `readability/report.json`: **62/62 passed**, 10 real package images at 667×375 and 844×390 CSS-equivalent viewports, including 1.6× camera zoom. Stone, copper, tool-locked wall and the existing bedrock fallback were inspected. Bedrock is excluded from ordinary target selection; the probe explicitly selects an existing bedrock block only to review that fallback. No terrain or rewards are changed by the probe.
- `feedback-before/report.json`: the focused crowded-state probe reproduced four target-label overlaps before the shared notice exclusion was added. The original failed images remain in their render directory; the failed report is preserved here.
- `feedback-after/report.json`: **14/14 passed** after the integration. Actual skill, pickup and achievement notices clear the target text. In the constrained 667 case the achievement is deferred with its phase paused, then resumes visibly and reaches the readable hold phase when the target clears. `achievement-resumed-667.png` shows that resumed state.
- The original image identified as `readability/bedrock-667.png` in the image manifest retains the first observed achievement overlap. It is diagnostic before integration; `feedback-after/` is the acceptance evidence for the resolved overlap.

The exact PCK overlay receipts are `readability-package.json` and `feedback-package.json`; they verify unrelated payload retention against the published DEV15.55 production package. `evidence-sha256.json` binds the text evidence and lists every original PNG by evidence name, absolute render-directory path and SHA-256. PNG files remain in those original render directories; only duplicate copies were removed from this documentation directory. This is native rendering with the approved hero, not a physical-phone or browser release acceptance.

## Reproduction

Use `tools/review_target_labels.gd` for the state/zoom matrix and `tools/review_target_label_feedback.gd` for the four notice states and deferred achievement resumption. Set `MODS_OUT` to an isolated evidence directory and run the script with the real production PCK plus the source overrides named in the receipts. Both require a graphical Godot 4.7.2 renderer and isolated save data.
