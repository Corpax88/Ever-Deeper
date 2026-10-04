# Notifications respect modal screens

Actual rendered Treasury and Surface/Depth2 map captures showed FIRST CHIP artwork/text overlapping the map legend, terrain and biome labels. The achievement presentation kept following the hidden world's hero while menus were open. Its transparent activation button could also intercept modal input.

Achievement notices now hide their content and pause their phase timer while the game is in a menu, Bag, shop, companion journal, mod preview, orientation guard or ending presentation. The same notice and remaining queue resume after returning to play. Skill notices reuse this obstruction rule, including the companion/mod panels. Existing PNGs, durations, spin, sound and lifetime records are retained.

`tools/review_notification_modals.gd` opens the actual Skills, Map, Bag, Companion and mod-preview screens, then resumes ordinary play. All19 assertions pass on an isolated exact-baseline overlay: no modal-visible notification input, unchanged phase/queue, post-close resumption, and next achievement still presented. Godot4.7.2 native headless, clean log, disposable user data. PCK SHA256 `16938aa4a79e898e0bfeeda6aba641bc2d5b8766f6f7361a4cfc76885ad3dd10`. Actual integrated graphical acceptance remains required.

The existing DEV shortcut suppression now also covers Bag, mod preview, Skills/settings and presentation screens, keeping the reviewed art and equipped-tool icons clear. Existing gameplay/start-screen DEV access and explicit diagnostics remain. An integrated27-owner overlay passed25/25 notification/modal/DEV checks with no runtime errors; PCK `69a552cdec1f9e6e29cc750fd78a76afa26de9d3e85c3a32d69aa0e4db7353ac`. The two additional receipts retain the actual tested package identity.
