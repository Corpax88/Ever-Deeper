# V4 native elbow feasibility — rejected before runtime integration

This isolated branch starts at the exact preserved study
`90ac772232b8506f7146a495e8ae613cd178f663`. The existing mapper, all production
PNGs, shared drawer, terrain, collision and gameplay are unchanged. V3 remains
default-off and unpromoted. Earlier rejected attempts remain preserved.

## Proposed narrow correction

For the one matching upright NE bedrock turn, sample the actual authored elbow
from `assets/caves/ancient-bedrock-corner-v1.png`, retaining its continuous facet
grain across the bend. V3 currently samples only the lower straight leg and
intersects it with the separate horizontal loop. Its actual captures show the
resulting square, cross-grained joints. A native elbow could address that cause;
simply changing the overlap order would move the visible seam.

I re-inspected the full V3 `topology_bedrock_intact_candidate.png`,
`topology_bedrock_excavated_candidate.png`, and
`topology_voidstar_intact_candidate.png` in
`/workspace/scratch/4e99473f21fc/evidence/deep-wall-study-v3-fixed2`, plus the two
unchanged production corner/edge PNGs for each rejected material. The saved
README is the recovered reference brief. A separate approved wall mockup has
not been located; the two rejected RGB/checkerboard ImageGen previews are not
references or assets for this work.

## Measured failure at the existing anchors

`audit_native_elbow_fit.py` measures alpha >= 250 in the existing PNG. It writes
`native_elbow_fit_audit.json` and never writes artwork. It holds V3's 64px tile,
55px visible bedrock leg, 8px floor overlap, and one uniform `55 / 243` scale.
The horizontal arm center is measured immediately before the bend (native
columns 256–340); the vertical center remains the V3 profile's 511.5px.

The resulting physical NE grid vertex maps to native `(597.65, 486.35)` and has
alpha 0. Samples 8px inside either solid edge, including the diagonal `(−8,+8)`,
also have alpha 0. The nearest opaque native elbow pixel is about 20.5 world
pixels away (20.44px using the unrounded source coordinate). Translating that
pixel onto the physical corner requires roughly
`(+16.4, −12.1)` world pixels and breaks both adjoining arm anchors.

Therefore this placement is rejected before integration. Drawing it directly
would expose the square wall mass through the elbow's curved outer silhouette.
Moving it outward would swell the visible corner and change floor intrusion.
Clipping away that mass would make part of the still-solid grid corner appear
walkable; scaling separate axes would distort the approved art. None is a
valid completion of the proposed correction.

This is a bounded failure of this measured placement, not proof that every
possible native mapping is impossible. No changed renderer needs a slot, and no
rendered V4 candidate or performance gain is claimed.

## Next acceptance gate

A future mapping must first demonstrate a native elbow placement that covers
the physical corner while joining the existing arm positions at a uniform
scale. Then render its exact change against V3 at 1696×780, with the intact and
excavated bedrock boards first. Inspect the top-right four-turn corner near
`x389–409/y98–164`, every stair turn, the one-cell pillar, narrow column and
excavation. Grain must turn continuously without a square mass wedge, cropped
edge, larger stamp, or hidden collision. All other directions remain visible
and require separate acceptance; this one upright PNG cannot be treated as
four approved directional elbows by rotation or mirroring.

Voidstar still shows the rejected large repeated side clusters at
`x620–696/y100–610` and `x1496–1592/y98–311`; no new source samples were substituted.
The five previously accepted material boundaries and the Rootwound, Moonglass,
Emberdeep and Mossvein profiles remain byte-identical. Any eventual broader
candidate needs those boundary, topology and rebase captures again, followed
by real mining/travel and separate performance/device evidence.
