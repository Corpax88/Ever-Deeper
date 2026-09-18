# Original-hero stock-animation study

Isolated offline Blender tools, not a runtime feature or accepted animation bank.
Read `docs/premium-polish/hero-retarget-20260918/ATTEMPTS.md` before another attempt.
The selected UAL2 TreeChopping clip was rejected as a shortcut for two-handed
native mining. No full movie or sprite bank was produced.

## Inputs and licensing

Blender 4.5.3 LTS. Original private v28 hero and Worn v9 tool remain outside Git.
`--native-tools DIR` expects the existing native structure: `DIR/worn/hero.blend`.
The v28 file SHA is checked by the runner; see the saved donor manifest for the
verified CC0 Standard asset hash. No Pro/Source edition or purchase is needed.
Official author page: https://quaternius.itch.io/universal-animation-library-2
License: `docs/premium-polish/hero-retarget-20260918/UAL2-LICENSE.txt`.

The free downloader only selects the exact Standard archive from the author's
public form. It stores the actual license, README, GLB, archive and hash inventory.
Do not re-download verified local assets just to repeat checks.

```sh
python tools/hero_retarget_probe/fetch_standard.py --library 2 --output /tmp/stock2
blender --background --factory-startup --threads 2 \
  --python tools/hero_retarget_probe/inspect_stock.py -- \
  --glb /tmp/stock2/UAL2_Standard.glb --output /tmp/source-poses.json \
  --sample-actions TreeChopping_Loop Walk_Carry_Loop
blender --background /path/to/hero-v28.blend --threads 2 \
  --python tools/hero_retarget_probe/probe.py -- \
  --glb /tmp/stock2/UAL2_Standard.glb --native-tools /path/to/native-tools \
  --output /tmp/new-attempt --fit-grips --chop-driver right-hand --render keys
```

Use a fresh output directory. The runner samples 66 poses before rendering and
now refuses image output if tool correction exceeds 0.10 native model units.
The failed right-hand trial will therefore be stopped before rendering by default.
Use `--max-tool-correction .80` only to reproduce that rejected historical trial;
this does not accept its geometry or visuals. `--chop-driver wrist-pair` reproduces
the earlier mapping; it is invalid for the source's one-handed chop.

The applier retains original materials, geometry and native closed hand grips.
The donor has 65 bones and the hero 17; arm/leg scale ratios differ substantially.
Ankle-height floor approximation is not a sole-contact solver. Native source
clip durations are 2.0s carry and approximately 0.966667s chop at imported 24fps.
They have not been mapped to gameplay's 0.68s cycle or .42 impact phase.
Do not claim smoothness or clean stops from the eight keyframes.

No `.blend` or third-party model is committed. The saved evidence archive keeps
actual renders, reports, licenses and donor GLB, separate from repo source.
