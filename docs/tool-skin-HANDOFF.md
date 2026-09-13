# Tool Forge appearance correction — DEV8

Crusher was equipped in the shop but resolved to Burrower whenever a drill was owned. Explicit workshop appearances now select their existing authored pickaxe model before the default drill fallback. Original retains the actual drill tier. Mining power, speed, reach, recipes and saved progression are unchanged.

The intentional protected change is `scripts/player/hero_gear.gd`; all other protected files retain their hashes.

- Prior SHA-256: `deab85b9d958f0a3da455b1f426315716e34c8fc629e22419732334a02dd6961`
- Corrected SHA-256: `662a29dc0e13ca01d7e684e7e1e6290aadd1f04750e057dffee0063fb1a9f5b8`

Migration coverage exercises saved Crusher, all four appearances with all three drills, restoring Original, and unchanged mining stats. Native review exercises real shop equip, Hub and held mining with each appearance.

The first two native review runs (34727200071 and 34727654611) were rejected: the new fixture moved directly to the Hub without ending the active descent. The next descent was correctly refused, leaving the mine button hidden. The fixture now uses the real Tunnel Home transaction and asserts phase plus completed descent state. Extra waiting alone did not fix it. Runtime code is unchanged by these fixture corrections.

Exact-package review is complete: all six jobs pass in run 34728099178; 1016 native assertions and 22 skin captures pass. The author inspected 16 affected images at mobile viewports and accepted the existing models. See [visual review](tool-skin-review.md) and [evidence](tool-skin-evidence/review-index.json).

Publish only candidate artifact 10308746307 (source 800a993e206be5b381df4709c74dcb2bb72140b8). DEV8 is published and verified at https://corpax88.github.io/Ever-Deeper/dev/?v=1.0.0-dev.8. Publication run 34728884989 passed package, deploy and verify. All eighteen public files match: DEV is the reviewed artifact, and all nine LIVE 0.46.9 files match the previous receipt.

Receipt artifact: 10308093269; receipt SHA-256: `194db3eb75dad0ddc41e445c5b6698ea1f7c9c2bdcc073c3b85cd01e2a21a7ff`. Rollback artifact: 10309081710. The durable receipt is `.github/one-point-zero/tool-skin-publication-receipt.json`.

Use the existing DEV save and equipped Crusher; refresh the game to load DEV8. No save reset or new purchase is required. No final 1.0 or LIVE approval.
