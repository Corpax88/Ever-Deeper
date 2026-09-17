# Five-pose native anatomical probe

The constant working-plane v1 at `354bc9bd04953f4e20e23c2eef87d1affe686ab2`
was rejected independently from its actual native images. The shaft and pick
remain hidden at contact. Its 96 beauty/cloth pairs, atlas, records and reviews
are preserved; no v1 in-game run or production replacement followed.

Evaluated 200px camera rays locate the obstruction: hair, rolled blanket and
backpack lid at contact; helmet in windup. These are native geometry samples,
not rendered pixel visibility or visual approval. The approved evaluated scene
has 629 rendered mesh objects and 2,714,340 triangles; no mesh or material is
removed or simplified here.

Three constant anatomical shifts improved windup but still left contact nearly
hidden. Increasing the constant offset failed reach during the high windup;
those failures are retained. The selected bounded stroke keeps the windup
closer to the body, and shifts the hands laterally as the native downswing
reaches contact. It uses a genuine wrist/tool roll around the unchanged shaft
axis to expose the otherwise edge-on pick head.

The specification is in `anatomical-probe-selection.json`: upper torso yaw
−45 degrees around its own pelvis-level pivot, with the head following its
neck position and counter-turning toward the original up gaze; local lateral
hand/tool plane −.35 in windup to −.50 at contact; retreat .10 to .15; rigid
tool roll 30 degrees. The contact weight is smooth from phase .40 to .55,
held to .625 and returned smoothly by .82. Torso/head and tool normal are
explicitly changed in this trial. The actual shaft axis, whole-character
heading, full original hip/knee/ankle chains, foot matrices and contact flags
remain unchanged. Both arms and rigid two-hand grips are re-solved natively.

The selected targets pass 135 phases with maximum shoulder/wrist reach
.6537191231 below .71. Evaluated geometric rays give tool fractions about
.901/.528/.566 at windup/contact/recovery, but only the actual native images
can judge whether this is readable. The rigid tip has moved and rotated with
the genuine tool; later contact with the actual world ore remains mandatory.

`render_anatomical_probe.py` reuses the exact approved exporter scene, model,
native gear, materials, camera, lighting, 200px beauty and cloth output. It
evaluates all 135 native rig poses and verifies real hand attachment before
rendering exactly five poses at .125, .375, .55, .625 and .8125. It never
changes production assets or the pilot consumer. Its `--validate-only` mode
creates no images; actual rendering requires the exact clean checkpoint.

These five frames are an anatomical image test, not gameplay, a complete
animation bank or motion acceptance. Do not render another full 96-frame bank
unless the originals show a recognizable windup, shaft and pick at contact.
The larger torso change also needs its own bridge reach, speed and timing
review; success here does not certify the earlier .051-second up entry.
Mine48 density, ordinary interrupts, turns/recovery, other new views/gears,
mobile runtime cost and full polish remain open.
