# DEV 0.46.9-dev.4 — Teamwork fix

Published and all 18 public files verified on 2026-09-08. LIVE 0.46.9 is byte-identical; DEV contains the Teamwork null-state guard. No diagnostic pet instrumentation was released.

QA: all ten current gameplay cases, build flavor, protected files, native captures and mobile WebKit passed. All skills learned in the hub test for more than 30 seconds. Exact package source 20f4a0354ef98c0a2d052e105611760739fd4298; publication 8de53f2259fa87e65b538273e1ddf48d4bd86881. See review.json and publication-receipt.json for hashes and runs.

Confirmed: Teamwork previously threw repeated bool(null) errors in hub. The 22 pet-skill native tests and two actual-dig controls are documented on codex-pet-skill-performance. Physical iPhone's delayed ~30-second FPS collapse remains unconfirmed as fixed. Next: compare the user's same hub/Mossvein situation on dev.4; preserve graphics and investigate remaining device-specific slowdown if it persists.

Test URL: https://corpax88.github.io/Ever-Deeper/dev/?v=0.46.9-dev.4
