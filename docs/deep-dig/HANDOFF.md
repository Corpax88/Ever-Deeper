# DEV15.28 — The Deep excavation

29 September 2026. Accepted gameplay source a58b99b40128b7e5a8eb34e626146a551b0137ca on codex/deep-dig-20260929. Main is a publication carrier: never rebuild its historical gameplay source. Baseline was exact DEV15.27; unchanged PCK resources and engine files preserved byte for byte.

Changes: removed cyan Hub elevator overlay; held-direction mining now retains a reachable forward target without cancelling every strike (turning away still cancels); terrain is solid except a small entrance landing and player excavation; relics, sites and hazards are hidden/inactive until uncovered. Deterministic resource placement remains. Physical resource drops rise, then attract nearby, credit cargo only upon pickup, and persist through save/reload and streamed terrain. Atomic claims prevent duplicate rewards. Existing occupied save anchors get a small safe clearing.

Validation run 36617600791 passed: native input and premium-core (231 checks), 12 Chromium gates including 32 Deep checks with actual simultaneous two-finger CDP input, ordinary WebKit startup/save/reload/new-game. Apple Metal GPU, DPR 2. All 15 final screenshots inspected. Historical invariant registry/document mismatch remains a known failure, not counted as passing. No physical iPhone or FPS claims; FPS work remains parked.

Accepted candidate artifact 11056132610, ZIP SHA256 7c473c84e33af0ec00bc252fb1c3014af34db5d33abd741fe6c1c60a9a04a660. Evidence artifact 11055448845, ZIP SHA256 22b927c341843c4d0c7d776b66b66ef7fc15577583b49af302f2de6681251510. Immutable acceptance and reports: .github/deep-dig/accepted.json and evidence/. Publication run 36618603249, carrier cf4185edec5b7cc7d10fbfa5b627a64bd40e9506, verifies all 27 public files and preserves LIVE/Worn.

Authorization: Mats explicitly reconfirmed authorization for uploads, graphical QA and DEV publication in this session. Continue these authorized steps without asking again. Earlier automatic upload denials preceded that new authorization. LIVE publishing is separate.

Earlier failed attempts: native retreat cancellation fixed before acceptance; test fixture reach corrected; preliminary graphics used the joystick Control center outside its active zone, corrected to a real left-side touch and second mine finger. Do not describe earlier failures as passes. Final source and artifact above supersede all local candidates.

Publication completed and all 27 public files verified. Receipt artifact 11058260876; rollback artifact 11057560654 (DEV15.27 plus unchanged Worn). Only DEV index.html/index.pck changed.
