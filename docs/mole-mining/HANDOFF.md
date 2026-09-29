# Slower commanded companion mining — 29 September 2026

User request: the mole must be able to mine the same materials as the hero, while active player mining remains faster.

Implementation: tap an accessible rock to assign one job. The mole continues without holding Mine, then returns to following/collecting. Tapping open ground, recalling, leaving the nearby area, world changes, or the target being finished cancels the job. Menu/pause suspends it. Basic commanded mining needs no extra companion skill. Existing Earthshaker and automatic Teamwork remain their original abilities.

Eligibility follows current hero equipment and exposed terrain in Depth 1, Depth 2, The Deep, and surface resources. Gates retain their equipment and ten-hit requirements. Bedrock/progression boundaries remain protected. Work hits reuse the world's reward, armor, depletion/respawn, discovery and persistence owners. No new save schema. No Crusher shockwave from ordinary paws.

Mole period is max(1.68 seconds, three current hero tool cycles). No instant destruction, no hero animation/stamina spending or mining-skill XP from these manual companion hits. Normal resource/prospecting/bond rewards remain. AudioDirector's optional train_hero parameter defaults true; only new manual companion paths opt out. All earlier audio cadence optimizations remain.

Source base bde8ead03852ed9722d217af0b50d01269eb362c plus byte-exact current text runtime from immutable DEV15.22 artifact11021180959/run36541177604. In particular, preserve the per-search collision cache in mole_companion.gd and current terrain code. Never export historical main. .github/mole-mining/build.py validates all nine baseline hashes and every unchanged PCK payload, then patches listed scripts/remaps and DEV version15.23 only. LIVE1.0.2 loading-rotation fix and Worn must remain unchanged.

Testing route: .github/workflows/mole-mining.yml on codex/mole-mining-20260929; Mac15 Apple GPU, Godot4.7.2, actual Chromium touch and ordinary WebKit. Tests use opt-in skills_browser_review fixtures only. No physical-iPhone performance claim and no reopening the parked FPS investigation.

Initial run36580808872 had passing input/premium-core and actual successful ore mining. Its new fixture incorrectly used hp3 assuming power1, and caught the shared audio helper awarding hero mining XP for companion sound. Corrected fixture uses three tool hits; manual audio now opts out of hero training. No failed package is published.

Final source, passing evidence, inspected images and publication receipt: pending completion. Continue authorized task through the final gate and DEV publication.
