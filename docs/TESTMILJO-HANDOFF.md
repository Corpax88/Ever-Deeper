# Test environment — premium-polish source recovery

Canonical source is the complete root project in `Corpax88/Ever-Deeper`.
This recovery is based on `d4619e5429326b880c4da2d466a2bf5351f0f46c`.
Read `premium-polish/HANDOFF.md`, `AGENTS.md` and `verification.md` first.

## Verified local route

- Official Godot 4.7.2 Linux binary, version `4.7.2.stable.official.ed1daf0bf`.
- Xvfb 21.1.12, libXfont2 and libxkbfile downloaded as Ubuntu packages and
  extracted without changing access controls. `/usr/bin/xkbcomp` is required.
- `tools/run_rendered_isolated.py` starts authenticated Xvfb and Godot together,
  isolates saves, supplies extracted libraries and captures complete logs.
- `tools/capture_recovery.gd` captures actual source states using the existing
  game fixtures. Example, with verified executable paths supplied locally:

```sh
python3 tools/run_rendered_isolated.py --godot /path/to/Godot \
  --xvfb /path/to/xvfb/usr/bin/Xvfb --output /absolute/review \
  --resolution 1696x780 --timeout 300 -- \
  --script tools/capture_recovery.gd -- --output=/absolute/review
python3 tools/qa.py --godot /path/to/Godot
python3 tools/check_invariants.py
```

31 source captures were inspected. Software rendering is useful visual evidence,
not Apple-device performance evidence. The source gate has 14 current cases;
do not count the lost candidate's additional premium suite as present.

## Restore rather than assume

Probe execution and actual files on each continuation. Old scratch locations
and process IDs can disappear. Verify executable versions after downloading.
Do not use the older truncated Godot ZIP as a runtime. Blender 4.5.3 LTS is the
native hero exporter; keep approved v28/v9 binary originals outside the public
source payload. Never rebuild the model from reference imagery or memory.

The established Apple route uses GitHub Actions macOS runners and the repository's
review workflows. It is not a reserved Mac mini. Read current workflow files
before use, keep source changes on the game's own work branch, and preserve
contents-read permissions and isolated saves. Mac WebKit, Safari in an iPhone
Simulator, and physical iPhone performance are different evidence categories.

The full premium-polish workflow was part of the lost source and must be restored
and reviewed before relying on it. No exported package, browser performance,
Safari Simulator or physical iPhone result is asserted by this checkpoint.
