# Change 01: keep the next destination visible on mobile

The HUD compass was retired, but the mobile goal ledger still hid its action/source line whenever resource costs were present. This left players with a target and counters but no visible instruction about where to obtain it.

Always show a nonempty next-action line, use the same mobile text size as the goal title, and reserve its height in HUD layout. Preserve the pass-through touch behavior and all goals/counts.

Validation pending actual candidate capture at667/844/932 CSS widths: early forge goal, multi-resource recipe and pinned treasury mod source. Check no overlap with controls or minimap and no clipping. This is a checkpoint, not a release or visual approval.
