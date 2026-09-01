# Ever Deeper

## v0.43 assembled build workspace

Current release: **Ever Deeper v0.43.1** / **DEV v0.43.1-dev.2**.

This is the buildable Godot 4.7 workspace assembled from the deployed
v0.42.0-dev.7 package, then updated through the v0.43.1 edge-contour hotfix
and the DEV-only premium Mossvein Forge pass.
It is not the original pre-export source snapshot. See
`EVER_DEEPER_HANDOFF.md` for provenance, exact release inputs, verification,
and continuation notes.

The historical v0.38.1 development notes below are retained for context; their
HTML/JavaScript run instructions do not describe the current Godot workspace.

## Historical v0.38.1 notes

Build: **Ever Deeper v0.38.1 - Crownseeker Reforged**

Completing Starfall and extracting the first Singularity Core now unlocks a persistent Underground Hub beneath the final world. The Hub is a safe, non-mineable building scene with touch-first wall painting, removable lamps that shape the room lighting, real storage chests, a lift back to Starfall, and an offline elevator reserved for The Deep. Hub construction uses existing Stone and Gold, survives reloads, and never resets expedition progress.

Routine mining, discoveries, upgrades, gates, pickups, and chest openings no longer add generic canvas rings or procedural debris over the production art. Pickaxe and drill impacts now rely on the biome-specific premium response sheets, while sold materials travel to the exchange as their real drop assets. Gameplay-critical targeting, health bars, timed-vein indicators, lighting, and readable text remain intact.

The world now breathes around the player through eight biome-specific premium animation sheets: slow Mossvein spores, Moonglass wisps, Emberdeep ash, and Starfall void motes, plus matching reactions for footsteps, pickaxe hits, drill impacts, and breaks. The layer stays world-anchored beneath mine lighting, clears cleanly between scenes, freezes under Reduced Motion, and is capped for mobile rendering and decoded memory.

Each biome now has its own hand-painted ambient creature: Mossvein glowmoths, Moonglass prism moths, Emberdeep cinder skinks, and Starfall astral rays. They inhabit both the surface and safe open cave cells, occasionally cross the landscape in small groups, freeze under Reduced Motion, and remain strictly visual with tight mobile draw and memory budgets.

Every surface biome now ends at a dedicated transparent production-PNG ridge with its world gate as the only passage. The complete boundary art provides each natural opening, while the enlarged premium gate sits directly inside the painted rock instead of a rectangular code-cut gap. Inside all four mines, every permanent collision wall uses a dedicated biome-specific unbreakable-bedrock PNG, visibly distinct from chipped mineable terrain.

Static game data lives in its own ordered module, protected by parity checks that catch accidental balance or progression changes.

Fifty persistent achievements now cover mining, precision, resources, exploration, treasure, veins, equipment, Depth 2, and the final victory. Every unlock has its own transparent reliquary sprite, an earned-at record with a clear reason, and a hero-following five-turn reveal that settles before it can be claimed.

Starfall is now a complete production-art world: its own seamless surface, an untouched biome road with a naturally joined cave branch, a correctly oriented Starfall Hollow entrance, sinking Master Seal and permanent astral ground mark, celestial chests, Starforge station, lattice sockets, and distinct background formations. Starfall Hollow and Voidstar Depths have dedicated floors, walls, barriers, chambers, stations, portals, buried wall hints, mineable nodes, and rewards.

The final expedition now has a real ending. After mastering the Deepcore Drill, the text-free guide returns the player to Starfall Hollow; the discovered Voidstar shaft remains locked to lower drills, and mining the first Singularity Core in Voidstar permanently records the Ever Deeper victory.

Emberdeep now has a complete production-art pass across the blended surface biome, sinking seal, permanent gate mark, mine approach, portal, chests and bonus fault. Emberdeep Works and Molten Depths have their own floors, walls, barriers, hidden chambers, stations, readable ore hints, mineable nodes, drops, natural lighting and Infernium drill gate.

Every cave now uses a low-resolution raycast lightmap: the miner's helmet projects a warm, directional beam that stops against solid terrain, nearby darkness remains readable, and exposed ores emit restrained light in their own material colors. The light buffer is capped at 34% resolution and 16 visible ore lights to keep the effect mobile-safe.

Mossvein Depth 2 now uses its complete Rootwound production set: seamless deep-earth floor, root-bound terrain walls, Rootiron/Deepstone/Ambercore/Burrowsteel nodes, a buried Rootiron wall vein, the amber-lit shaft, ore exchange, and drill forge. Their former canvas-drawn Depth 2 counterparts no longer render in Rootwound.

Ever Deeper Drift now plays as a low background soundtrack after the player's first interaction. Its intro and ending are rebuilt into an 82.38-second crossfade loop, and playback pauses while the game is hidden. The audio master is attenuated by 15 dB to keep iPhone Safari from overriding the intended background level.

Burrower, Pulse, and Deepcore now use complete production character assets with both hands permanently drawn around the correct grips. Drill rendering swaps the entire character as one clean unit, so facing changes and recoil can never separate hands, body, and tool.

The failed drill limb-crop renderer has been removed completely. Pickaxes retain the proven Character B layered swing, while drills use a subtle whole-character recoil with no independent limb or tool transforms.

Character B is the production player character. Five pickaxes and three Starforge forms remain mutually exclusive equipment layers on the proven hand anchor; the three drills are complete mutually exclusive character composites. The former canvas-drawn player and tools remain fully removed.

Mossvein's entire surface now uses one opaque production PNG with a continuous dirt path from the mine entrance to the Moonglass gate. The former canvas grid, path, and ground decorations are no longer rendered in Mossvein.

The Mossvein mine entrance now uses one dedicated transparent production PNG. The former canvas portal is no longer drawn for Mossvein.

Ordinary surface stone now uses a dedicated transparent PNG node instead of the former canvas polygon.

Copper and Gold now use dedicated transparent PNGs for both buried wall seams and revealed nodes. Their former canvas-drawn mineral bodies and seams are no longer rendered.

Wall-seam PNGs are clipped into the final terrain face as narrow, shallow previews; full node PNGs remain unchanged.

The Mossvein wall asset is now neutral charcoal stone without baked amber patches, so colored seams always indicate a real buried mineral.

Buried ore now bleeds through the final terrain block as irregular colored veins and embedded mineral pockets on the open tunnel face. The full resource remains hidden until that last block is mined.

A standalone, framework-free HTML5 prototype for the mining loop:

`dig terrain -> open a tunnel -> reveal hidden ore -> collect it -> sell -> upgrade -> dig deeper`

## Controls

- Desktop: `WASD` / arrow keys to move, hold `Space` to mine, `E` to interact.
- Mobile: press anywhere in the playfield to place the floating joystick, drag to move, and hold the `MINE` button to swing.
- Your latest movement direction aims the pickaxe, so push toward a mine wall while holding mine to carve a tunnel.
- Walk near the Sell Chest, Forge, storage chests, or a sealed gate to reveal their action.

## Run locally

From this directory:

```powershell
python -m http.server 4180 --bind 0.0.0.0
```

Open `http://127.0.0.1:4180` on the same computer.

## Codebase layout

- `game-data.js` owns the static world definitions, balance values, equipment catalogs, discoveries, recipes, and achievement definitions.
- `script.js` owns runtime state, persistence, input, UI, audio, rendering, and the browser bootstrap.
- `index.html` loads both as ordered classic scripts: `game-data.js` must always run before `script.js`.
- Exported game data is shared read-only. Clone nested objects before changing them at runtime.

## Refactor guardrails

- `npm run test:smoke` loads every external runtime script in HTML order and exercises saves, progression, achievements, controls, lighting, and the complete expedition.
- The smoke suite pins a canonical SHA-256 digest of the static game data so accidental balance, requirement, layout, or catalog changes fail immediately.
- The Playwright suite checks desktop and iPhone behavior. Keep gameplay changes separate from structural refactors so failures remain attributable.

## Mossvein wall optimization

- Production PNGs are pre-cleaned, resized, and compressed from roughly 4.3 MB to under 300 KB total.
- The floor now uses one cached repeating pattern instead of many large rotated image draws per frame.
- Rocky wall art is clipped into a continuous terrain mass with deterministic overlapping placements; the old bright pipe-like bevel is removed.
- Mining, collision, loot, progression, saves, and mobile controls remain unchanged.

## Mossvein production art

- Mossvein Mine and Rootwound Depths now use production PNG artwork for the cave floor and rocky tunnel walls, with a safe procedural fallback while images load.
- Dug tunnels combine the existing terrain mask with irregular high-detail rock clusters, quieter fracture shadows, and a textured lamp-lit floor.
- The renderer caches concealed discovery cells and culls detail to the viewport for mobile performance.
- Terrain data, mining HP, collision, loot, progression, base placement, and save compatibility remain unchanged.
- Other biomes keep their existing rendering until their own approved visual pass.

## Visual foundation

- Premium mobile HUD with an Ever Deeper logo header, clearer resource counters, a stronger goal card, tactile mining controls, directional joystick cues, and a unified tool console.
- Existing gameplay, world rendering, progression, saves, interaction IDs, and mining logic remain unchanged.

## Prototype scope

- One continuous world with four visually distinct areas.
- Every mine is now four to five times deeper: aim with movement, hold mine to carve persistent tunnels, and let the camera follow the descent.
- Each mine hides exactly one persistent, randomly placed descent. Break into it to unlock a separate Depth 2 with harder dirt, denser veins and its own tunnels.
- Every Depth 2 now has a permanent Exchange and Drill Forge beside its return shaft.
- Depth 2 uses entirely new local resources: Rootiron and Ambercore, Prismite and Lunacore, Magmaite and Furnace Hearts, or Voidglass and Singularity Cores. Mineable dirt yields Deepstone instead of surface Stone.
- A forged Starforge pickaxe can bootstrap Depth 2, then three permanent drill tiers replace it with much faster mining: Burrower Drill, Pulse Drill, and Deepcore Drill.
- The top objective stays locked to the next permanent progression goal, including exact missing drill materials and gold.
- One soft, text-free guidance light points toward the next useful rock, route, entrance or station, then fades as the player gets close.
- Off-screen objectives use a single pulsing chevron, including the route back out of the wrong mine and onward to the correct Depth 2.
- Persistent circular area markers were removed from bonus veins; their subtle connecting trace and status remain.
- Sell All automatically protects the materials reserved for the active drill upgrade.
- Drills use their own braced, spinning bore animation and matching HUD controls instead of a pickaxe swing.
- Drill progression now routes back through earlier Depth 2 mines: Burrowsteel in Mossvein requires the Burrower Drill, while Phase Crystal in Moonglass and Infernium in Emberdeep require the Pulse Drill for the final Deepcore upgrade.
- Dirt now uses a stronger contrasting color in every mine so open cave floor and mineable terrain are easy to read on mobile.
- Terrain is generated lazily in compact 16 x 16-cell typed-array chunks and only visible cells are drawn, avoiding one heavy object per rock tile on mobile.
- Deterministic connected ore veins run through the deep terrain in clusters of 4-10 nodes instead of isolated random rocks.
- Buried chambers remain visually concealed until the player breaks through their perimeter, then permanently reveal their name and rare find.
- Every buried chamber now contains a persistent reward: a buried cache, crystal cluster, motherlode, or Mining Rush shrine that grants 55% faster mining for 30 seconds.
- The Wayfarer Shop turns spare gold into permanent movement speed with rising prices and no upgrade cap.
- A clean resource-only inventory shows every collected material without equipment or character preview.
- The Forge, Sell Chest and storage chests form a movable base that can be packed without loss and placed in any mine or depth.
- The first 20-type storage chest is free, more chests cost progressively more gold, and one button auto-sorts nearby storage while protecting active drill materials.
- Drill terrain hits use indexed reveal lookups instead of scanning every hidden deposit, reducing frame spikes while digging quickly.
- Stone, copper, Moonglass, armored Emberstone, Astralite, and four valuable rare veins.
- Five pickaxe tiers with stronger damage and faster swings.
- Emberstone shells that can be ground down normally or cracked quickly with precision strikes.
- Four timed bonus veins that reward clearing a full connected cluster quickly.
- Broken ore now bursts onto the ground and must be collected by walking over it. One global five-minute cleanup clears loose items from every map, with warnings before the sweep.
- Ember Pickaxe requires 12 lifetime Emberstone mined plus 650 gold.
- Five Ember Mastery ranks extend progression after the final pickaxe. Each rank needs gold plus a lifetime Sunslag milestone, then grants higher power, swing speed, shell penetration, precision frequency, and bonus yield.
- Damage left over after breaking an armored shell now carries into the ore core, so stronger pickaxes never waste their extra power at the shell boundary.
- Ember Mastery 5 opens the Starfall Master Seal and reveals Starfall Depths, armored Astralite, rare Crownstone, and the Starfall Lattice.
- The Starforge consumes Astralite and Crownstone to unlock three swappable endgame styles: the heavy Astral Crusher, rapid Comet Edge, and high-yield Crownseeker. Crownseeker's three-point Crownstone crest and single mining beak give it a distinct silhouette from the Ember Pickaxe.
- Three visible rock-damage stages and optional timing-based precision strikes.
- Stronger mining feedback with staged terrain cracks, brief impact weight, material-tuned audio, optional haptics, escalating vein feedback, and discovery/jackpot bursts, without full-screen shake or flashes.
- A five-step Mining Focus streak for accurate active play.
- Animated resource selling with a smooth gold count-up.
- Local browser save.
- No framework or external runtime dependency.
