# Wardrobe portrait — 9 September 2026

## Scope

Replace the small animation-cell preview in Wardrobe with Mats's approved
`Ever-Deeper-wardrobe-crossed-arms-v2.png`. The original 1600×2000 transparent
PNG is retained byte-for-byte in `assets/hero/dad/wardrobe/crossed-arms-v2.png`.
SHA-256: `d26daf25c87a728ac252244830bc56ac27be17f9b40325bbcf08943d59d42f91`.

`scripts/ui/wardrobe_portrait.gd` fits the whole character inside the existing
large preview and cards. Lossless import and mipmaps support the different
display sizes. Its shader changes the fabric to the existing five outfit
colors while retaining skin, hair, helmet, leather and the authored shading.
Light Lab retains `outfit_preview.gd` and its existing directional hero preview.

## Release procedure

The exact current public LIVE and DEV packages are separate baselines, recorded
in `.github/wardrobe-portrait/baseline.json`. Only CommercePanel and the new
portrait resources are copied from the compiled export. Every other packed
resource must remain byte-for-byte identical, with no deletions. This preserves
the separate LIVE and DEV hero, lighting, gameplay, save and developer-menu state.

`.github/workflows/wardrobe-portrait.yml` compiles the change, runs the existing
nine production cases, ten DEV cases and both exported flavor checks, then captures nine
Wardrobe states and exercises mobile touch, unlock/equip and save behavior.
The preceding published Wardrobe is captured for comparison. The exact candidate
must be inspected before `visual_reviewed` is set in its release receipt.

## Verification and release status

Validation: commit `f3308054c60fd2014a6902038894f3a8a0cddce2`, run
`34324191544`, all jobs passed. Exact candidate artifact `10093151681`.
LIVE has 189 mobile touch checks; DEV has 193; all passed. Both nine-state
Wardrobe captures and the two preceding published baselines were inspected.

DPR 3 validation: commit `7aff03a7843b9823396225136a37375385ee43ad`, run
`34324907471`, both jobs passed. All ten 2532×1170 captures were inspected.
The five clothing colors, complete character silhouette, transparency and
material detail are retained. Evidence previews are in
`.github/wardrobe-portrait/evidence/`; the release receipt records full hashes.

Only `scripts/ui/commerce_panel.gdc` changes inside each public package; five
portrait resources are added. The other 1277 LIVE and 1300 DEV resources are
byte-for-byte identical, with no deletions. LIVE remains 0.46.9 and DEV remains
0.46.9-dev.9; this task updates Wardrobe only. Physical iPhone FPS is unverified.

Publication is the remaining step. The publisher requires both inspected runs,
checks the exact candidate hashes, preserves both preceding public builds, and
verifies all 18 public files after deployment. A concurrent release aborts staging.

Next user check: reopen the game, enter Wardrobe and tap/swipe through all five
colors. The full-resolution crossed-arms character should replace the old blurry
animation frame. Unlock, wear and saved outfit behavior is unchanged.
