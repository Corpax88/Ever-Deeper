# Ever-Deeper 0.46.3 — continuous shop carousels

The previous swipe implementation switched the selected item after release,
which still felt like paging with invisible arrow buttons. The shared commerce
card strip now follows the finger continuously and preserves its existing card
nodes. Release carries velocity into a damped animation toward the nearest
centered item. Touching the strip stops its movement immediately.

This applies to multi-item shops and workshops using CommercePanel, including
Starforge, Tool Forge, Light Lab and Wardrobe. Single-item shops retain their
normal presentation. Arrows and the horizontal scrollbar are absent. Vertical
details, taps, desktop dragging and wheel browsing continue to work. Navigation
never purchases or equips an item; buying is disabled during horizontal drags.

Existing authored artwork, game data, economy and save identity are preserved.
The native suite checks continuous displacement, settling across frames, stable
card identity, interruptions, list bounds, longer lists and purchase isolation.
Browser validation uses Chromium and WebKit at mobile landscape viewports;
Chromium also records the actual canvas motion for review. The QA handshake
uses F8 so its acknowledgment cannot activate a held menu button.

See review.json for final immutable build identities and verified evidence.
DEV and LIVE are published together from those exact reviewed artifacts, with
the previous 18 public files backed up and all 18 new public files verified.
Physical iPhone performance and Mats's subjective acceptance remain unverified.
