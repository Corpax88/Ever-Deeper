# DEV15 Skills — implementation checkpoint

User approved the exact attached Skills concept on22 September and said Implementer.
Reference LibraryID libfile_5ea15d86ad708191834a0f7186567138. The user's optional answer explicitly activated stamina now, mildly limiting running/mining. Skills0–100 was already agreed; XP curves and mild stamina effects are now documented below.

Base: Corpax88/Ever-Deeper game source1632526b0cb675e5efd5709b0e55a6ab7ef970d9 (DEV14.3). Branch codex/locked-skills-ui-20260922. Main is publication/evidence, not the current game-source branch.

Implemented: live Skills screen with mine backdrop, separate transparent portrait and production nine-patch copper/iron textures, EB Garamond(OFL), four live XP rows, stamina, real resource counts and current depth. HUD crossed-tools button opens it; Inventory/Map/Settings and close route to actual game systems. Gameplay hero/native animations are unchanged. Original native prepared assets reused byte-for-byte from public DEV14.3 PCK SHA25669a3b032e324a865b4ba064756ab23e3f71beb3336df7705430436e37e74df5e.

Training: Mining4XP per recorded swing, Prospecting1XP per mined resource(count_as_mined=false grants excluded), Running1XP per64px actual physics movement, Carrying same while carrying cargo. Next level100+50*levelXP; levelcap100. Existing recorded swings and resources seed old-save Mining/Prospecting. Unknown historical travel stays0. Additional optional schema3 save section includes XP and stamina; existing saves stay valid.

Stamina100. Running2/s, loaded running adds0.75/s, mining4/s; first three skill levels gradually reduce matching drain (30%,50%,30% at100). Restore14/s after0.8s rest. Only active gameplay advances; menus/orientation/background catch-up freeze it. Below15 stamina, movement and effective tool power taper to75%; no animation/cooldown changes and no hard mining/movement lock. Prospecting currently measures ore knowledge, without a passive yield bonus. HUD stamina strip appears below full.

Initial native graphical fixture passed30 checks, including schema compatibility, XP sources, fatigue/recovery, menu pause/resume, Map/Inventory/Settings. Images runtime/skills-native-v2. Critic first review found XP/border overlap (fixed), missing icon frames(fixed), embedded-map resize callback(fixed), render-vs-physics sampling(fixed), close touch size(fixed). Independent narrow UI score8.0/10; code pending those verified corrections. Final exact web package/mobile touch/build/independent review are still required. Nothing new published yet.

Tools: current intact146414384-byte Godot4.7.2 at /tmp/ever-deeper-skills-tools/Godot_v4.7.2-stable_linux.x86_64; workspace extracted executable was truncated by synchronization, so recover from valid runtime/godot.zip into /tmp. Xvfb extracted to runtime/xvfb with libXfont/libxkbfile/xkbcomp; tools/run_rendered_isolated.py works. Physical iPhone FPS/crash unverified as before.

Artwork archive: libfile_06d3ff7b27ac81918aedb9576867c224, Ever-Deeper-Skills-DEV15-art.zip, five exact production binary files + manifest. Direct local git push has no shell credential, but existing GitHub connector is authenticated. One-time branch-scoped CI stores only these authorized-public artwork files, with an allowlist/hash-checked transfer; renderer workflow stays contents:read and checkout credentials are not persisted. No new user login required. Do not route binary/base64 through conversation tools.

Next: finish exact-package core/native+Mac browser checks, independent final capture review, then update ordinary /dev/ preserving all LIVE and historical Worn bytes. Update this handoff and Library entry with final immutable identities. No final release claim until gates pass.
