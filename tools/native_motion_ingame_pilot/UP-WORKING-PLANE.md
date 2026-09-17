# Unapproved Worn/up working-plane study

Historical status: this v1 was rendered at `354bc9bd` and independently
rejected for hidden shaft/pick at contact. Its original images and reviews
are preserved. No v1 in-game trial followed. The later five-pose anatomical
investigation is separate: [UP-ANATOMICAL-PROBE.md](UP-ANATOMICAL-PROBE.md).

This isolated branch starts from the exact in-game pilot fixture
`f34bf7486f560ba104c137009a5affe50d2a642b`, whose ordinary runtime remains
published DEV11 `8f5680defb9083bbe1e044d39a10612f2186e7f3`.
The right pilot was accepted for bounded continuation. The up pilot was
rejected for mining readability; no original evidence is replaced.

## Source cause and one candidate

The correct up atlas and ground anchor were loaded. Native schema 2 rotates
every state into the actual up ground heading, −44.52649443596227 degrees in
the approved up camera. This makes the model squarely back-facing. The older
approved up poses retain a more readable three-quarter working silhouette.
In the new atlas, the body occludes the arms and shaft through mining
phases .125–.625, including the real HP-change frame 50. This is a visibility
failure, not evidence of a detached grip or a physically missed target.

The single candidate is an explicit `--native-up-working-plane` exporter flag.
It changes only Worn mining poses in the `up` view, plus the existing native
bridges that sample those poses. It translates the rigid tool/hand targets by
local `(-.20, +.10, 0)` in the unchanged ground heading, then re-solves the real
native arms. The world-space displacement is approximately
`(-.07246136, +.21154043, 0)`. It projects to `(+11.03449, +3.17475)` pixels at
the existing 160px packed scale. This is a modest lateral stance and slight
retreat; its actual visibility and ore contact remain to be judged.

The native torso/head, tool axis/normal, complete hip/knee/ankle chains,
foot rotation matrices and contact flags are kept from the original pose.
The arm solver's reconstructed leg fields are discarded. No model, geometry,
material, camera, light, atlas crop, ground anchor, runtime scale, world
position, collision, input, timing or damage owner is changed.
Moving the rigid tool also moves its tip; preserving its aim does not prove
the same contact point. Revised actual world frame 50 and adjacent poses are
mandatory before contact/readability acceptance.

## Exact scope and constraints

The exporter and `native_motion.py` are the only existing source owners
changed. The production player and pilot consumer are unchanged. With the
flag absent, all previous behavior remains active. With it enabled, other
gears, right view and up idle/walk poses remain exact controls.

Keep the original export declaration `right,up`, `idle=1,walk=16,mine=16`,
40Hz bridges and source phases idle 0 / walk .625 / mine .625. The exporter
uses the longer view duration for shared bridge sample counts; changing the
declaration to up-only would change that bank. Thus the trial renders the
same 96 native poses, including the unchanged right control. This is not
broader input or direction coverage.

Dense target checks compare against the exact rejected source SHA256
`54b2eae8ecc6b335b8c4bccdff26c2700ce4009e7215d6397d698cfd7c0f86a3`.
They cover 135 canonical mining phases and 129 samples in each of the three
existing bridges for both views. Protected pose fields, sole points,
transition timing and retained offsets must match exactly. Native upper/lower
arm lengths remain .36/.35; reach must stay below .71−.00001, with no clamping
or stretching. The separately evaluated native rig must retain matrix and
hand/tool attachment errors below .00001.

The exploratory 31-offset reach probe is preserved as a diagnostic. Its first
report incorrectly called unchanged ankle endpoints unchanged sole orientation.
That report is not sole evidence; the source annotation is corrected and the
actual candidate checks full leg chains, foot matrices and sole points.
Constructed .145 grip spacing also does not prove evaluated hand attachment.

## Gates and remaining limits

Before native rendering, checkpoint these source files remotely and verify
the ref/tree and local identities. Preserve every failed result. Headless
target/rig checks establish constraints, not visual acceptance.

Then render the actual native frames once, pack them with the unchanged
native packer, and inspect the new up atlas against the rejected atlas. Only
if coherent should a separately checkpointed fixture asset manifest consume
the new bank in the same ordinary-world input route. The old up candidate and
the actual DEV11 baseline remain preserved comparisons. Full native captures
must retain input events, mechanics, source-phase crossings, frame hashes,
cloth masks and actual image bounds. Independent review remains required.

Mining density stays 16 to isolate this anatomical change. A later separately
identified 48-sample trial must account for changed nearest-phase selection:
the old 16 bank displayed .625 while the requested phase was about .60446;
a 48 bank would still display .60417 and reach .625 a frame later. Do not call
those traces identical or guess an unsupported transition source.

Arbitrary input, turns, release/recovery, mid-bridge interrupts and retained
offset release remain uncovered. The next normal-input design needs explicit
exact displayed source poses, including interrupted bridge poses; a finite
canonical-only bank does not solve that closure problem. Physical input and
damage must remain immediate, without waiting for a convenient source phase.
No production adoption, full animation score or sustained FPS claim follows
from this study.
