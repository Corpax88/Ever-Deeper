# Ever-Deeper — FPS audit round 2, 28 September 2026

Mats explicitly requested a second team investigation for other candidates. The depth-prepass candidate is PARKED: do not enable, publish, or repeat it as part of this round. Keep its prior evidence: branch `codex/depth-prepass-audit-20260928`, source `1c3f5c552cff462cb0da74041e85e16762a524ce`, run `36392214186`; fourteen pixel-identical pairs, mixed browser timing, no physical-iPhone acceptance.

## Exact baseline

Public DEV remains 15.16. Immutable `surface-probe-candidate` artifact 10952875555, run 36380070907, source 0225855d5b243fadf75c5267898ac2cd6edb3d0b. Artifact ZIP SHA256: 06e46692f2224518997516a9c14cfe32a82ef611cafa23da5f503ca585ab8c18. PCK: 262003869 bytes, SHA256 ee5a77d6c0b15d84bb1b44c85f1aa777aeb555293e0ba11747a400d6bc9a4d72. Current public PCK and engine JS were retrieved and verified against the immutable baseline; all 1427 PCK resource digests passed.

The audit uses a separate branch `codex/fps-round2-20260928`. The root repository runtime can be older than the additive PCK patches. Resolve active remaps before attributing a finding; in particular, DEV15.14 installs the stance runtime from `.github/hero-stance/runtime_motion.gd`.

## Scope

Investigate hero CPU work, world/companion CPU work, and browser/render synchronization. Preserve approved graphics, resolution, lights, animation, gameplay and saves. Diagnostic source substitutions are isolated in the QA package. No production publishing is requested by this round.

## Candidate status

- Hero contact-search invariant calculations: code-backed hypothesis for mining-start/retarget hitches; not an explanation of stationary surface FPS.
- Immutable inverse-rest transforms: code-backed candidate for per-frame CPU work; total FPS benefit unmeasured.
- Companion collision queries inside one synchronous path search: code-backed candidate for navigation hitches; retain identical path/search order.
- Repeated framebuffer validation: separate read-only call/mutation/timing profile; do not bypass WebGL validation speculatively.

Measurements and final dispositions will be appended after the bounded checks. No physical-iPhone improvement is established.
