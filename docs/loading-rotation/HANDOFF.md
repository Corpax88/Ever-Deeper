# LIVE loading rotation hotfix — 29 September 2026

Mats reported that rotating portrait to landscape moved the splash down and hid the loading bar. LIVE and DEV's HTML loaders were identical except PCK size; matching code does not imply matching Safari viewport state.

## Scope and mechanism

Only LIVE root `index.html` changes (24719 bytes, SHA256 ee4e7baa1c9724a98842419c91a78f865e371f2117f69e0372e7cf7e5c094b81). Game remains LIVE1.0.2, shell hotfix loading-rotation-1. All engine/PCK/image/audio files, DEV15.22 and Worn are preserved byte-for-byte. FPS work stays parked.

The old absolute overlay used the layout viewport; Safari's visible viewport can be shorter and offset during rotation/browser toolbar changes. The overlay now uses fixed positioning with visualViewport size/offset, dynamic-height CSS fallback, safe bottom spacing, coalesced resize/orientation/scroll updates, and listener cleanup when loading finishes. No per-frame gameplay listener remains. Existing error notices keep their viewport updates. Approved splash and progress design retained.

## Exact source and test

Source147e4dfe997e9166b0a086d977a9c6d1e09ab58d on codex/loading-rotation-20260929; workflow .github/workflows/loading-rotation.yml, run36569827357. Build only patches the verified immutable LIVE1.0.2 artifact11020836697 from36541177604. Never re-export historical main.

Mac macos-15 / Playwright WebKit / Apple GPU, requested DPR3 but runtime reports2. All25 checks passed with no runtime errors. Actual cold/reload portrait→landscape→portrait→landscape captures, ordinary start menu ready twice, overlay remains removed after later resize. All13 original PNGs visually inspected. Controlled visual/layout viewport mismatch: baseline bar bottom356 lies outside visible bottom300, candidate bottom277 lies inside; changing viewport offset/size also passes. This mismatch is a synthetic fixture, not a physical iPhone/Safari toolbar recording. Actual physical iPhone behavior still needs ordinary user feedback.

Evidence artifact11033531964, ZIPsha2568cf0412f6e80c52c31a71f31da3647d4946ad25f3f63f8d1818a90e613cbd5c7. Candidate11033422171, ZIPsha25678a32398dc72e080693ef5c3640381cf360d575aaf674c82d7f136e7564cfaae. Raw report in .github/loading-rotation/evidence/report.json; PNGs in evidence artifact. No unrelated gameplay/core/FPS tests repeated: PCK is unchanged and its prior successful gates are recorded in docs/menu-stamina/HANDOFF.md.

## Publication

Accepted publisher commit e2901e9f9d59a9fb22991acdcc8a6b7b1c3c6c74, run36570148578. All package/deploy/verify jobs succeeded; all27 public hashes verified. Receipt11033786799; rollback11033716790. Publisher verifies reviewed hashes, exact successful source/run/artifact, downloads all27 original public files, replaces only root HTML and verifies all27 after deployment. Rollback contains only previous root HTML plus instructions; retain all other current files.

## Next

Published and verified; no pending work. User can reload LIVE in portrait and rotate while loading. Do not ask for cache clearing or erase saves. Do not repeat this accepted test or rebuild the unchanged game. Preserve menu stamina recovery and approved Skills icon/caption/no compass.
