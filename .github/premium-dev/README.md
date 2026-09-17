# DEV11 immutable playtest publication

Source: 8f5680defb9083bbe1e044d39a10612f2186e7f3.
QA:35186932201. Version:1.0.0-dev.11.
Publishes the exact reviewed candidate and preserves all nine LIVE files.
The previous successful DEV10 receipt is copied unchanged to baseline-dev10-receipt.json; both previous packages are retained for rollback before deployment.

Simultaneous pickup labels and achievement feedback now preserve readable placement around the hero and mobile HUD; labels remain above ore actors. Existing artwork, amounts and lifetimes remain intact. A bounded audit also removes unused portable-base data and code remnants while retaining the modern workshops, relics and inventory.

All 14 immutable QA jobs pass:15 core suites, both export flavors, nine Chromium suites, Mac WebKit gameplay/pause and native residency. The same package passes 346 feedback checks with eight actual images, 47 hazard lifecycle checks and 58 commerce residency checks. Independent visual readiness must be recorded in review.json before the publisher can stage anything. The publisher's 11 offline checks also use the real downloaded artifacts and API receipts.

This is a bounded DEV playtest. Stable 50 FPS, physical iPhone, world joins and complete all-tool animation quality remain open. Camera and compact-corner experiments were not adopted. LIVE remains 0.46.9; this adapter cannot publish a new LIVE package.
