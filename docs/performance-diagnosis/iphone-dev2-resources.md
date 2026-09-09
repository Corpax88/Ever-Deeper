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
