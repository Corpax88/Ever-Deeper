# Saved graphics settings — DEV15.13 and LIVE1.0.1

User explicitly requested Settings in both LIVE and DEV: Performance, Balanced,
Quality; no explanatory setting text. Balanced is default and choice persists.
Authorization covers publishing both after verification. This supersedes the
prior LIVE-untouched constraint for this settings-only change, not a wholesale
promotion of DEV gameplay or experimental optimizations.

Source d7aeb10b087bca58a240ee7c78da38304fabe9f3 on
codex/graphics-settings-20260927. DEV starts with accepted DEV15.11 immutable
music-candidate10925867913, preserving music fix. LIVE starts with pinned public
LIVE1.0.0 bytes and its original premium_menu source28667f9796d386472f021771ed9336223efe0a48.
Only Settings UI/version and HTML graphics preference bridge change in LIVE.
DEV diagnostic DPR buttons are removed; the ordinary Settings row replaces them.
No AI, shadow, terrain, audio or FPS experimental patches are included.

Modes map to DPR1/2/3. Separate origin-local keys ever_deeper_graphics_dev_v1
and ever_deeper_graphics_live_v1; invalid/unset values fall back to2. Storage
failure preserves session selection. Existing game saves are untouched.
DEV report window flushes before graphics change. No extra descriptions, no
automatic FPS overlay. Active selection has an exclusive pressed state.

Mac WebKit validation36352372852 passed DEV first, then isolated LIVE candidate.
Real touches select1/3/2; each survives full page reload with matching pressed
state, actual canvas and GL buffer dimensions. Default2, blocked-storage fallback,
normal New Game and actual player movement pass for both. No runtime errors.
Evidence10942663478; exact dual candidate10942907152. Root inspected both Balanced
settings captures and both actual gameplay captures. Not a physical-iPhone test
of this new saved preference, not a new60FPS claim. Do not repeat these checks.

Publisher pins both manifests, candidate digest and successful test source;
retains prior LIVE/DEV rollback, preserves Worn9 bytes, verifies all27 public
files. Publication36352688179 succeeded: all27 public files verified.
Receipt10942313304; rollback10942881620. Publication commit
c93e6d9656d24f1294b01aae71e695fbbd6a4838. After successful publication the requested
settings task is complete; broader FPS optimization remains a separate task.
