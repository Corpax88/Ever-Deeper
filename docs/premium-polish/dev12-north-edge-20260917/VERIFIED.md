# Exact DEV12 package verification

All 14 jobs in QA 35203069938 passed on attempt 1 at runtime source
`580a2e02eca1e000f5d5f58bb61ac09fd4b2a194`. The complete report has 13 passing
units and no errors. All 15 raw QA ZIPs were checked against actual API size,
SHA-256 and CRC; every extracted member was hashed, and all ZIPs were rehashed
after a delay. The local aggregate exactly equals CI.

| Check | Result |
| --- | --- |
| Core cases / export flavors | 15 / both passed |
| Chromium gameplay | 1273 checks |
| Chromium touch | All six sections passed |
| Shop images | 19 original captures |
| Mac WebKit | 1265 gameplay and 9 pause checks |
| Commerce / feedback | 58 and 346 checks; 6 and 8 images |
| Hazard lifecycle | 47 checks, 8 images |
| New north-edge package fixture | 3 images, 53135 changed pixels, 40 actual B production draw calls |

The independent critic accepted the bounded north correction after reviewing
all three originals and both endpoints. The review SHA-256 is
`9a1efec68b0218867ecd23ce8c0ddacc2accbb6d817913c0235522f070dfcf69`.
Root authored the integration and disclosed that authorship; root also viewed
the actual package B image and the prior seven source A/B pairs.

The first local suite-verifier invocation lacked its required run-ID environment
and failed before binding. The corrected invocation passed. The first local
publication-binding script compared reserialized staged JSON bytes to the
publisher's original review-file digest. That assumption failed; corrected
checks prove the original file's exact digest and equal staged JSON content.
Neither local invocation error is a game or CI failure.

The publisher's 11 existing tests passed with real package/API inputs and reject
missing or incomplete north coverage. All three actual publication jobs passed.
See [PUBLISHED.md](PUBLISHED.md) and the raw receipt for public byte verification.

The new animation study, rejected art/performance studies and physical-device
acceptance are outside this publication. The protected player_visual baseline
mismatch remains documented; no source assertion was weakened to hide it.
