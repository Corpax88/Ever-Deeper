# Tool Forge appearance correction — DEV8

Crusher was equipped in the shop but resolved to Burrower whenever a drill was owned. Explicit workshop appearances now select their existing authored pickaxe model before the default drill fallback. Original retains the actual drill tier. Mining power, speed, reach, recipes and saved progression are unchanged.

The intentional protected change is `scripts/player/hero_gear.gd`; all other protected files retain their hashes.

- Prior SHA-256: `deab85b9d958f0a3da455b1f426315716e34c8fc629e22419732334a02dd6961`
- Corrected SHA-256: `662a29dc0e13ca01d7e684e7e1e6290aadd1f04750e057dffee0063fb1a9f5b8`

Migration coverage exercises saved Crusher, all four appearances with all three drills, restoring Original, and unchanged mining stats. Native review exercises real shop equip, Hub and held mining with each appearance.

Exact-package visual review and DEV publication are pending. No final 1.0 or LIVE approval.
