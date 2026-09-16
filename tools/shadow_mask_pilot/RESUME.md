# Paused caster-mask proposal — 16 September 2026

Stopped at Mats's explicit request to save quota and package playable work.
**No mask candidate was written or run. No runtime change was adopted.**
This folder contains this resume note only.

## Evidence preserved elsewhere

- `evidence/shadow-contour-20260916/parity-1`: contour aim-3 differs in 369
  pixels, maximum RGB delta 4, alpha unchanged; restored control is exact.
  Every changed pixel is darker in B, in sparse diagonal rays at x113–312/y0–77.
- `parity-2`: independently checked all eight complete A/B/A2 image sets;
  every pair is exact. Real depletion changes the actual caster geometry.
- `parity-3-original-fixture`: retaining original rectangle vertices still
  reproduces the same 369-pixel failure in the original fixture. No timing.
  The second fixture changed camera/entry state and two original caster spans,
  so its passing result did not close the first failure.

The vertex-retaining contour helper still shortens exposed parts of original
edges: aim-3 has 62 exact native directed edges and 29 strict subsegments.
Godot extrudes each segment into two triangles, interpolates shadow depth and
uses binary depth comparisons in PCF5. Geometric ray equality therefore does
not establish raster equality. Adding interior bridges preserves original
segments but adds new triangles whose endpoints have zero boundary clearance;
strict parity at grazing angles remains uncertain. Do not adopt either contour
version or relax the gate.

## Proposed next isolated test, not implemented

Subclass `scripts/lighting/cave_light_occluders.gd` under this pilot folder;
call `super.refresh()` and retain every original four-point rectangle exactly.
Do not copy or replace the production geometry owner.

Use **LightOccluder2D.occluder_light_mask**, not its inherited receiver
`CanvasItem.light_mask`. Reserve bits 15–18, one per managed cone/bounce light;
preserve StaticLightField's bit 19 and every original lamp shadow-mask bit.
Add the reserved bit to that lamp's `shadow_item_cull_mask`; managed casters
receive only the bits whose existing conservative `_source_cell_bounds()`
intersect their full rectangle, including touching borders. Receivers and
`range_item_cull_mask` stay unchanged. Estimate submissions as four times the
eligible caster/light pairs; the normal canvas counter omits these calls.

Required safety/ownership checks before any rendered test:

- Discover same-canvas lights/mask users once; maintain node additions/removals.
  Check only the small cached light set on ordinary refresh. Unknown enabled
  shadowed lights, conflicting reserved bits, or too many lights restore full
  baseline caster masks and remove only bits the pilot itself added to lamps.
- Refresh memberships when **per-light coverage** changes even if the merged
  rectangle signature remains equal. Also invalidate on light identity,
  enabled/visibility/shadow flags, original mask and lifecycle changes.
- Restore pilot-owned bits on hide/disable/exit; never overwrite non-pilot bits.
  StaticLightField can restore actor masks, so re-establish only owned bits.
- Godot has no CanvasItem light-mask-changed signal. Arbitrary reassignment of
  an existing receiver into reserved bits cannot be detected without a scan.
  Current runtime writes only bit 1/bit 19. Document the reservation contract
  and provide explicit audit invalidation for fixtures/owner changes; do not
  claim protection against unobserved arbitrary mask mutation.
- Start with count reduction and the saved failing original fixture, then
  exact A/B/A2 parity across existing states. No timing before exact parity;
  include refresh CPU and moving costs before claiming an improvement.

No render or implementation should resume without the next session's task.
