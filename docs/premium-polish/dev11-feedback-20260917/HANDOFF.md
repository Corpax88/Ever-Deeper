# Feedback coordination — unpublished work

This work continues the verified [published DEV10](../dev10-20260917/PUBLISHED.md).
Work branch: `codex/dev11-feedback-20260917`. The runtime label remains DEV10 until
the new candidate is accepted and given its own package identity. This checkpoint
is not published and has not yet passed its rendered regression gate.

Observed defect: simultaneous Waystone, Memory Silk and Deep Alloy pickup labels
overlap the Rune Ready achievement in the actual moving Deep capture. The change
coordinates the existing achievement with the visible pickup text, hero and HUD.
It retains the approved icon, title, font, transparent presentation, touch target,
resource values, merge behavior and feedback lifetimes.

Owners: `scripts/main.gd`, `scripts/ui/achievement_toast.gd` and
`scripts/ui/resource_pickup_burst.gd`. Pickup text dimensions are cached when the
text changes; their bounds use the actual camera and animated transforms. The
achievement keeps its chosen offset while clear. Crowded placement searches are
bounded to 80 candidates and unresolved layouts retry at most every 200 ms.

`tools/review_feedback_overlap.gd` is the actual rendered regression fixture.
Pending checks include the exact published DEV10 PCK as a negative control,
simultaneous merged pickups, camera motion, zoom, mobile edges, actual tap,
natural expiry, retained placement and observed normal/crowded layout cost.
Parser checks passed; that is not visual or gameplay acceptance.

The camera-bounds performance experiment is separate and is not adopted here.
Stable 50 FPS, physical-iPhone feel and full premium-polish acceptance remain open.
Mats has already authorized code uploads and gated DEV publication. Preserve LIVE.
