# Ever Deeper v0.43.1 / DEV v0.43.1-dev.2 handoff

## Status

Ever Deeper LIVE remains **v0.43.1**. DEV **v0.43.1-dev.2** adds the approved
premium Mossvein Forge treatment while preserving LIVE byte-for-byte. This
remains the assembled Godot workspace reconstructed for v0.43, not the lost
original pre-export source tree.

## DEV v0.43.1-dev.2 premium Forge addendum

- `scripts/ui/commerce_panel.gd` applies four text-free production PNG assets
  to Mossvein Forge only: frame, plate, action button, and item medallion.
- Live item art, costs, labels, values, interaction logic, and scroll behaviour
  remain authoritative. Ready, missing-material, locked, mastery, completed,
  and missing-icon states retain distinct functional presentation.
- `scripts/main.gd` closes and hides the DEV drawer toggle while commerce is
  open, then restores it after the panel closes.
- `scripts/dev/visual_capture_driver.gd` expands the deterministic suite from
  121 to 133 states with ten Forge fixtures plus Wayfarer and Tool Forge
  regression baselines.
- `.github/workflows/deploy-v0431-dev2-only.yml` reconstructs DEV from the
  exact public dev.1 PCK, verifies the target package, preserves all nine LIVE
  files byte-for-byte, and deploys through GitHub Pages only.
- Final local DEV HTML: 13,410 bytes,
  SHA-256 `53ec054c0e45617dced265af58c07d3c6ba81904fe80aaaf07450a81ed49fb0f`.
- Final local DEV PCK: 109,519,212 bytes,
  SHA-256 `854243e06a5557ef2a33157f4fb30a62073fd0945a77be096c7f656a3f522de1`.
- The dev.1-to-dev.2 xdelta is 1,916,554 bytes,
  SHA-256 `e50e73169da49608f69b5294662a3e9a59391d17889ea78d7375488e21061f34`;
  decode and byte comparison pass.

## Approved mineable-edge rule

- A mineable cave rim may face only a missing cell proven to be permanently
  player-dug.
- Authored entrances, chambers, barrier clearances, and temporarily depleted
  resource cells do not manufacture a mineable rim.
- Every adjacent 90-degree turn uses a compact local corner join. Opposite open
  faces are not a corner.
- The rim terminates flush at bedrock and never continues down either side.
  Bedrock emits no mineable edge or corner.
- The shared rule applies to Mossvein, Moonglass, Emberdeep, and Starfall while
  preserving each biome's distinct bedrock surface.

## Implementation

- `scripts/world/mossvein_mine.gd`
  - adds `mineable_edge_void_cells` as explicit player-dug provenance;
  - restores it from `RunState.dug_cells` when a mine is rebuilt;
  - records ordinary terrain, barrier, and crusher excavation immediately and
    persists it, preventing non-resource stones from growing back;
  - explicitly excludes temporarily depleted resource cells;
  - derives mineable faces from provenance instead of every physically empty
    neighbour;
  - emits corners only for adjacent open-face pairs and crops every mineable
    turn to its compact local join.
- `scripts/main.gd` asserts provenance, immediate and restored excavation,
  resource respawn, every 90-degree rotation, and opposite-face non-corners.
- The v0.43.1 baseline `scripts/dev/visual_capture_driver.gd` added a deterministic four-biome
  fixture for an authored clearance with no U-rim, a compact player-dug turn,
  and a rim terminating at bedrock. DEV v0.43.1-dev.2 retains those fixtures
  and expands the suite to 133 states as described above.
- Collision, targeting, resource respawn, and the four biome bedrock textures
  are unchanged.

## Source provenance

The hotfix input was the project-report archive
`Ever-Deeper-v0.43.0-source.zip`, SHA-256
`09f742d690f3330a6e871a3094154fb1e5eb48f8bd57487e76997399edb49dd4`.
It was imported as local root commit `13f8313`; the verified implementation and
release inputs were committed as
`0e4863b74ac5c88208812890c6d84e0acda7afb3`.

The v0.43 workspace itself was reconstructed from deployed v0.42.0-dev.7 with
GDRE Tools 2.6.4 after the original workspace became unavailable. Recovery
verified/extracted 950 of 950 files, decompiled 45 of 45 scripts, and converted
468 of 468 resources with zero failures and one lossy conversion.

The unchanged production bedrock assets are:

| Biome | Asset | SHA-256 |
|---|---|---|
| Mossvein | `assets/mossvein/bedrock-surface-v1.png` | `ad1339cd2605c43e84327f4d708385b987bad59befe8e406946a05f3a7085109` |
| Moonglass | `assets/moonglass/bedrock-surface-v1.png` | `a2108f91d88fdb7ee30622d1756bb740e44da3ad12db963ec10ecc54a156056d` |
| Emberdeep | `assets/emberdeep/bedrock-surface-v1.png` | `021d8408cfd90683245b701a0e6ee79931282eee26bfe76c7c9692a643672d73` |
| Starfall | `assets/starfall/bedrock-surface-v1.png` | `5229bb17cd72c275aa62f22749da6ab308c060044f3552bcc5bf0fdec847e3ee` |

## Release identities

| Artifact | Bytes | SHA-256 |
|---|---:|---|
| Production PCK, v0.43.1 | 107,885,104 | `cea26af47f58045e220fb5c2f96aefa4224dfe8573eb13340a997c114b07a4ac` |
| DEV PCK, v0.43.1-dev.1 | 107,900,100 | `d40678f149e6840e7e007c512b08a88f02d2273b9e30ae0e456581887ff20cb6` |
| Production HTML | 13,446 | `27c14d7c3f0917cbdb43b4509e40ef9a61928dc2c03052f13fb4d01731158b6a` |
| DEV HTML | 13,459 | `0795b19ce53bc06f403a37101e8b99bc32b1db41eb66e000ee52eef36bda5883` |
| v0.43.0 to v0.43.1 xdelta | 341,185 | `aba767c32106538854b4c3bb1b449ca04005e8c218b2d04c275d67c1948ec285` |
| v0.43.1 production to DEV xdelta | 15,886 | `6d8f13ae0320854d66b3b2912b3c89459cffc5ac0ab03007f332745be4258d78` |

The production delta has ordered parts of 250,000 and 91,185 bytes. The DEV
delta is one 15,886-byte part. Both were decoded with xdelta3 3.2.0 and compared
byte-for-byte with the PCKs above.

The exact v0.43.0 rollback baseline, freshly re-fetched before release, is:

| Baseline | Bytes | SHA-256 |
|---|---:|---|
| Production HTML | 13,446 | `f1a8f9750cd6020f1e2a799a17eb8dd7002b78ced807565e9e9e32c1b073629b` |
| Production PCK | 107,879,936 | `97554f389ea297b8a6cb58345403234e3e044839ebb2b487843583976b028156` |
| DEV HTML | 13,459 | `e111689c1eb72c1ffc47577d69ed9b54b2a19746dc12bfbcc49661f57282e1f6` |
| DEV PCK | 107,894,932 | `50b64de316676fd83daeabe1fb9f36976cc6fdbe39a077cbc9a1ae3a6032fec5` |

The seven shared runtime files remain byte-identical:

| Runtime file | SHA-256 |
|---|---|
| `index.apple-touch-icon.png` | `27408d8b450ea9b0664fa639129e01dd79bdee7dfb494319cd06106d64e647d5` |
| `index.audio.position.worklet.js` | `be33985bc7160d6bf9646f259cd86b259cd67b02ccb297ee5c44f8ac84327bc8` |
| `index.audio.worklet.js` | `5b476a9c9ce642c0ee4256436d1bc31d9c38f868aca0f9a8e2a57c18d2dec2a3` |
| `index.icon.png` | `290a6f61f9e48f2e30becbf93da69a002e839742cbeb556d36bd409b8fbf3bec` |
| `index.js` | `33c94cb3175f3333b82e2a3be5e8e86f77986f0aa2042b1631f6367a4e5bb6ba` |
| `index.png` | `c0167be478bcbc291bb752bb503d9f0ba527b64d93a62523ad915c9ad96b8d3f` |
| `index.wasm` | `fc74679e3b97f76878947fcd4fbe1268cbfa6188182a2e33bbc3f5dc9bfa57d0` |

## Verification completed

- Godot 4.7.2 import/parser: PASS.
- Production and DEV exported twice; each pair is byte-identical: PASS.
- Commerce component QA: 68 checks, PASS.
- Production PCK flavour, smoke, landscape, iPhone layout, commerce, and
  13-stage journey performance: PASS.
- DEV PCK version/flavour, DEV menu/save isolation, and smoke: PASS.
- Journey performance: worst p95 17.32 ms, max 44.28 ms, seven slow frames,
  peak static memory 244.1 MiB, mature save 60.8 KiB in 2.71 ms.
- Production visual capture: 121/121 at 932x430, manually inspected; manifest
  SHA-256 `612657db79b72961c6ffc930a1c75a9bef880e6cc3628457f4c8975469d01ccd`.
- DEV v0.43.1-dev.2 packaged-web visual capture: 133/133 at 932x430 in
  Chrome 152 / SwiftShader, manually inspected; manifest SHA-256
  `b71896eb7ccd58b3d12d30511d9e9d949c4459b8695dd1603a320c3726bafc9f`.
- DEV v0.43.1-dev.1 baseline visual capture: 121/121 at 932x430, manually inspected; manifest SHA-256
  `948bc5bb0838250d8dc8fdc99b3d80c1b77ce031d8f1b7c410dfbe5a72f2de13`.
- Review covered both reported D1 regressions in all four biomes, every D1
  barrier state, bedrock joins, transitions, all D2 states, and Endless.
- Release-input audit, YAML parse, exact nine-file packages, runtime hashes,
  patch counts, and local two-stage reconstruction: PASS.

## Release and publication evidence

`.github/workflows/deploy-dev-preview.yml` verifies and stages the public
v0.43.0 LIVE/DEV packages as a 30-day rollback, reconstructs exact v0.43.1
packages, requires production itch publication, deploys root and `/dev` in one
Pages artifact, and re-fetches all 18 public files. DEV itch remains optional
because that project is not provisioned.

- GitHub release-input commit:
  `8af582b7dc96a2930e073df15cbd7682179defcf`.
- Successful Actions run 17, attempt 1: `33486993557`:
  <https://github.com/Corpax88/Ever-Deeper/actions/runs/33486993557>.
- Jobs: `package` 99789288482, `deploy-itch` 99789480609,
  `deploy-pages` 99789554346, `verify-deployment` 99789648068; all succeeded.
- LIVE: <https://corpax88.github.io/Ever-Deeper/>; exact production hashes
  above, exactly nine files.
- DEV: <https://corpax88.github.io/Ever-Deeper/dev/>; exact DEV hashes above,
  exactly nine files.
- A separate post-workflow download compared every public byte against the
  locally verified packages: PASS.
- Production itch: upload 18954222, new build 1935579, user version 0.43.1.
  Optional DEV itch returned expected `invalid game`.
- Pages artifact/deployment: 9792170807 / release commit
  `8af582b7dc96a2930e073df15cbd7682179defcf`; SUCCESS.
- Rollback: `ever-deeper-v0430-rollback`, ID 9792165948, 300,451,027 bytes,
  digest `sha256:1329693f0c21176fbf605b7332cc1b87d63d383b18cde5731606ac0753b320e9`,
  expires 2026-10-01T08:26:22Z.
- Production artifact: `ever-deeper-v0431-production-web`, ID 9792171903,
  150,223,053 bytes, digest
  `sha256:a995ee3054165b1165404eb55a30b2fa051f574f65f75c3f8660d532bfa0936d`.
- DEV artifact: `ever-deeper-v0431-dev1-web`, ID 9792172978, 150,238,062
  bytes, digest
  `sha256:628438a7800bf6d6b892c285d70cf986c6fa09bbff875b990ffe19063947986d`.
- No tag was created; commit, run, artifact, and public-file hashes are the
  immutable release identity.

The final source commit and ZIP SHA-256 are recorded in the detached handoff
saved beside the ZIP, avoiding a self-referential archive checksum.

Project-report destinations:

- `/Ever-Deeper/Ever-Deeper-v0.43.1-source.zip`
- `/Ever-Deeper/Ever-Deeper-v0.43.1-HANDOFF.md`

## Continuation notes

Use Godot 4.7.2 and `export_presets.cfg`. `Web Production` excludes
`scripts/dev/developer_menu.*`; `Web DEV` enables `ever_deeper_dev` and isolated
DEV saves. Run PCK QA from an empty directory so loose source cannot overlay the
pack. The source ZIP excludes `.git`, `.godot`, `node_modules`, generated
builds/captures/logs/reports, but retains `tools/visual-qa` and
`.github/visual-qa`.
