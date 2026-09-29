# DEV15.25 — mole escape from respawned ore

Task: prevent the companion being trapped when renewable ore reappears, as reported in Starfall. DEV-only authorization; preserve LIVE1.0.2 and Worn.

Candidate source: e231cc934ac0d97d2799036b3b10c875aa1c3397 on codex/mole-collision-20260929. Built from immutable accepted DEV15.24 artifact11045262015 (validation36593885775), preserving every unmodified PCK resource byte. Never rebuild historical main.

Cause: depth-one ore respawn checks the hero's position only; companion routing used the hero's block collision predicate, so a newly restored resource could surround it. The shared depth-one world now exposes companion_collision_at, retaining bounds, barrier rectangles and all non-resource blocks. Only role=resource is ignored for the companion. Hero collision and mining/progression requirements remain unchanged. Depth2/The Deep use their existing movement contracts; no surface changes.

Regression: actual _update_respawns restores a real resource on the companion in Mossvein, Moonglass, Emberdeep and Starfall. Assert old hero predicate blocks it, companion predicate permits escape, terrain/bedrock/barrier/bounds remain solid, then command real movement out and retain before/after images. Existing manual mining across five contexts, automatic work, Earthshaker, menu pause and hero speed are also checked. Physical iPhone behavior remains user confirmation.

Validation36597423462 passed54 Chromium/AppleGPU checks, input/premium-core200 and ordinary WebKit startup/save/new-game. All21 actual PNGs inspected. Every respawn fixture starts at distance0 from the restored resource and walks out; old hero predicate stays blocked. First QA36596672657 exposed a deferred scene-spawn fixture issue during visual inspection; corrected test before accepting, gameplay unchanged. Historical invariant QA flag/docs mismatch remains explicitly failing.

Candidate11046229836 ZIPsha2567dc737dd8218196cbfe765bfda125a7b8ad20bfd681099e612bc935bbf220a5d. Evidence11046399192 ZIPsha256c90dbbbc6b7e407c2928333b601bf1382d4ea6cb0faa2aaf30cba87076ef4f14. PCK265131818bytes SHA2566fc396464be208c750018f1c2ffc8a18548771222610a72768fd35f27e1bdacf. Published and verified by run36598118833, commit65f1a6d33f9c39d43e801a0d9c01404549def82d. All27 public hashes verified; LIVE1.0.2 and Worn unchanged. Receipt11048400561; rollbackDEV15.24 artifact11047596328. No work pending. FPS parked; no physical-iPhone claim.
