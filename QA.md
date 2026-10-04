# QA registry

The ordered registry is `scripts/qa/qa_launcher.gd`; the first matching flag wins. `docs/qa-extraction.json` records that exact order and is checked by `tools/check_invariants.py`. The normal validation commands and historical contracts are in [docs/verification.md](docs/verification.md).

These four existing review entries precede `--qa-skills-browser`, in this order:

| Order | Flag | Suite | Purpose |
| --- | --- | --- | --- |
| 1 | `--qa-telemetry-review` | `telemetry_review` | Browser control of the lighting probe, interruption/cancellation, session report controls, and restoration status. |
| 2 | `--qa-fps-review` | `fps_review` | Deterministic mining render/performance fixture, cached/reference draw comparison, and frame/CPU timings. |
| 3 | `--qa-production-browser` | `production_browser_review` | Real production web feature/save identity, persistent boot/resume, and developer-resource exclusion observations. |
| 4 | `--qa-wayfarer-browser` | `wayfarer_browser_review` | Retired store contexts and the relocated Copper Ridge quarry. |

All four invoke `run` and have `surface: false`; their suites own world setup. They already existed in the runtime registry. The October 4 documentation correction adds the missing four entries without changing launch order or runtime behavior.

The full-quality candidate retains the existing input and premium-core gates. Its review-only package updates two premium-core expectations to require a claimed treasury goal to retire, while preserving earned ownership and enabled state. That assertion overlay is excluded from the production package.
