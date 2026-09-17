# DEV12 work in progress

Published runtime remains DEV11 `8f5680defb9083bbe1e044d39a10612f2186e7f3`.
Branch `codex/premium-polish-dev12-20260917` starts at documented DEV11
`900d4841b2761f2f62fc259c52b748281ab924f2` and integrates only the independently
accepted upright Moss north-edge correction. Native full texture regions,
horizontal phase and world bounds remain identical. No art is replaced.

The exact isolated study `74a0f772b0445dc3dfe82a3ecc4f014400318dd4` completed
approach, blocked contact, real hit, mined opening, short steps and both
adjacent biome boundaries. All seven A/A2 pairs were pixel-identical, changes
stayed in eligible north-edge quads and all eight source phases changed.
Four strong-light cases proved normalized level5 and actual1.3/1.4 multipliers.
See [independent study review](independent-study-review.json).

Integration f2ce35f passed the held-pose gate and independent review. All53137
changed pixels have exactly the same signed effect as the accepted study.
Full images across runs differ35448pixels; do not claim full-frame identity.
The source gate first passed14/15 cases; a dummy-renderer null-texture error
stopped overhaul in unchanged Rootwound loading. Both an unchanged DEV11
control and the isolated candidate repeat passed, without runtime changes or
error suppression. The initial failed gate is preserved. The existing protected
player_visual baseline mismatch remains. See the attached source verification.

The candidate now labels DEV12 and adds the north actual-production triplet
to the existing immutable-package workflow. No other runtime change is added.
The reference fixture resolves beside the external script because tools are
deliberately excluded from the PCK. The pinned workflow uses the same absolute
package path for --main-pack and --pack-source and an empty host directory;
the fixture verifies its complete hash against the immutable build's expected
PCK_SHA256. Godot strips --main-pack from exposed engine arguments, as an
unchanged DEV11 package probe confirmed, so the fixture does not claim to
observe that argument directly.
Package acceptance and original image review remain required before publication. `tools/north_edge_release_review` calls the actual production
owner in B and exact legacy owner in A/A2; it is never loaded in ordinary play.
No new release has been published. The nine LIVE files remain fixed.

Game feel, all-tool coverage, new native motion, stable50FPS, other world joins
and physical-iPhone acceptance remain open. The rejected compact-art and floor
studies are not adopted. Preserve the evidence of both failed north fixtures;
neither was a production collision or lighting fix.
