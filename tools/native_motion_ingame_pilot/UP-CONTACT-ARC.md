# Target-bound Worn/up contact investigation

This is a diagnostic proposal after the five native poses at `7f1b22c4` failed
the contact-readability gate. Their originals and independent rejection remain
preserved. Nothing in this investigation changes the runtime, pilot consumer,
existing atlases, mining selection, damage or clocks. No new contact arc has
been rendered or accepted.

## What the actual replay establishes

The original up replay selects `endless_d000002_node_006`, a deep-alloy node at
`(1760,1568)`, while the player stands at approximately `(1696,1648)`. A separate
headless query reproduces the exact generated world, resource HP, terrain and
route, and binds the actual resource texture. The committed target is 64px
right and 80px up. The world then quantizes the target vector to cardinal `up`
for the current visual. A direction name alone does not carry this target.

At real HP-change frame 50, the native candidate's drawn 160px cell includes
its retained `+4.29385662` Y offset. The actual ore rectangle maps into that
cell's 200px native coordinates as approximately
`(130.236,-8.792,109.200,109.200)`. No offset is applied twice.

Native mesh rays distinguish the two failures. The original native shaft is
almost parallel to the camera ray (dot `.979593`) and projects only
`13.8615px` per native unit. Both lateral variants retain that orientation.
The torso/roll probe exposes 50 of 95 projected head pixel centers, but its
head remains a thin fragment in the actual images. Its projected tool has no
overlap with the recorded ore alpha. Existing DEV11 also presents its up tool
to the left of this upper-right ore; this alignment issue is not new-only.
These are bounded projection results, not native ore collision measurements.

`query_up_contact_target.gd` reads the normal generated target.
`map_up_contact.py` measures the original native, rejected lateral/anatomical
and production DEV11 contact poses. The first mapping attempt failed while
requesting native foot metadata from the older production pose. It remains
intact; the corrected report records the actual evaluated legacy foot matrices
and distinguishes the schemas. The exact production manifest is explicitly
pinned, independently of the pilot bank's hashes.

## One proposed native contact arc

The proposal explicitly replaces the earlier fixed-shaft-axis constraint.
The approved camera's actual ground Jacobian maps the selected `(64,-80)`
screen target to native heading `-69.24495°`, an upper-body change of
`-24.71846°` relative to cardinal up. It keeps the original cardinal-up leg
chains, foot matrices/contact flags and physical root. The torso/head and real
arm/tool frames aim toward the existing target. No whole-image rotation,
camera change, mirroring or pixel deformation is involved.

The bounded contact candidate uses torso-local rear grip `(-.12,-.40,1.00)`,
shaft pitch `-10°` along that target heading, and a genuine `30°` shaft-axis
roll. The original target-facing native windup blends into those contact
parameters from phase `.40` to `.55`, holds through `.625`, and recovers by
`.82`. Mining phase `.55` remains the intended impact sample; gameplay still
owns its existing `.68s` cycle and `.42` hit fraction.

`target_contact_pose.py` contains only this diagnostic pose construction.
`probe_target_contact.py` checks target geometry and native limb reach. The
selected curve passes 135 target poses, maximum reach `.64080042 < .71`, with
unchanged `.36/.35` arm lengths and exact original lower-body pose fields.
Its shaft projects `38.3066px` per native unit. A head extremum projects within
`.029px` of an opaque ore sample. That last number is only a reach heuristic:
it does not identify the working tip, the ore's physical surface, the approach
direction or the instant of impact. It is not a contact or readability gate.

Before a new image trial, identify the intended working tip on the actual
native head, bind its surface/normal, evaluate its approach across the contact
phase and check the actual native rig and part-specific occluders. A rotated
head that shows its blunt side or reaches an interior alpha sample too early
does not satisfy the intended strike. No full bank follows target math alone.

## Proposed presentation boundary

The world remains the sole owner of target selection, committed swing,
progress, impact serial, damage and cancellation. A later opt-in adapter can
publish read-only presentation metadata after the world's normal update:

- Existing target ID, generation/depth identity and committed world position.
- Stable swing-start identity, the unchanged progress and impact serial.
- Actual player transform, cardinal movement direction and the usual input
  and physics-frame identities already required by the presentation contract.

The visual may derive a native aim/contact pose from those fields. It must not
choose another resource, move the actor or target, enlarge reach, delay input,
restart a mining clock or issue damage. A turn/cancel/new swing is whatever
the world reports. Unsupported target geometry and transitions stay explicit.
This document does not add a new gameplay owner or implement that adapter.

The initial evaluation remains this one frozen, normally selected Worn/up
target. A clean checkpoint, native grip/sole/surface evidence, five original
images and independent visual review come before any bank expansion. An
ordinary-world replay must then verify real adjacent poses, unchanged HP and
timing, and recognizable tool contact. Arbitrary targets, bridge interruptions,
turns, other gear, mine48 cadence and runtime cost remain separate open work.
