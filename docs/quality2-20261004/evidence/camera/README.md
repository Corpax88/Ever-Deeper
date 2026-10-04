# Cave camera HUD clearance

Published DEV15.55 reproduces six helmet/minimap intersections at 667, 844 and 932 landscape widths (11/17 checks pass). The scoped camera candidate passes all 17 checks with the original world boundary, geology and saved chunks unchanged. The actual 667 original-tool image was inspected. Four tool styles are covered at 667. Cross-world visual review follows separately.

The camera now limits its downward headlamp lookahead to the space remaining below the 114px HUD, authored 160px hero frame and 12px gap. It interpolates toward this bounded target, including after viewport/zoom changes. Upward lookahead and surface framing are unchanged. Snapshot values report applied framing.

A preliminary north-boundary-margin hypothesis did not resolve the six failures and was reverted; no world-margin change is included. These checks demonstrate visibility, not frame-rate or physical-phone acceptance.
