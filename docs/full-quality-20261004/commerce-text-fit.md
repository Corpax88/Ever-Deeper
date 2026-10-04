# Commerce text fit — 4 October 2026

Scope: existing authored commerce panel only. The Rootwound Drill Forge heading expands its plaque to the measured title width; completed workshop descriptions wrap in full; next-step copy is larger; long action copy fits the inset of its decorative button. Prices, purchase callbacks, assets and progression are unchanged.

Production owner: `scripts/ui/commerce_panel.gd`. Exact owner hash and package identity are in `evidence/commerce-text-fit/package-receipt.json`. This overlays only that owner on the first integrated candidate production package.

`tools/review_commerce_text_fit.gd` produced 27/27 passing checks and eight actual 1334×750 native captures (667 CSS-equivalent width) under Godot 4.7.2, X11 and Mesa llvmpipe. Seven panel families were inspected: surface forge, Starforge, Depth forge, Tool Forge, Light Lab, Wardrobe and Tunnel Workshop. The separate enabled `UPGRADE WORKSHOP` capture was also inspected. Full title widths, action inset widths, helper wrapping, enabled ready state and actual close paths pass. The fixture grants the 100 Deep Alloy needed to present the ready upgrade; it does not claim an unseeded journey or physical-phone testing.

Machine receipts and original log are in `evidence/commerce-text-fit/`. Exact capture paths and hashes are in its `captures.json`; integrated Mac QA will preserve the final candidate images. No new art was created.
