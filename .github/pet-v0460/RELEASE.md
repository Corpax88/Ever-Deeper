# Ever-Deeper v0.46.0-dev.1 — Little Paws

Mats requested an autonomous companion improvement pass: skills should feel useful and understandable, the pet menu should be cute and distinct from shops, and the mole should have personality. This work targets DEV for his next playtest. LIVE remains v0.45.0 production without the developer menu.

## Changes

- Dedicated CompanionJournal modal instead of the CommercePanel: an authored transparent leather-and-parchment panel, existing mole portrait, friendly controls, Together / Paw skills / How we help tabs, learned/passive/command distinctions, prerequisites and exact missing costs. Tap the mole portrait for an affectionate response. Shared pause/input lifecycle remains centralized; shop layouts are unchanged.
- Paw points retain the existing companion_xp save identity. Valid mining now earns points even when the hero collects the drops first. Pet collection still earns points. No save reset, skill repricing or purchased-skill removal.
- Fetch starts sooner and searches farther. Base movement is 280; Trailrunner is +60% (448). Big Paws changes pickup radius 32 to 100. Long Beam doubles actual reach 220 to 440. Earthshaker keeps the protected 2×2 maximum and reduces recharge to 8 seconds; its command finds a nearby ordinary wall. Teamwork acts every 2.5 seconds and credits terrain at the animation strike, with keyboard and touch mining supported.
- Ore Nose automatically marks a new exposed vein at most once every 10 seconds. Commands mark targets, display a relative direction, and explain failure. Homeward waits for the hero. Ground commands return to following after a short stop. Small breathing, curious tilts, happy bounces, and brief result bubbles use the existing authored animation frames and preserve the character.
- HUD text explains current work and dig recharge. Journal describes automatic help, commands, controls, point earning and result feedback.

## Validation and limitations

Source and exact exported DEV runtime pass 796 checks, including 20 added checks for mining point accounting, invalid inputs, save roundtrip, actual light range, actual expanded pickup, single-credit animation, visible feedback, hold recovery, recharge, separate modal, input pause, tabs, close restoration and skill access. Existing browser-touch gestures and the full overhaul suite are also run in CI. Twelve targeted mobile captures cover fresh/locked/ready/learned skills, scrolled list, how-to, commands, recharge, petting and HUD in surface/D1/D2.

Artwork, progression locks, earlier saves and the approved player/tools are preserved. Companion digs continue to call the world's existing guarded terrain APIs. Performance is checked in Chromium/SwiftShader mobile format, not on a physical iPhone. New subjective acceptance is left for Mats's playtest.

Full source archive includes the complete editable Godot project and this release's source changes, authored journal PNG, capture runner, gameplay suite and runtime hashes. Follow final publication-receipt.json for exact CI/deploy identities; this document alone does not assert publication.
