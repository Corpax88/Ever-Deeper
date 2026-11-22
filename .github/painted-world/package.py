"""Rebuild the visual candidate from the verified DEV15.63 pack."""
import hashlib
import json
import os
import re
import shutil
import struct
import subprocess
import sys
from pathlib import Path
from tempfile import TemporaryDirectory

root = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(root / ".github/five-mods"))
from pack_helpers import identity, unpack

baseline_sha = "187cc463b48a93fcfe8b89595e2ca68a357d8de8134c3c2964c4d3baa5d3aa2f"
web = (
    "index.html", "index.js", "index.wasm", "index.pck", "index.png",
    "index.icon.png", "index.apple-touch-icon.png", "index.audio.worklet.js",
    "index.audio.position.worklet.js",
)


def main(engine, baseline, output):
    output.mkdir(parents=True, exist_ok=True)
    original = baseline.read_bytes()
    assert hashlib.sha256(original).hexdigest() == baseline_sha, "Requires the public DEV15.63 pack"
    base, entries = unpack(original)

    def raw(name):
        offset, size, *_ = entries[name]
        return original[base + offset:base + offset + size]

    replacements = {}
    for path in (
        "scripts/ui/premium_menu.gd",
        "scripts/ui/premium_hud.gd",
        "scripts/ui/resource_inventory.gd",
        "scripts/ui/painted_palette.gd",
        "scripts/player/native_worn/native_surface.gdshader",
    ):
        replacements[path] = (root / path).read_bytes()
        if path + ".remap" in entries:
            replacements[path + ".remap"] = f'[remap]\npath="res://{path}"\n'.encode()

    paths = (Path(__file__).parent / "textures.txt").read_text().splitlines()
    assert paths and len(paths) == len(set(paths))
    with TemporaryDirectory(prefix="ever-deeper-painted-import-") as folder:
        project = Path(folder)
        (project / "project.godot").write_text(
            'config_version=5\n\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n'
        )
        imports = {}
        for path in paths:
            import_path = path + ".import"
            assert import_path in entries or path in entries, path
            if path in entries:
                # Treasury loads its authored PNGs directly with Image.load_from_file.
                replacements[path] = (root / path).read_bytes()
            if import_path not in entries:
                continue
            local = project / path
            local.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(root / path, local)
            metadata = raw(import_path)
            (project / import_path).write_bytes(metadata)
            mapped = re.findall(r'"res://(\.godot/imported/[^"]+\.ctex)"', metadata.decode())
            assert mapped and set(mapped).issubset(entries), path
            imports[path] = set(mapped)
        process = subprocess.run(
            [engine, "--headless", "--path", str(project), "--editor", "--import"],
            capture_output=True, text=True, timeout=180,
        )
        (output / "texture-import.log").write_text(process.stdout + process.stderr)
        assert process.returncode == 0 and "ERROR:" not in process.stderr, process.stderr
        for path, mapped in imports.items():
            for target in mapped:
                assert (project / target).is_file(), (path, target)
                replacements[target] = (project / target).read_bytes()

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
        "version": "1.0.0-dev.15.64",
        "baseline_pck": identity(baseline),
        "textures": paths,
        "replaced": sorted(replacements),
        "retained_payloads_verified": True,
        "files": manifest,
    }
    (output / "qa-build-receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")
    print(len(paths), "painted textures", manifest["index.pck"])


if __name__ == "__main__":
    main(str(Path(sys.argv[1]).resolve()), Path(sys.argv[2]), Path(sys.argv[3]))
