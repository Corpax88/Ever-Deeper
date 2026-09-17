# DEV11 immutable package and publication verified

[DEV11 is published](https://corpax88.github.io/Ever-Deeper/dev/?build=8f5680d).
[Publication run 35188991326](https://github.com/Corpax88/Ever-Deeper/actions/runs/35188991326)
completed package, deploy and verify successfully on attempt 1 at main
`53301dbf5da99ab7133e3d09e3593e821c60c941`. The actual post-deployment receipt
verifies all nine DEV files and all nine unchanged LIVE files. See
[PUBLISHED.md](PUBLISHED.md) and [publication-receipt.json](publication-receipt.json).

Source `8f5680defb9083bbe1e044d39a10612f2186e7f3`, tree
`48b24a93faaa6f77d7a53c404cfb1228d7f825e0`, version `1.0.0-dev.11`.
All 14 jobs in [QA 35186932201](https://github.com/Corpax88/Ever-Deeper/actions/runs/35186932201)
passed on attempt 1. The complete report has 13 passing units, zero errors.

The source UI change and bounded cleanup are documented in HANDOFF.md and
LEGACY-CLEANUP.md. No production artwork, animation, balance or save schema changed.

| Exact package check | Result |
| --- | --- |
| Core suites / export flavors | 15 / both passed |
| Chromium gameplay | 1267 checks |
| Chromium touch | Six sections, all passed |
| Shop images | 19 captures at 1696×780 |
| Mac WebKit | 1265 gameplay + 9 pause checks; actual darwin/WebKit26.5/Apple GPU |
| Native feedback | 346 checks, eight images, actual activation, natural expiry |
| Feedback maximum camera-relative displacement | Toast 11.817 px; pickups 11.858 px; both below 32 px |
| Native hazard lifecycle | 47 checks, eight images, zero paused drift |
| Native commerce residency | 58 checks, six images |

Candidate artifact 10481858878: 232599634 bytes, ZIP SHA-256
`82b9dc45b75c9f44a4a6b1afdf10e6ca3ca4207c750d1ada2643fe84d79b7858`.
Complete artifact 10481719990: 796 bytes, ZIP SHA-256
`187e920dc91e90e9913fff37ba4c7770e82db2d85a1ecebd081823d3fe0d7020`.
PCK 221013680 bytes: `5b77b3a219011cb676895e41830c8dab32bec2346db93102c7894a3c084414e9`.
HTML: `64a64a8d4c516e8ad5a1892077ccad2068d72f251a518d1ef513360fb037324a`.
Identity: `027b128fe5fa70d7814c0f0952ee06549f447afc9769426c3b5696c631579a7a`.

All 15 artifact ZIPs were downloaded and checked against their actual API size,
SHA-256 and ZIP CRC. A local re-verification of every raw suite using the actual
complete-job outputs produced an identical complete report. The first local
invocation omitted those job outputs, correctly failed the build-output binding,
and is retained as a verifier-invocation failure; no game or CI failure was hidden.

The implementation author's package review covers 25 actual original images and
discloses authorship. Root separately inspected all eight source images, three
exact-package feedback images and four shop images. A critic who did not author
the implementation independently approved all eight exact-package feedback
images plus motion, expiry and activation evidence, with no blockers; see
`independent-feedback-review.json`.

The publisher preserved the exact DEV10 receipt and both prior public packages
for rollback. All 11 offline checks passed before publication, including actual
candidate/complete archives, all 14 QA jobs, missing Mac/feedback evidence,
changed package/baseline rejection and preservation of all nine LIVE files.

The subsequent independent publication binding passed 102 checks. It matched
each DEV receipt size/hash to actual downloaded candidate bytes and each LIVE
entry to the actual preserved DEV10 receipt. It also verified the genuine
completed API jobs and critical publish/verify steps, candidate and complete
archive identities, publication evidence and receipt ZIP hashes/CRC, staged
file maps and rollback artifact metadata. This pass used the successful public
HTTP verification job's receipt; it did not download the public game files again
or rehash the large rollback archive.

Raw receipt: 5016 bytes, SHA-256
`7bd53dd44ace7e8a860f75160a99e6728238e04e1c1a39eedbdf398fb3ba4afa`.
Preserved DEV10 baseline receipt SHA-256:
`f23caaadffbc662061483dbd8c1d3336d1b32f856c066c3f5d2921217bf6576e`.
The verification report is
`evidence/dev11-publication/independent-verification.json`, SHA-256
`6d0bb4c7313f7cfb2cbac0eeb7d6d7fa80797f1153cb6038ec3f516c43867cf1`.
LIVE remains `0.46.9`; its nine receipt entries are unchanged.

Stable 50 FPS and physical-iPhone performance remain unverified. Prior DEV10 Mac
sessions failed the sustained 50 FPS target. New all-tool motion and opaque-floor
studies remain separate, with no production adoption or whole-game 9/10 claim.
The existing player_visual protected-baseline mismatch is unchanged.
