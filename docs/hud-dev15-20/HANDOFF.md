# DEV15.20 — Skills knot and compass removal

Mats approved option3 blue-gray steel interwoven knot and explicitly requested removing the unused compass. The requested runtime changes are complete and validated. Publication run36492425281 passed package/deploy/verify; all27 public hashes verified,9LIVE+9Worn preserved. Receipt11001686972;rollback11002850512.

Exact game source b037f532435d43c114380d14a6e2ab63d14d0d39, branch codex/hud-dev15-20-20260928, repository Corpax88/Ever-Deeper. Parent df8608b898dae3ba3fa248dec90a354b8dd5fc52 / DEV15.19. Main remains publication carrier; do not build its historical game source.

New asset assets/ui/skills/icons/skills-knot-blue-steel-v1.png is1254x1254 RGBA, one icon with transparent background/holes and no text. Built-in image generation extracted the approved option3; original generated pixels retained. Prompt: extract rightmost blue-gray steel knot, retain silhouette/orientation/material; transparent holes/background; no text/thumbnails/shadow.

HUD uses new PNG with existing104 icon cap and120 touch target. Compass is permanently hidden/disabled, retained as an internal compatibility node. Companion and mobile gold move one slot left. Progression goal stays visible; Skills internal layout and all balance/FPS/hero/world/save logic stay unchanged.

Validation36479931785: input release and premium-core200 checks passed. Chromium Apple Metal actual touch at844x390,667x375,900x600:21 observations/gates passed including compact placement, hidden compass on surface/Moss, Skills/mole opening/closing and real mining afterward. Actual browser-reported DPR2 (requested context3; do not call measured DPR3). Ordinary Mac WebKit startup, pause, saved-menu reload and confirmed new game passed. All13 actual PNGs inspected. No physical-iPhone claim. Existing crowded Skills navigation at900x600 is outside the HUD-change scope. Existing source invariant debt was not re-certified; exact package resource hashes enforce preservation for this patch.

Exact immutable candidate10996042147, ZIPsha25682bf7318305c52e533e7a3ea7047193bcc570fbd5dd1d6dd80c623139fd656ed. Browser evidence10996561562;core10995872277. Publisher cf6aa8678696076e1cc3c0132070a3e33ac9e6b2/run36492425281 binds all review files, source, artifact digest and9 candidate files, preserving9LIVE+9Worn.

PCK 266134172bytes SHA25611d1f0fc6577c0544915ac8a3bcff22e4e0675fe962a1b5598ede805145ebdca.

FPS investigation remains explicitly parked after Mats's stable53–60FPS DEV15.18 session; no claim that its cause was fixed. Skill balance/recovery from15.19 is preserved. Next: user can refresh DEV15.20 and inspect the icon/spacing. No jobs remain. Do not repeat completed unchanged tests.
