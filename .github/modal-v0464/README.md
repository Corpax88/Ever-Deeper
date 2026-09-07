# Ever-Deeper 0.46.4 — pause menu input isolation

Settings could activate an obscured Starforge Browse button. Godot's GUI hit testing follows sibling order, while the pause menu previously relied on z_index for its visual position. PremiumMenu now moves to the front when opened; context actions also reject calls during pause, inventory, companion and orientation overlays.

The regression forces Settings and Browse to overlap, sends real touch input, checks Settings opens without opening commerce, checks a direct context callback is rejected, and verifies Browse works again after closing the menu.

## Editable source
Start with Ever-Deeper-v0.46.3-source.zip, SHA-256 4a1d0c6ae4955df9281d64aa8fbbd934ca34ad3cec50a569a115ec6ed279d6ec (Library libfile_e93359032c8c81918236ce40ff4925ab). Extract game-source and apply this directory's source.patch with git apply. Use Godot 4.7.2 and Web Production / Web DEV presets. Do not use the older top-level distribution repository source.

## Exact candidates and verification
bundle.json contains hash-checked deltas and complete HTML. prepare.py reconstructs DEV and LIVE from the current 0.46.3 production baseline and verifies all 18 files. The seven runtime files, authored artwork, game data and save identities are preserved. LIVE excludes the developer menu.

Native exact-pack tests: LIVE 37 menu checks, DEV 39 menu checks; LIVE 859 gameplay checks. Browser validation: Actions run 34107482398. WebKit at 844x390 passed 70 checks, and settings-blocks-starforge.png was visually inspected. Physical iPhone testing remains for Mats.

Publication uses the exact candidate artifact from that run, checks the reviewed hashes, backs up both previous public builds, deploys DEV and LIVE together, then verifies every public file. See publication-receipt.json after deployment.
