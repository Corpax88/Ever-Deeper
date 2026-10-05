# Attention and onboarding — 5 October 2026

## Primary sources

- [Celia Hodent, Epic UX / GDC 2016, The Gamer’s Brain Part 2](https://celiahodent.com/gamers-brain-ux-onboarding/): limited selective attention; a Fortnite example shows urgent top-screen information missed during action. Teach in context, distribute learning, make goals meaningful, and support memory with visible guidance.
- [Valve, Illustrative Rendering in Team Fortress 2, 2007, §4.2–4.3](https://cdn.fastly.steamstatic.com/apps/valve/2007/NPAR07_IllustrativeRenderingInTeamFortress2.pdf): visual hierarchy through restrained detail, saturation and contrast; game-relevant forms must remain readable against their surroundings.
- [Naughty Dog, navigation assistance](https://feedback.naughtydog.com/hc/en-us/articles/22879759505940-How-do-I-use-Navigation-Assistance): optional guidance can identify progression routes and interactable destinations.

These support design principles, not a claim of measured gaze. No eye-tracking or human comprehension study was performed.

## Applied to Ever-Deeper

The baseline displayed five controls simultaneously and marked the tutorial seen after nine seconds. Actual rendered baseline also clipped the row. Replace it with one task in the existing goal panel: move → enter a mine → collect actual ore → open Bag → earn the first upgrade. Task completion observes runtime actions; idle time cannot advance. Mining a block is deliberately distinct from collecting its dropped resource.

Use the approved existing HUD/art, retain the local pickup feedback, and temporarily defer achievement/skill presentations during the first four tasks without discarding rewards. Keep the fifth task's normal live costs and route. The world cue consistently uses semantic gold with a dark outline; when the matching enabled context button becomes available, the cue moves to that button. Unrelated nearby actions do not receive the cue. Local outlines pulse twice, then remain steady. No global vignette, new art, lighting changes, camera changes or extra objective arrows.

Skip is explicit. Settings → Controls → Replay Guide is available with an expedition. Developed saves are not forced through beginner lessons; their voluntary replay finishes after Bag and does not require another upgrade. Pauses preserve progress; the persistent beginner course survives reload. Treasury HUD ownership is reconciled for voluntary teaching so it cannot hide the required panel/Bag.

## Critic rounds

1. Research/code: confirmed timer-based five-hint problem. Initial candidate's clean goal-panel capture accepted as an improvement; rejected Bag dismissal, pre-pickup completion and incorrect ENTER wording.
2. Six rendered native states: readable; no hero overlap. Corrected remaining Forge-cue suppression, replay route/state handling, non-mining instruction and Treasury HUD competition.
3. Seven rendered edge checks pass, including the real matching Forge button and Treasury route/Bag visibility. Shortened the Treasury route instruction after the critic found clipping.
4. The critic explicitly inspected all18 first Mac screenshots at667/844/932 plus the corrected Treasury capture: no further scoped blockers;8/10 for onboarding/attention. Existing target/companion text still adds scene noise and is not claimed resolved. Root inspected representative actual Mac images. Final source-bound Mac acceptance follows below in HANDOFF.md. No physical-iPhone, gaze measurement or overall UI9.5 claim.
