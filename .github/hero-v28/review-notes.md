# Gruvepappa v28 — DEV8 review

The approved native Blender v28 character replaces the old hero in all eleven existing
gear families. The short hair, fitted helmet, rectangular dark glasses, user-approved
head shape and dark brown eyes are retained. Existing native tools and working grips
are attached to real idle, walk and mining poses; these are not AI-generated sprites.

There are 5,472 genuine Cycles animation frames and 5,472 cloth masks, packed into the
original 160px cells. Crusher retains its 96 mining frames. The maximum native grip
error is 0.0000006002 Blender units; no frame touches its crop boundary. The corrected
projected anchors place the boots on the existing game shadow. Runtime player logic,
gear selection, recoloring, saves and gameplay are retained. No 3D runs on the device.

The candidate includes main 3efdef1 and its reviewed DEV7 floor composition. The PCK is
219,164,200 bytes, 230,528 bytes smaller than DEV7. This is not a physical-device FPS
measurement. No iPhone performance claim is made.

## Package evidence

Source: 2e8e165b7f236c854357d0440c007d74b03e7f12.
Candidate artifact: 10072521163 from run 34267571804.
PCK SHA-256: d342642443ca76d46f465f1883f68ff9ea226e9e79cea5330e00c74e37e01378.

The ten current source/gameplay cases pass, including 859 gameplay assertions and
123 touch/shop assertions. Both DEV and production flavor checks pass. Actual Chromium
WebGL2 at 932x430 also passes the rendered gameplay suite (859 checks).

The original environment job requested a nonexistent 217th state. Starfall has no
second-depth gate, so the actual matrix contains 216 states. Run 34268226702 captures
the 24 environment states (193–216) from the exact same candidate artifact successfully.
The original motion runner timed out because its single still capture had no intermediate
capture marker. Actual damage events now count as progress; run 34268469537 records all
12 real mining combinations successfully using the same artifact. Neither failed original
job is counted as a pass, and neither correction changes the exported game package.

Environment captures 193–216 have been inspected at full mobile resolution. The new
hero fits the terrain and light in Mossvein, Moonglass, Emberdeep, Starfall, both depths,
all available depth-two gates, transitions and Endless permanent walls. Boots meet the
ground and the green/brass/leather palette remains distinct under warm and cool lighting.
The final motion recording was inspected across worn, Crusher and Deepcore. Head and
helmet stay attached; both hands track the tool, including support under the drill.

All 216 final-package captures have now been inspected: every gear, four directions,
idle/blink/walk/impact, five outfits, all worlds and all 24 selected environment states.
Garment recoloring leaves skin, hair, eyes, leather and brass intact. Blinks close the
eyes without displacing the glasses; head, helmet, backpack and grips remain attached.
The approved character is recognizable in the actual mobile view, with boots grounded
and materials consistent with the native source. Visual review is complete; the DEV-only
publisher stages these exact nine reviewed files and preserves all nine LIVE files.
