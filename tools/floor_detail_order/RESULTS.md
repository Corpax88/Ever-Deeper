# Headless result — no credible batch opportunity

The one headless check on 17 September 2026 completed with process exit 0, both
stdout/stderr completion markers and no script/runtime errors. It used unchanged
published DEV11 PCK SHA256
`5b77b3a219011cb676895e41830c8dab32bec2346db93102c7894a3c084414e9`
and production source `8f5680defb9083bbe1e044d39a10612f2186e7f3`.

All 10 material/source/strip eligibility checks pass, including restoration.
The geometry proof covers all 1,443 floor-detail offset combinations and 5,772
adjacent-cell intersection checks. Minimum horizontal gap to a neighboring
grown rock rectangle is 2.183772 pixels. A conservative damage-polyline bound,
including width, clamped miter and antialias feather, stays within that rock
rectangle. A deliberate overlap control is correctly rejected. All moved-line
versus intervening-solid intersections in the real generated inventories are
empty. These are geometry/guard checks, not pixel equivalence.

Nine static source inventories use the actual seed-4608, depth-12 resident
terrain, the 1696×780 viewport, actual camera zoom, the original three-tile
margin and original four-cell section alignment. They sample generated terrain
along the resident bands; they do not simulate the live excavation route.

| View | Floor lines | Moved strips | Concatenated command runs A → B | Per-strip runs A → B |
| --- | ---: | ---: | ---: | ---: |
| 00 | 58 | 8 | 95 → 109 | 205 → 205 |
| 01 | 50 | 7 | 107 → 114 | 220 → 220 |
| 02 | 64 | 8 | 117 → 122 | 222 → 221 |
| 03 | 55 | 7 | 105 → 110 | 221 → 220 |
| 04 | 57 | 7 | 110 → 113 | 220 → 219 |
| 05 | 45 | 9 | 107 → 114 | 227 → 226 |
| 06 | 57 | 10 | 128 → 138 | 239 → 238 |
| 07 | 56 | 8 | 112 → 119 | 228 → 227 |
| 08 | 49 | 11 | 107 → 115 | 228 → 227 |

The source model preserves rock/ore/damage order, counts distinct textures and
the engine's unbatchable damage polygons, and distinguishes rectangle and
primitive commands. Real renderer culling, clipping and light specialization
can change the resulting GL count; none is claimed here. Even this favorable
within-strip opportunity is only 0–1 commands per view. Existing cross-strip
runs may become worse: median modeled reduction is **−7**, versus the
predeclared **+5** threshold for considering a pixel/draw-count gate.

Decision: **stop this candidate; no graphical or timing run, no adoption**.
The geometry proof does not justify spending a render trial on an unsupported
benefit. The completed Mac CPU sample remains useful; this app-level ordering
hypothesis does not resolve its wait cost.

Original output: `/tmp/ever-deeper-floor-detail-audit-20260917-attempt1/`.
Closed, byte-verified evidence copy: `evidence/floor-detail-order-headless/`.
Keep `godot.log`, `headless-audit.json`, `source-identity.json` and
`execution-receipt.json`. Startup save/cache files are not needed for this
geometry result and are excluded from the durable evidence archive.
