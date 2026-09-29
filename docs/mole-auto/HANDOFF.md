# DEV15.24 automatic mole, earthworm power and renewable rush shrines
Requested 29 September 2026: automatic mining by default; optional target steering. Common random crawling earthworms give hero-speed mining for20seconds. Existing mining-rush shrines return after120seconds.

Base: exact DEV15.23 source1171d1e90a507e987d9f51dfb346c5a5d547c459, immutable candidate11041095866/run36582708554. Never rebuild historical main. New source branch codex/mole-auto-20260929. LIVE1.0.2 loading-rotation-1 and Worn must remain unchanged.

Implementation:
- Bounded automatic target search once/sec; same world eligibility and rewards as commanded work. No skill or held mining needed. Tap rock overrides automatic selection; open-ground command briefly holds before automatic work resumes. Work stays within600logicalpixels of hero, then regroups. Optional following exposes more ground.
- Worms: generated one transparent PNG assets/companion/earthworm-v1.png; in-game28logicalpixels wide, body compresses and turns while moving3–5px/sec on reachable floor. Initial4–8sec, subsequent random18–32sec, max3,90sec lifetime.2.5sec visible crawl before collection eligibility. Mole approaches/eats; manual job resumes. Power refreshes to20sec, never stacks; same active hero tool/rush/heat cycle. Timer follows active companion across worlds and pauses in menus. No hero mining XP/stamina spending.
- Native resource rewards, saves, controls, hero, lights and engine unchanged. New shrine timestamps stored/sanitized in existing overhaul progress dictionary. Old permanently claimed shrines revive. Depth2 legacy local runtime cooldown still supported; new claims use persistent real-time120sec deadline.
- User requested imagegen asset, not a mockup or sprite sheet. Built-in imagegen original is one complete isolated warm terracotta segmented earthworm, soft painted volume, no text/background/props; unchanged source PNG copied into project, animated in code. SHA and test captures to be bound at acceptance.
- Keep FPS investigation PARKED. Existing historical invariant QA-registration/documentation failure is not claimed green. No physical-iPhone claim.
Validation/publication: in progress, no accepted release yet.
