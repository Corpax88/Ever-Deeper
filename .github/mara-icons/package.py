"""Rebuild the visual candidate from the verified DEV15.66 pack."""
import hashlib
import json
import os
import re
import shutil
import struct
import sys
import subprocess
from tempfile import TemporaryDirectory
from pathlib import Path

root = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(root / ".github/five-mods"))
from pack_helpers import identity, unpack

baseline_sha = "aa67b874c55d3710bfcf815f7711c227634c06b4605165ca169ddaf8ce3e7ec6"
web = (
    "index.html", "index.js", "index.wasm", "index.pck", "index.png",
    "index.icon.png", "index.apple-touch-icon.png", "index.audio.worklet.js",
    "index.audio.position.worklet.js",
)


def main(engine, baseline, output):
    output.mkdir(parents=True, exist_ok=True)
    original = baseline.read_bytes()
    assert hashlib.sha256(original).hexdigest() == baseline_sha, "Requires the public DEV15.66 pack"
    base, entries = unpack(original)

    def raw(name):
        offset, size, *_ = entries[name]
        return original[base + offset:base + offset + size]

    replacements = {}
    for path in (
        "scripts/main.gd",
        "scripts/ui/premium_hud.gd",
        "scripts/ui/premium_menu.gd",
        "scripts/ui/action_icons.gd",
        "scripts/progression/mara_quests.gd",
        "shaders/mara_idle.gdshader",
    ):
        replacements[path] = (root / path).read_bytes()
        if path + ".remap" in entries:
            replacements[path + ".remap"] = f'[remap]\npath="res://{path}"\n'.encode()

    textures = sorted((root / "assets/ui/actions").glob("*.png"))
    assert textures, "Action PNGs missing"
    with TemporaryDirectory(prefix="ever-deeper-action-import-") as directory:
        project = Path(directory)
        (project / "project.godot").write_text(
            'config_version=5\n\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n'
        )
        for texture in textures:
            local = project / texture.relative_to(root)
            local.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(texture, local)
        process = subprocess.run(
            [engine, "--headless", "--path", str(project), "--editor", "--import"],
            capture_output=True, text=True, timeout=120,
        )
        (output / "texture-import.log").write_text(process.stdout + process.stderr)
        assert process.returncode == 0 and "ERROR:" not in process.stderr, process.stderr
        for texture in textures:
            path = texture.relative_to(root).as_posix() + ".import"
            metadata = (project / path).read_bytes()
            remap = re.search(r'^path="res://([^"]+)"', metadata.decode(), re.M)
            assert remap, path
            # The scripts refer to these icons by path. Exclude generated editor UIDs.
            replacements[path] = re.sub(rb'^uid=.*\n', b'', metadata, flags=re.M)
            replacements[remap[1]] = (project / remap[1]).read_bytes()

    data = bytearray(original[:base])
    directory = {}
    for name in sorted(set(entries) | set(replacements)):
        payload = replacements[name] if name in replacements else raw(name)
        data += b"\0" * (-len(data) % 32)
        directory[name] = (len(data) - base, len(payload), hashlib.md5(payload).digest(), 0)
        data += payload
    struct.pack_into("<Q", data, 32, len(data))
    data += struct.pack("<I", len(directory))
    for name, entry in directory.items():
        key = name.encode()
        key += b"\0" * (-len(key) % 4)
        data += struct.pack("<I", len(key)) + key + struct.pack("<QQ16sI", *entry)
    out_base, out_entries = unpack(data)
    assert set(out_entries) == set(directory)
    for name, (offset, size, *_rest) in out_entries.items():
        expected = replacements[name] if name in replacements else raw(name)
        assert data[out_base + offset:out_base + offset + size] == expected, name
    (output / "index.pck").write_bytes(data)
    for name in web:
        if name != "index.pck":
            shutil.copyfile(baseline.parent / name, output / name)
    html_path = output / "index.html"
    html = html_path.read_text()
    config = re.search(r"const GODOT_CONFIG = (\{[^\r\n]+\});", html)
    assert config
    values = json.loads(config[1])
    assert not values["args"]
    values["fileSizes"]["index.pck"] = len(data)
    html_path.write_text(html[:config.start(1)] + json.dumps(values, separators=(",", ":")) + html[config.end(1):])
    manifest = {name: identity(output / name) for name in web}
    (output / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    receipt = {
        "source": os.environ.get("GITHUB_SHA"),
        "version": "1.0.0-dev.15.67",
        "baseline_pck": identity(baseline),
        "replaced": sorted(replacements),
        "retained_payloads_verified": True,
        "files": manifest,
    }
    (output / "qa-build-receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")
    print(manifest["index.pck"])


if __name__ == "__main__":
    main(str(Path(sys.argv[1]).resolve()), Path(sys.argv[2]), Path(sys.argv[3]))
