# Shop mockup implementation — v0.46.5

The approved Starforge reference defines a shared shop system: angular bronze headings,
dark metal surfaces, a large authored item preview, thumbnail browsing, legible comparison
rows and a prominent forge action. Shops share placement, fonts and interaction; accent
colours distinguish Starforge (purple), forge (embers), Wayfarer (green), Light Lab (blue),
Wardrobe (rose) and the other workshops.

Russo One headings and Chakra Petch SemiBold body text include their OFL licenses.
Existing authored tools, buildings, boots, frame and action textures are reused. The only
new raster artwork is the transparent Starforge orbit aura. The approved JPEG is a
reference, never flattened into the interface. Long titles adapt, and overflow remains
touch-scrollable with a visible scrollbar. Costs are authoritative: Starforge still needs
both 200 Astralite and 200 Crownstone; the mockup's single cost does not change the economy.

## Editable source

The repository's old top-level source is not current. Use Godot 4.7.2:

1. Extract `game-source` from `Ever-Deeper-v0.46.3-source.zip` (Library
   `libfile_e93359032c8c81918236ce40ff4925ab`, SHA-256
   `4a1d0c6ae4955df9281d64aa8fbbd934ca34ad3cec50a569a115ec6ed279d6ec`).
2. Apply `.github/modal-v0464/source.patch` from the extracted game-source directory.
3. Apply this directory's `source.patch`, then copy the contents of `source/` into it.
4. Check `source-files-sha256.json`, import, and use `Web DEV` / `Web Production` presets.

The Settings/Browse isolation fix remains included; LIVE excludes developer-menu code.
Save formats, identifiers, upgrade prices, progression and transaction behavior are preserved.

## Review and publication

`bundle.json` identifies exact candidate files. The QA workflow reconstructs those bytes,
takes 30 WebKit screenshots at 844x390, and runs real browser touch tests on DEV and LIVE.
`review.json` binds the inspected screenshots and native tests to both PCK hashes.
Publication requires a successful QA run, exact reviewed hashes and an unchanged live
baseline. It backs up all 18 existing files before replacing the Pages deployment and
verifies all 18 public files afterward. Physical iPhone feel still needs Mats's feedback.
