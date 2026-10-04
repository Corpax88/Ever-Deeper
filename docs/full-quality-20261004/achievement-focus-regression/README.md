# Achievement highlight layout regression

The selected achievement ID survived page construction, but the initial deferred scroll used provisional nested-container positions. The Threefold Star row began at 3752 while the scroll jumped to 5652, leaving the requested achievement entirely offscreen. A second call after layout correctly revealed it.

`premium_menu.gd` now waits one process frame before resolving the target and guards against page replacement, closure, or Back during that wait. Existing artwork and list sizing are unchanged.

Validation: real native Godot 4.7.2 X11/software GL, 1334×750 framebuffer (667×375 at 2-pixel capture scale), isolated save, exact existing production PCK with explicit source overlays. All unrelated packed payloads retained; receipt included. This is not a physical phone or Mac browser result. QA has been asked to repeat target visibility in the maintained Mac matrix.

First Chip, Threefold Star, and Ever Deeper each retained the requested ID and placed the complete row inside the scroll viewport. Back during pending focus returned to the menu without reopening or highlighting a stale page. No script errors. The actual before and after frames are included; DEV toggle in the historical overlay predates root's separately verified modal suspension fix.
