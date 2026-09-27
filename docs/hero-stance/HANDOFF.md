# DEV15.14 native mining stance

User reports skewed feet and sideways lean while mining; always plays DEV. Authorized correcting existing hero, without another broad performance round. LIVE must retain published 1.0.1.

The task bank's mining poses carry a rotated planted stance (feet approximately `(±.146, ∓.144, .14)` versus idle `(±.205, 0, .14)`) while the ready torso is rotated approximately -109.245 degrees from idle. Feet and torso therefore use different stance frames (about 65 degrees apart). The lean was also authored on a fixed axis instead of the torso stance axis. This is animation data, not DPR or the mole AI.

The bounded correction lives in `.github/hero-stance/runtime_motion.gd`, applied once after the original reference guard validates the unchanged native asset bank. It derives the mining stance frame from the ready torso relative to idle, rotates the idle foot/leg references into that frame, removes only lateral body tilt/translation in that frame, and preserves forward pitch and vertical compression. Head and shoulder pivots follow the torso, and existing rigid leg solving retains segment lengths. Existing tool and hand transforms remain unchanged in each authored key; arms use the existing rigid solver. No new per-frame solver or asset redesign.

The original immutable native assets remain byte-identical. The original/corrected bank copies support the opt-in QA fixture; normal gameplay uses corrected poses. Existing contact retargeting and transition safety still run. Do not use world X/Y to classify the authored torso sway, or assume local -Y is the pick contact bearing.

Build recipe: `.github/hero-stance/build.py`, based on the exact published graphics candidate from run 36352372852, source d7aeb10b087bca58a240ee7c78da38304fabe9f3. Preserves accepted music buffering and graphics preference bridge. Version becomes 1.0.0-dev.15.14. Runtime dependency raw remaps are carried explicitly. Do not build historical main as a game release.

Targeted verification: actual held-key mining in four cardinal directions on Mac WebKit; native rig remains active, impacts advance, no motion/parse errors, rigid lengths and contact error checked. Frozen original/corrected comparisons at phases .20, .42 and .70 use the actual game rig. QA hides HUD layers for unobscured comparisons. These are not physical iPhone verification or FPS evidence.

First visual run 36354700399 / 3070b0dbc221b2e493341237471b3ad78dc9bb30 passed, but HUD obscured the down view. Candidate review run 36354890594 / 34a8e0733206aa6f70ad878b5e2fccca0e2ee084 completed the browser check, but GitHub artifact creation timed out repeatedly; no candidate was accepted from it. Run 36355243162 / 32318b464a8ece242a466161e174bd1e332f3cd8 repeats the same focused review with bounded runner/browser shutdown and progress diagnostics. API polling needs unique query parameters to avoid stale cached run status. Publication details are recorded below after acceptance.

Visual rejection: run 36355243162 passed its runtime checks, but the unobscured down view revealed that simply using unrotated idle feet was wrong. That intermediate candidate was NOT published. The accepted approach must use the ready torso frame. Follow-up source 4811f56ca5b524980cebe4ded68f3bcfe2389488 corrects that frame; tool and authored hand transforms remain unchanged.

Accepted source 4811f56ca5b524980cebe4ded68f3bcfe2389488, validation run 36355460990, candidate artifact 10944315256. Final visual review confirms aligned stance, including unobscured down view; runtime impacts advance in all directions (7/7/6/7), reach error zero and max contact error <.000008 pixels. No runtime error. Publication pins artifact digest and every file, preserves LIVE1.0.1 and Worn, and verifies all 27 public file hashes.

Published: commit 45fa1f1fab49a8efd40900c8ec55ac68a9288794, run 36355716317. Package, deploy and public hash verification passed. Receipt confirms all 27 files, including unchanged LIVE1.0.1 and retained Worn trial. Rollback artifact 10944340849 preserves previous DEV15.13. DEV15.14 is available at https://corpax88.github.io/Ever-Deeper/dev/. Task complete; do not repeat these checks.
