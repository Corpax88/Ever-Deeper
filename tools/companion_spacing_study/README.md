# Companion spacing study capture

This is an opt-in tools-only comparison against published DEV12 source
`580a2e02eca1e000f5d5f58bb61ac09fd4b2a194`, PCK SHA-256
`9dfcf913c867e36e6a16f4f5123fd5cce7654cfb435a753f9eb7bca12f574bd9`.
It does not change the shipped main, companion, hero art, camera or input code.
Candidate approval requires the root-owned autonomy/lifecycle gates and an
independent review of actual images after the source checkpoint is saved.

## Bounded A/B capture

`run_companion.py` runs one Worn/right or Worn/up case. Baseline uses the actual
shipped main. Candidate mounts only the existing study overlay and installs
`pilot_main.gd` on the actual main scene before `add_child`, just as the isolated
integration gate does. It never positions or manually steps the companion.

Supply the original hero-motion fixture folder at exact commit
`72f11bcd33ff129f8f0f694106bef509b68fd0f3`. The runner rejects any change to its
capture, runner or archiver hashes. It stages the original source plus a derived
base containing exactly two added calls: the before-add-child installation hook
and an extra report field. The full diff and both hashes are recorded. All route,
ordinary startup settling, real held-input choreography, cancellation, contact,
follow-through, 8px full-reserve framing, 195-frame and raw/critical-PNG checks
remain active. Up uses the already validated natural wall `(13,15)`.
The 113 original runtime/hero preservation hashes are recorded, plus the companion
owners, original companion atlases and project settings. If this study checkout
has clean tracked assets sparsely omitted, their exact DEV12 Git blobs supply
the hashes; those paths are listed explicitly. The running PCK is still checked
byte-for-byte and no omitted asset is rematerialized just for this study.
The executed `run_rendered_isolated.py` is copied into the staged fixture, bound
to its exact DEV12 Git bytes, included in A/B identity and checked after capture.

The actual normally earned achievement profile retains its DEV11 source/package
origin. Before reuse on DEV12, the runner requires identical achievement service,
RunState, save epoch, GameData, toast owner and game-data bytes. Each case loads an
isolated copy normally, verifies its loaded identity and naturally settles any
new ordinary feedback. No awards, timestamps or queues are fabricated or cleared.

Example preparation only (no Godot, Xvfb or encoder starts):

```sh
python3 tools/companion_spacing_study/run_companion.py \
  --hero-fixture /absolute/72f11bc/tools/hero_motion_coverage \
  --pack /absolute/dev12/index.pck --godot /absolute/Godot \
  --achievement-profile /absolute/earned-profile/profile-provenance.json \
  --variant baseline --direction right --output /tmp/companion-right-A-prep \
  --prepare-only
```

After root has verified the remote checkpoint and granted the renderer, use a
fresh output path, omit `--prepare-only`, add `--xvfb /absolute/Xvfb` and
`--study-source-sha FULL_CHECKPOINT_SHA`. Run baseline first. Candidate additionally
requires `--baseline-case /tmp/companion-right-A/worn-right-baseline`.
Repeat this pair for `--direction up`. Keep only one unsaved case at a time;
the start guard requires 3,424,134,400 bytes free and the live disk guard preserves
the 1.5GB reserve plus encoding forecast. Stop on any failed capture or comparison.

Every post-draw sample records actual companion mode/action, position, facing,
sprite/frame, terrain query, foot depth, route/task counters and candidate steering
diagnostics. Hero input, position, health properties and whole-world damage/floor
identity are recorded beside the original mining observations. The shipped player
has no numeric HP property; its observed absence is explicit, never encoded as
zero HP. Candidate must match the baseline's actual inputs, resolved movement,
health-property state, target and whole-world damage, native non-idle phase,
cancellation and contact events for all 195 samples. Floats allow only 1e-5 absolute
serialization tolerance. Companion state, absolute clocks and ordinary startup
idle-frame phase are recorded but are not claimed identical.
The unchanged logical-to-native transform is scale `(1.1,1.1)`, offset `(0,0)`;
companion rectangles are recorded in logical viewport coordinates.

## Evidence closure

The runner prints `COMPANION_RENDERER_RELEASED` immediately after capture exit;
encoding is a separate CPU step using `archive_command` from
`companion-plan.json`. That unchanged 72f11bc archiver preserves all ordered RGB
frames losslessly, proves alpha opacity, records every original raw/RGB hash and
retains the eleven original Godot critical PNGs. Raw RGBA files are not original
PNGs. Keep original critical PNGs, reports, exact derived sources/diff, overlay,
profile provenance and the actual mechanics comparison in each closed bundle.

Do not remove raw caches until a fully checked bundle is durably saved and every
movie frame has decoded back to its original RGBA hash. Native review crops are
derived artifacts and must preserve the full-frame RGB hash and logical-to-native
transform. Full sprite-cell rectangles do not establish opaque-pixel visibility;
inspect the reversal, return, contact and follow-through originals independently.
Passing mechanics never approves spacing, gait, tool visibility, FPS or final art.
