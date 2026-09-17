# Feedback coordination — source gate passed, export gate pending

This work continues the verified [published DEV10](../dev10-20260917/PUBLISHED.md)
on `codex/dev11-feedback-20260917`. Source
`cb1b865a795f17eb7960e4b8055bb205a4582edd`, tree
`cde8a3fe7b3e5e5c2b51706f1592ef1905b89348`, passed the bounded rendered source
gate. Root independently inspected all eight original-resolution images and
accepted this UI result. This source has not been published. Its runtime label
was still DEV10 during the gate; the accepted UI and bounded legacy cleanup will
receive DEV11's own immutable export identity before publication.

The original moving Deep capture showed Waystone, Memory Silk and Deep Alloy
colliding with Rune Ready. Review also found pickups over the minimap/objective
HUD and behind deeper ore actors. The change coordinates the existing pickup
stack, achievement, actual projected hero bounds and visible HUD rectangles.
It preserves the approved achievement PNG, title/font, transparency, touch target,
pickup font/colors, stack spacing, merged values and all pop/rise/fade clocks.
Pickup feedback now uses the top world Z within its existing canvas; the HUD's
higher CanvasLayer stays above it. No new art layer or material was introduced.

Owners are the narrow anchor function in `scripts/main.gd`,
`scripts/ui/achievement_toast.gd`, `scripts/ui/resource_pickup_burst.gd` and the
private shared `scripts/ui/feedback_placement.gd` geometry helper. Text dimensions
are cached on text changes. Group placement reserves the existing maximum 6%
pulse and 12-pixel rise and converts screen offsets with an affine inverse, so
camera zoom is respected. Both owners retain their selected offsets while clear.
The shared search selects with 32-pixel clearance and only reflows below the
18-pixel retention clearance; it examines at most 80 candidates and retries an
unresolved crowded placement at most every 200 ms. Pickups coordinate even when
there is no achievement. The first actual achievement anchor invalidates any
provisional placement made with the previous notification's anchor.

The actual rendered fixture is `tools/review_feedback_overlap.gd`, SHA-256
`f6d5ccbb0e345b48d5b048123d4e54c430bbc398a6e4291c528058f36511ec50`.
Local evidence is under
`/workspace/scratch/d5437d917805/evidence/dev10-feedback-overlap/`.
`source-cb1b865/source-identity.json` records and verifies the five source/fixture
file hashes against the saved commit; all five still matched after the run.
Every reviewed image's SHA-256 was also checked against the fixture report.

| Run | Result | Evidence folder |
| --- | --- | --- |
| Exact published DEV10 PCK | 346 checks, 30 expected failures, 8 captures | `published-dev10-expanded` |
| Current source cb1b865 | 328 checks, zero failures, 8 captures, 40 motion samples | `source-cb1b865` |
| Existing onboarding, iPhone layout and UI contracts | All three passed after the Node viewport correction | `targeted-source-qa-pickup-extension-fixed` |
| Existing world and migration cleanup gates | Both passed serially after rendering | `cleanup-world-migration-cb1b865` |

The negative control loaded only the exact published package from an empty host
directory, using the external fixture. Its PCK SHA-256 is
`8b83ed55d62841eac8e891ad6c224b101665d98f5ead63a022e66589d6266c3b`.
Failures reproduced achievement/pickup/hero collisions, minimap and objective
collisions, mobile safe-bound overflow and the DEV toggle overlap. The package
has 18 additional checks because its visible DEV toggle is checked against each
of three labels in six pickup states. Local source mode lacks that build feature;
the pending DEV export must verify that toggle as well.

The eight inspected source images are `01_simultaneous`, `02_zoomed`,
`03_left_edge`, `04_right_edge`, `05_lower_edge`, `06_pickups_expired`,
`07_camera_moved` and `08_pickups_without_achievement`. They use actual walkable
interior Deep terrain, the real player camera, 1696×780 / 1688×780 framebuffers
and zooms from 0.8 to 1.35. Label bounds are measured independently through
Label minimum size and actual canvas transforms. All three merged captions
remain readable and clear of the hero, HUD and safe bounds; the lower-edge
captions previously obscured by ore are complete. The camera/culling parity
correction removes the earlier fixture's gray edge strip. Natural pickup expiry
does not move the achievement, both feedback owners release their callbacks or
activation target as appropriate, and an actual GUI tap opens achievements
exactly once. The fixture never manually advances feedback animation clocks.

Across 40 rendered camera-movement samples, maximum camera-relative reflow was
7.3249 pixels for the toast and 7.4509 pixels for the pickup stack. Both remain
below the unchanged 32-pixel gate. Normal coordination p95 cost was 35–45 µs
over five 100-call samples; the largest single update was 574 µs. The 24-obstacle
fully covered viewport took 302 µs for its first search and 18 µs p95 over 100
updates. These are local function-cost samples, not an FPS claim. A fully covered
viewport still uses a bounded least-overlap fallback; it is not a guarantee that
physically impossible layouts can be made collision-free.

Rejected and superseded attempts remain intact:

- `source-12f9039` passed its first 110 collision checks but failed actual visual
  review: a stale initial anchor produced a large placement jump. Its retained
  motion samples show approximately 457.4 pixels of camera-relative reflow.
- `source-v2` failed the added movement gate at 112.9236 pixels.
  `source-v2-reflow-diagnosis` identified HOME's unchanged expanded rectangle
  `(893.818, 520.091, 242, 140)`: only 0.412 pixels of entry into its outer
  clearance triggered a roughly 121-pixel lateral reflow. The threshold was not
  weakened; slot selection gained the 32/18-pixel hysteresis.
- `source-v3-motion` was the first green toast motion control: 31 checks and
  11.1338-pixel maximum reflow. `source-v3-interior` then passed 121 checks with
  8.8270-pixel reflow, but pickup/HUD overlap, ore occlusion and the separate-camera
  culling artifact remained. The pre-extension state and those limits are
  recorded in `toast-v3-before-pickup-extension/checkpoint.json`; its archived
  fixture includes the subsequently prepared camera-parity correction, as the
  manifest explicitly states.
- `targeted-source-qa-pickup-extension` stopped at a main-script parse error:
  Node has no `get_viewport_rect()`. The one-line correction uses
  `get_viewport().get_visible_rect()`; the failed logs and successful rerun are
  both preserved.

The next gate is the immutable DEV11 package. Its exact-package CI must bind the
fixture hash and package identity, require all eight named images and at least
300 checks, verify both motion bounds, and run the integrated Mac WebKit gameplay
and pause checks with engine/platform receipts. The local source gate does not
replace that exported DEV build review. No new candidate export or publication
was performed by this implementation task.

The camera-bounds performance and corner studies remain separate and are not
adopted by this UI gate. Stable 50 FPS, physical-iPhone gesture/feel and full
premium-polish acceptance remain open. Mats has already authorized code uploads
and gated DEV publication. Preserve the nine LIVE files.
