# 0.46.1 — iPhone menu input

Content-area swiping replaces scrollbar-only interaction in the pet skill list, inventory, achievements, shop item strip, shop details and developer drawer. The shared TouchScrollContainer tracks one finger in each menu's local coordinates, cancels pending child button presses once a swipe begins, suppresses the associated mouse release, and adds short deceleration. Ordinary taps and desktop wheel/bar input remain available. Hiding a menu, application focus loss and browser touchcancel clear the gesture.

Pet buttons are 75 logical pixels high (about 45 CSS pixels on an 844-pixel-wide landscape iPhone), with revised spacing for Together, tabs, Close and Learn. The original journal artwork and all ten reactions are retained.

Native gameplay regression: 859 checks passed. Exact DEV PCK menu test: 16 checks passed. Production flavor test confirms developer menu and resource absent, with the original isolated production save namespace. Browser tests exercise swipes over Learn buttons and text, cancellation without buying, a deliberate purchase exactly once, inventory, achievements, the horizontal shop catalog without selection, shop detail fit, and the DEV drawer. Chromium uses real CDP touch; WebKit uses browser touch events for swipes and native touchscreen taps for activation. This is browser-engine testing, not a physical iPhone test.

Source and exact runtime identities accompany the visual/input review. Both previous public builds are backed up before the reviewed candidates are deployed, and every public runtime file is verified afterward.
