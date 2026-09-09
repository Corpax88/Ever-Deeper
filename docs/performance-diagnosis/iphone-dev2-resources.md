# DEV2 texture residency investigation

The physical report shows 19.9 FPS after 554 seconds, p95 56.0 ms, CPU 23.0 ms,
physics 1.0 ms, 155 draws and 567 MiB reported GPU memory at 2328×1260 / DPR 3.
This is a serious device performance failure. The texture inventory below does
not establish which portion of that frame time is caused by memory pressure.

The inspected baseline source is `6d65ce6340723da0ddbb5e9af06f8e84f9412259`.
No hero PNG, import setting, animation frame, shader, texture size or visual
quality setting was changed by this resource-lifetime work.

## Baseline ownership

These are static PNG payload estimates, not a sum of measured GPU allocations.
Owners share some paths; the final row deduplicates paths. Scene resources,
runtime-loaded textures, imported mipmaps and render targets are excluded from
these totals. The wardrobe's existing generated mipmaps remain enabled.

| Runtime owner | PNG preloads | Source channel payload | RGBA8 equivalent |
|---|---:|---:|---:|
| SurfaceWorld | 109 | 179.67 MiB | 185.90 MiB |
| CommercePanel skin | 5 | 30.00 MiB | 30.00 MiB |
| MoleCompanion | 4 | 12.24 MiB | 12.24 MiB |
| WardrobePortrait | 1 | 12.21 MiB | 12.21 MiB |
| All scripts, unique paths | 149 | 267.58 MiB | 275.19 MiB |

The shared hero loader already loads only the current tool's eight atlases:
four directions, each with its color atlas and grayscale cloth mask. Standard
atlases are 1280×2400; Crusher atlases are 1280×3360. Their decoded source
payloads are respectively 58.59 and 82.03 MiB per complete equipped tool. The
actual backend can promote channels, so these are not GPU-memory measurements.
Inactive worlds release their hero references, and rapid equipment requests are
drained by the shared loader. No all-tools preload or unbounded equipment cache
was found.

SurfaceWorld stays instantiated and retains its surface sprites and preloads
while the player is underground. D1 and D2 replace their biome texture maps when
configured for a new mine, but retain their latest map while inactive. These
are fixed residency costs; a single high memory reading does not prove a leak.
Removing the surface safely requires work on its complete resource ownership,
not merely clearing the player's visual cache.

## Bounded correction

`CommercePanel.close_commerce()` previously cleared its item data but kept all
catalog, overview and showcase nodes. In a complete light workshop this kept
six preview SubViewports, their render targets and a previous hero's right-facing
atlas/mask after the shop closed. The viewports use `UPDATE_ONCE`, so their
retention was not continuous extra viewport rendering.

Closing now releases those dynamically rebuilt nodes and item texture
references, and stops the pending showcase tween and carousel. Opening already
rebuilds the catalog and showcase from the current configuration. The wardrobe
portrait now loads the original 1600×2000 texture when a portrait sprite is
created; its shared script no longer permanently owns the texture.

## Verification and limits

The isolated headless resource probe passed 122 checks with exit code 0 and no
script errors. It opened, closed and reopened the actual five-style light and
wardrobe catalogs across worn → Crusher → Deepcore → worn equipment, verified
the current production hero and unchanged resources/loadout, and drained rapid
equipment requests to exactly eight final atlases.

- Light workshop: 188 descendants and six preview viewports while open;
  58 descendants and zero preview viewports after closing.
- Wardrobe: 107 descendants while open, 58 after closing. The original portrait
  resource is cached while open and absent from `ResourceLoader` after closing.
- Weak references confirm old preview nodes were freed; reopening restores the
  same catalog and selection and the full-resolution portrait.

These checks establish resource lifetime and reopening behavior. They do not
measure physical iPhone frame times or certify rendered visual parity. Native
or browser measurements and final image review remain separate release gates.

## Headless engine error follow-up

One local 13-case source run stopped during touch QA with
`Parameter "t" is null` in the dummy renderer's `texture_2d_initialize`.
That run remains recorded as failed. An isolated rerun passed all 123 touch
assertions without engine errors; the CPU review agent independently obtained
the same result. Initial candidate CI
[34360064270](https://github.com/Corpax88/Ever-Deeper/actions/runs/34360064270),
at source `bafaec4dccef813602245c6140ec457a286784fd`, passed all 13 source and
13 exported DEV PCK cases, including touch (123 and 125 assertions respectively).
These results do not describe the later corrected candidate CI run.

The same bounded external allocation stress then ran sequentially against the
immutable DEV2 baseline and initial candidate. It changed worn → Crusher →
Deepcore equipment while loading ordinary short-lived textures on the main
thread, using normal ResourceLoader cache behavior.

| Package | Equipment cycles | Actual cold temporary loads | Engine errors |
|---|---:|---:|---:|
| DEV2 baseline | 12 | 2,208 | 0 |
| Initial candidate | 12 | 2,904 | 0 |

Every cycle completed with exactly eight current hero atlases. Exact Godot
`ed1daf0bf` source shows that the dummy texture RID owner defaults to a
non-thread-safe allocator, while GLES3 explicitly uses a thread-safe owner.
This supports an allocation-race hypothesis; it does **not** prove the cause
of the observed failure. Rendering-thread `free_rid` also flushes pending
commands before freeing, so releasing a resource alone does not establish
initialization after free.

No application workaround, retention delay, headless bypass or error filtering
was added. The intermittent error remains unreproduced, and these bounded
passes do not rule it out or establish iPhone performance. Package, harness,
result and log hashes, CI results and exact engine source references are in
[`fps-texture-investigation.json`](fps-texture-investigation.json).

## Rendered comparison and phone follow-up

The rendered comparison used the unchanged DEV2 PCK (`c331cde35f64...`) and final
runtime candidate `42fffc163c940db2ab9df2e1924608e2d1659793`
(`6ec691604a06...`), serially with the same external commerce harness
(`756055c344db...`). Fresh save directories and exported resource roots were
used; only the candidate required resources to be released. DEV2 passed 44
checks and DEV3 passed 58, both with exit 0 and no engine errors. This used native
GLES3/llvmpipe, and `physical_iphone` remains false.

| Shop closed | DEV2 GPU released | DEV3 GPU released | DEV3 shop nodes | DEV3 preview viewports |
|---|---:|---:|---:|---:|
| Wardrobe | 0 MiB | 16.30 MiB | 107 → 58 | 0 → 0 |
| Light Lab | 0 MiB | 20.34 MiB | 188 → 58 | 6 → 0 |

Both second closes produced the same releases. DEV3's portrait cache entry and
preview weak references disappeared after closing; DEV2 retained them. After
both shops closed, reported GPU totals were 564.55 MiB in DEV2 and 534.03 MiB
in DEV3, a 30.52 MiB whole-package difference. These totals include other scene
and backend allocations and remain above cold startup. The within-package
open/close deltas directly measure the preview release.

Opening and reopening images are pixel-identical within each package. The two
1100×1200 beam images are also identical across packages. Cross-package full
windows differ only in 635 pixels in the exposed top hub strip, maximum channel
error 6/255; the shop content is identical. Original portrait dimensions,
selection, catalog and unchanged loadout checks passed. Full counters, image
and package hashes, comparisons and limits are in
[`fps-commerce-residency.json`](fps-commerce-residency.json).

A second source review found no new dangling preview owner: close detaches
nodes before queued deletion, clears the selected-card reference and tween,
and emits its control-restoring signal afterward. Deferred carousel layout
checks the current card's validity. Reopening rebuilds presentation and resets
showcase opacity. The remaining concrete tradeoff is that opening now recreates
portrait textures and preview targets; a frozen image review cannot establish
whether that causes a noticeable opening hitch on a phone.

After the verified DEV candidate is available, use a review save on the same
iPhone and browser mode as the original report:

1. Confirm the DEV build label and show FPS. Record the canvas size, DPR, FPS,
   p95, maximum frame time, GPU counter and node count before opening shops.
2. Browse available wardrobe styles, close and reopen ten times; repeat in the
   light workshop. Check the first opening, rapid reopening, portrait colors,
   beam appearance, selected item and immediate return of movement controls.
3. Repeat after changing available tools, including Crusher and Deepcore.
   Confirm each reopened light preview shows the currently equipped tool.
4. Return to the original mining area, then The Deep, and continue moving and
   mining for at least ten minutes. Capture the same counters and any opening
   hitch, missing preview, reload or sustained FPS drop. Judge physical smoothness
   separately from desktop allocation and screenshot results.

The final artifact's eight hub/arrival frames and six mobile wardrobe frames
were also reviewed against their DEV2 counterparts. No visible regression was
found; four wardrobe PNGs are byte-identical. The museum's 0/5, 3/5 and 5/5
states, upgrade panels, carried relic on Tunnel Home arrival and all five outfit
colors remain present. This is image evidence only. Filenames, artifact IDs,
hashes, observations and comparison limits are recorded in
[`fps-hub-wardrobe-review.json`](fps-hub-wardrobe-review.json).
