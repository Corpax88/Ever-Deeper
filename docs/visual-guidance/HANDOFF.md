# Visual guidance / DEV15.58 candidate — not published

User requested research about where the eye looks in games, implementation in Ever-Deeper, clearer onboarding and an independent critic. Current public baseline remains DEV15.57 (runtime b8b7e0428c9aa2626861917f98b1b4b7d296f9e3), LIVE1.0.5. Source checkout is based on its documentation head406eeef. Never export historical main.

Research: RESEARCH.md. Production overrides are explicit in .github/visual-guidance/overrides.json, built on immutable DEV15.57 PCK SHA2565a97a3346dfb623d36b80bfb4b37feb8651ca48b60b6a91430a4202a103d7c79. Every other resource payload is verified unchanged; native art/hero/saves are preserved.

Environment restored: official Godot4.7.2 Linux ZIP verified by --version; task-local Ubuntu Xvfb/libxfont/xkb/libxkbfile packages and authenticated loopback Xvfb. Rendered at1334x750,1688x780,1864x860, Mesa software rendering. Not physical-phone or FPS evidence. Local input and414premium-core checks pass. Rendered walkthrough passed movement, idle, actual entrance/mining/pickup/Bag, actual funded upgrade, menu/save state roundtrip, replay and skip. First replay fixture hit a wall; later headless replay picked up real leftover ore earlier than expected. Fixture now accepts that real completion rather than assuming no pickup. Mac frozen final QA pending.

Current scratch /workspace/scratch/ada1db9371d3; native captures evidence/guidance-native2, local core evidence/core. Test with tools/review_visual_guidance.gd (rendered) or review_guidance_logic.gd (headless). GUIDANCE_OUT/MODS_OUT select evidence paths. .github/visual-guidance holds package preparation, review, workflow and acceptance scaffolding. No acceptance manifest until final frozen reports and actual images pass independent review.

An initial git push was rejected by automatic approval review claiming no destination/publication authorization. Read-only checks verified exact remote https://github.com/Corpax88/Ever-Deeper.git, public visibility, user's admin/push rights, and existing standing GitHub/DEV authorization in the project and session. Source-only task changes contain no private assets. No credentials/permissions were modified. Retry must use the same authorized branch action, not a bypass.

Retain all26 published file identities,8LIVE+9Worn protected and shared DEV engine contract. Website update is mandatory only after successful DEV publication. FPS and rotation investigations remain parked.
