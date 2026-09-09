# Hero and audio review for 1.0

Reviewed 2026-09-09 from `3a6ddd7d8cf0678d92756cb2c3d53c14c4d1826a`, with
Godot 4.7.2. This review preserves the approved Gruvepappa v28; no character,
equipment, outfit, shader, player controller, atlas or animation timing was changed.

## Changes

`scripts/audio/audio_director.gd` now reuses completed sound voices before replacing
playing ones. When all ten are busy, it may replace the oldest voice at the lowest
eligible priority. Mining and common pickups therefore cannot cut a discovery or
upgrade cue. A newer milestone can replace an older milestone if necessary.
There are still exactly ten sound players, with no new nodes or generated samples
during gameplay. Music, mix levels, material sounds and Web Audio SAMPLE playback
remain unchanged.

Rare pickups now have their own existing 62 ms throttle. Collecting stone and a rare
resource in the same batch plays both cues; repeated rare drops are still throttled.
Public event methods and mining/progression accounting are unchanged.

## Measured sound regression

`tools/qa-hero-audio.gd` drives actual `AudioStreamPlayer` lifecycles. A discovery cue
plays while normal mining and pickup calls alternate every 60 ms for 12 events.
It also exercises same-batch pickups, full voice saturation, upgrades and muting.

| Check | Original runtime | Candidate |
|---|---|---|
| Common and rare pickup in one batch | Rare cue suppressed | Both start |
| Discovery during 734 ms of mining/pickups | Replaced; slot playing another sound at 0.104 s | Same discovery still playing at 0.702 s |
| Discovery ends naturally afterward | Replaced sound ends | Discovery ends and frees slot |
| Mining while all ten milestone voices play | Cuts a milestone | Existing milestones continue |
| New upgrade during saturation | Plays | Plays |
| Rare burst throttled, ten-voice bound, mute | Pass | Pass |

The original runtime fails the negative control and the candidate passes every check
with exit code zero and no script errors. The initial test attempt used SAMPLE with
the native Dummy driver, which does not support that backend; it was rejected as a
playback measurement. The corrected native fixture selects STREAM on its own players,
checks advancing playback time, and waits for mixer teardown. It does not change the
shipped web backend or certify audible quality on an iPhone.

## Existing hero animation audited

`tools/qa-hero-transitions.gd` loads the real player scene and all eleven production
gear sets, then runs their actual animation methods in four directions. All 44 cases
and all five outfit selections pass. The audit covers:

- Real idle/blink poses and at least 40 distinct walk frames during one stride.
- Walk settlement and mining interrupted before/after contact returning to idle.
- At least 30 distinct mining poses per tested cycle, including the drill rotor.
- Authored pickaxe contact at phase 0.55 matching each tool's gameplay strike phase.
- Eight loaded texture/mask atlases per gear, directional selection and cache release.
- All five cloth-only recolor settings, native grip error below 0.00001, 48 mining
  frames per ordinary tool and 96 for Crusher.

Player movement, world coordinate handling, grounded anchors and equipment IDs remain
untouched, so this work introduces no coordinate change during continuous-world rebases.
This fixture verifies runtime animation state and atlas selection, not damage or
rendered aesthetics. Existing real-damage motion coverage remains available via
`HERO_MOTION=1 CAPTURE_END=1 node tools/capture-web.mjs ...` and the v28 capture matrix.
The baseline rendered acceptance is documented in `.github/hero-v28/review-notes.md`.

Preserved inventory (88 atlases plus eleven manifests):
`510a1b53b54d0c28eb31e24333a760aa0800ad2c5b1652f360507fde533bf977`.
The digest hashes each sorted relative path, a zero byte and its file SHA-256 digest.
`player_visual.gd`: `59530de85ae0de6006714b2c2259c4473bf4c264aae6b6bc413c24243fd69bc0`.
`player_controller.gd`: `1833194dbf14ea4e5cc8ffcb38b3ef72b6b9e8f96b85641f2300f468cbf2b9a0`.

## Reproduce

Use a separate `XDG_DATA_HOME` and output directory so player saves are isolated:

```sh
XDG_DATA_HOME=/tmp/ever-deeper-audio-user "$GODOT_BIN" --headless --audio-driver Dummy --path . --script res://tools/qa-hero-audio.gd -- --output=/tmp/ever-deeper-audio-results
XDG_DATA_HOME=/tmp/ever-deeper-hero-user "$GODOT_BIN" --headless --audio-driver Dummy --path . --script res://tools/qa-hero-transitions.gd -- --output=/tmp/ever-deeper-hero-results
```

Each fixture writes a JSON report and exits nonzero on failures. Original and candidate
measurements in this work session are under `qa-hero-audio-before`,
`qa-hero-audio-after` and `qa-hero-transitions` in the workspace parent directory.

## Release boundary

Final rendered mobile review, real web sound playback and sustained physical iPhone
performance remain whole-build gates. This focused review does not give the game a
1.0 score, mark those gates complete or authorize publication.
