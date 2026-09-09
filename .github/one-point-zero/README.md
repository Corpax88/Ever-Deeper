# Ever-Deeper 1.0 DEV release preparation

Prepared 2026-09-09. Nothing in this preparation has been pushed, published or marked
reviewed. The existing LIVE release remains 0.46.9. Its nine files, and the current
DEV9 rollback files, are pinned from wardrobe publication run **34325408480** in
`baseline.json`. The pinned LIVE PCK SHA-256 is
`3bb815dabf51f5146517d7ecb0ebbf7dfc7504d5d7030306f0daf46d6eac511b`.

## Validation workflow

`.github/workflows/one-point-zero.yml` runs only on pushes to
`codex-ever-deeper-1-0`. It has read-only repository permission and no deploy step.
`prepare.py build` requires a clean committed checkout, records its commit/tree/run,
checks the committed version labels, and uses Godot 4.7.2 with matching templates.

It imports and checks invariants, runs thirteen source cases, exports
**1.0.0-dev.2** and **1.0.0-rc.1**, repeats all thirteen cases against the exact DEV PCK,
and verifies both exported flavor/save/resource contracts and displayed versions.
The production candidate is discarded after its flavor checks; only its hashes are
retained as evidence. No production candidate goes into the publishable artifact.

The thirteen required cases are `input`, `overhaul`, `touch`, `endgame`, `onboarding`,
`layout`, `portrait`, `dev-tools`, `crusher`, `one-point-zero-state`,
`one-point-zero-world`, `one-point-zero-migration` and `one-point-zero-ui`.
The old `endless` case describes the removed room/lift design and is explicitly
replaced by the continuous-world journey checks. The retained `endgame` case checks
the campaign using mineable routes rather than requiring pre-cleared corridors.

The exact DEV PCK also runs the real audio playback overlap regression and all
44 hero tool/direction state cases plus five outfits, using external native harnesses.
The workflow preserves logs and JSON, then mobile WebKit checks rendered gameplay
and small-iPhone touch. Chromium records hero movement and twelve real-damage mining
combinations. A matching native Godot renderer captures the full new progression
from the immutable PCK at 2532×1170, with four software-rendering threads and retained
raw PNGs/JSON. It requires `ONE_POINT_ZERO_RENDER_COMPLETE`, passing assertions,
no failures, successful exit and the exact candidate PCK hash.
These jobs use the same candidate artifact and verify its hashes
before and after their checks. They do not automatically approve visual quality,
audible quality or sustained physical iPhone performance.

Separate `web-audio (webkit)` and `web-audio (chromium)` jobs exercise the actual
SAMPLE backend. `tools/qa-web-audio.mjs` uses a trusted touch to unlock the real
AudioContext, instruments actual BufferSource lifecycles, and measures nonzero
time-domain output through a transparent analyser before the destination. It checks
common/rare collection, discovery surviving twelve real mining/pickup requests,
natural completion, upgrade output, mute silence and unmute restoration. Unsupported
AudioContext, no sources, a silent destination or a failed lifecycle check fails the
job. Output records browser/driver versions, exact PCK/HTML hashes, raw RMS/peak data,
source durations and limitations; it never claims subjective listening or a physical
iPhone measurement. The opt-in bridge lives in `scripts/qa/web_audio_qa.gd` and does
not replace the game's playback backend or alter ordinary capture modes.

The DEV candidate contains only `dev/` with the nine final web files,
`manifest.json` and `validation.json`. The manifest binds every DEV file, source
identity, engine, versions, gate list, production flavor hashes and validation report.
The existing DEV diagnostic shell is installed before QA and hashing.

## Reviewed DEV publication

The separate `publish-one-point-zero-dev.yml` follows the repository's established
publication pattern: only a push to `main` changing this review file or the publisher
workflow can trigger it. Branch validation cannot deploy. All review flags are false,
artifact/run identifiers are unset, and no source or artifact has been approved here.

After inspection of the actual candidate, populate `review.json` with its successful
validation run, exact source commit, artifact ID, downloaded ZIP SHA-256, manifest
SHA-256 and complete DEV-file manifest. Mark the relevant gameplay, visual, touch,
sound and critic reviews honestly, record the provisional critic score and zero
critical bugs, and set `dev_test_ready` only when the reviewed candidate is ready.

DEV readiness is distinct from final 1.0 acceptance. The physical iPhone status may
remain false while DEV supports device testing. Final 1.0 acceptance still requires
at least 9/10, no critical bugs and measured smooth iPhone performance. This publisher
requires `final_one_point_zero_approved: false` and cannot publish a new LIVE build.

`publish.py` requires the successful exact validation workflow/run and its `build`,
`mobile`, `hero-motion`, `native-visual`, `web-audio (webkit)` and
`web-audio (chromium)` jobs. It downloads the reviewed artifact by immutable ID,
checks the reviewed ZIP hash, validates its members, source/run, manifest and all
file hashes, then downloads the eighteen currently published DEV/LIVE files.
Any baseline mismatch aborts before the site directory exists. The staged root
contains the unchanged LIVE files; only `dev/` receives the candidate. Both previous
builds become a rollback artifact. The publisher never invokes Godot or rebuilds.
After Pages deployment, every one of the eighteen public files is verified again.

## Local verification of this preparation

Eight offline release-contract checks pass: incomplete review stops before network
or staging; pinned receipt identity matches; valid DEV staging preserves LIVE bytes;
changed candidate or current LIVE bytes are rejected; workflow/run/artifact/job
identity is required; unsafe/extra ZIP members or symlinks are rejected; and DEV
test readiness cannot be marked as final 1.0 acceptance by this publisher.
Python compilation and YAML parsing also pass. No GitHub validation run or release
artifact exists yet, and the new workflow itself has not been executed remotely.

```sh
python3 .github/one-point-zero/check_release.py
python3 .github/one-point-zero/prepare.py verify-candidate /absolute/candidate
python3 .github/one-point-zero/publish.py check-review
```

The last command intentionally fails until the exact candidate review is complete.
For a clean committed build, provide a Godot executable and new output directories
outside the checkout to `prepare.py build --godot ... --candidate ... --review-output ...`.
