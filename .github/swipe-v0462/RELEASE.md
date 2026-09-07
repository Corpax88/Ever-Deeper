# Ever-Deeper 0.46.2 — Swipe browsing

Mats requested side-to-side swiping instead of the previous/next arrows in menus.
The shared CommercePanel now removes those controls. A horizontal gesture over
its showcase, item strip or detail area selects the next or previous item once,
with a short eased item fade. The selected card and detail panel stay in sync.
The counter includes a short swipe hint. The original authored metal artwork,
item cards, action controls and shop layouts are preserved.

Vertical gestures remain owned by the existing finger-scroll containers. Axis
locking, drag thresholds, first/last-item bounds, canceled-touch and focus-loss
cleanup prevent unintended navigation and button activation. Desktop mouse drag
also browses; existing taps and wheel input remain available. No change to pet
tabs, economy, equipment stats, assets, progression or save schema.

## Verification
- 859 existing gameplay checks pass against the exact production PCK.
- Native exported menu checks: 24 DEV and source production 22, all pass.
- Production flavor: developer menu and resource absent; production save identity preserved.
- Compared every packed resource with v0.46.1: only changed scripts, script remaps,
  UID cache and project version metadata differ; no resource was removed.
- Browser and visual results are recorded in review.json after inspection.

## Source and distribution
The editable source baseline is Ever-Deeper-v0.46.1-source.zip,
SHA-256 da25d581f7651165272914376ef1e2bfef6a4add8ce7e95555c2ed587b8d77f9.
source.patch includes the complete change against that baseline. bundle.json
reconstructs the reviewed exact DEV PCK from current public production, then
production from DEV, preserving existing web runtime bytes and mobile HTML shell.
The publishing workflow backs up both public builds, verifies baseline hashes,
deploys the reviewed artifact atomically and verifies all 18 public files.
Do not infer publication from this document; require the final publication receipt.
