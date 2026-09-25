# Clean shared HUD production candidate — browser correctness passed

Source `4f27644cb5952dbf31644eff78b61e3648ae056f`, run `36116844019`, based on integrated CPU/native candidate981dfb6. Public release remains unchanged.

Six exported core cases passed: input release,125 touch checks, DEV save isolation, Crusher,50 companion autonomy checks,461 world checks. Mac Apple/WebKit production UI gate passed122 checks and24 exact full-image pairs at three landscape sizes. All42 actual PNG retained. Real touch opens all journal tabs and closes; Escape closes journal without opening pause; inventory, pause/continue, Deepheart hide/restore once and actual SceneTree.reload_current_scene are exercised. Root inspected the3 actual Deepheart/reload images; independent full review is pending. Ordinary startup completed51 context samples without recorded loss and6 screenshots, awaiting independent visual review.

The parity reference moves the NEW full-rect Control group to the old CanvasLayer18. It isolates canvas topology while holding new group ownership fixed; it is not byte-for-byte original controller topology. Original-versus-prototype journal parity was separately established in47576e. Native empty canvas stays disabled in both current parity modes; sync2/3/2 per rendered frame is required. No GPU-time/FPS claim from this gate.

Artifacts exact-size/ZIP verified: build10855576005 (7446bytes), browser10855354127 (199448861bytes), startup10855438724 (14508964bytes). Candidate10855710571 (268856865bytes). Full original-package comparison1128d17/run36117283336 is running; same two-worker ABBA/BAAB method, original4 sync pairs versus complete candidate2.

Production diff: controllerextendsNode with owned full-rect Control under existingHUD10, z4095; three original children and all APIs preserved, no extra parking viewport. Main controller typeNode and remove duplicate Deepheart snapshot; HUD child is already included once. Exit frees owned group. `proposed-production.patch` is the two-file UI change. `combined-source.patch` contains the five production files plus earlier QA/dev writer migration and native fixture additions; explicit shared-UI QA suite is retained separately.

No physical phone claim or general release acceptance. Standalone wider-strip QAe212cf5 is a new investigation on this base, not an accepted production setting. Ordinary strip width remains6.
