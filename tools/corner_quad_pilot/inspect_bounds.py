#!/usr/bin/env python3
"""Read exact native corner alpha bounds once; never rewrite production images."""
import argparse
import hashlib
import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
ASSETS = {
    "caves/ancient-bedrock-corner-v1.png": ["Depth 2 bedrock", "Deep bedrock"],
    "rootwound/cave-corner-v1.png": ["Depth 2 Moss", "Deep Rootwound"],
    "prismatic/cave-corner-v1.png": ["Depth 2 Moon"],
    "molten/cave-corner-v1.png": ["Depth 2 Ember"],
    "voidstar/cave-corner-v1.png": ["Depth 2 Star", "Deep Voidstar"],
    "mossvein/cave-corner-v2.png": ["Depth 1 Moss compact joins", "Deep Moss"],
    "moonglass/cave-corner-v1.png": ["Depth 1 Moon compact joins", "Deep Moonglass"],
    "emberdeep/cave-corner-v1.png": ["Depth 1 Ember compact joins", "Deep Ember"],
    "starfall/cave-corner-v1.png": ["Depth 1 Star compact joins"],
}
PADDING = 3  # Two source pixels plus one conservative bilinear-filter pixel.
IMPORT_REQUIREMENTS = [
    "compress/mode=0", "mipmaps/generate=false", "process/fix_alpha_border=false",
    "process/premult_alpha=false", "process/size_limit=0", "process/channel_remap/alpha=3",
]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    result = {
        "base": "ec8976622231bc70c5413775291e841d0e543353",
        "scope": "Offline exact-alpha inspection only; no render or performance result",
        "padding_source_pixels": PADDING,
        "padding_policy": "2 pixel conservative margin plus 1 pixel for bilinear filtering; verified no mipmaps",
        "assets": [],
    }
    for relative, owners in ASSETS.items():
        path = ROOT / "assets" / relative
        imported = path.with_suffix(path.suffix + ".import")
        image = Image.open(path).convert("RGBA")
        alpha = image.getchannel("A")
        bounds = alpha.getbbox()
        if bounds is None:
            raise ValueError(f"Unexpected empty asset: {relative}")
        w, h = image.size
        x0, y0, x1, y1 = bounds
        crop = (max(0, x0 - PADDING), max(0, y0 - PADDING), min(w, x1 + PADDING), min(h, y1 + PADDING))
        text = imported.read_text()
        parameters = set(text.splitlines())
        bad = [line for line in IMPORT_REQUIREMENTS if line not in parameters]
        if bad:
            raise ValueError(f"Unsupported import settings for {relative}: {bad}")
        # This is a metadata proof; no raster image is created or altered.
        outside = [alpha.crop((0, 0, crop[0], h)), alpha.crop((crop[2], 0, w, h)), alpha.crop((crop[0], 0, crop[2], crop[1])), alpha.crop((crop[0], crop[3], crop[2], h))]
        if any(piece.getbbox() is not None for piece in outside):
            raise ValueError(f"Nonzero alpha outside candidate source rectangle: {relative}")
        row = {
            "path": "res://assets/" + relative, "owners": owners,
            "size": [w, h], "nonzero_alpha_bounds_xyxy": list(bounds),
            "padded_source_rect_xywh": [crop[0], crop[1], crop[2] - crop[0], crop[3] - crop[1]],
            "full_quad_area_retained": (crop[2] - crop[0]) * (crop[3] - crop[1]) / (w * h),
            "discarded_alpha_max": 0, "alpha_threshold": 0,
            "png_sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
            "import_sha256": hashlib.sha256(imported.read_bytes()).hexdigest(),
            "verified_import_settings": IMPORT_REQUIREMENTS,
        }
        result["assets"].append(row)
        print(f"{relative}: alpha={bounds}, source={row['padded_source_rect_xywh']}, full-quad retained={row['full_quad_area_retained']:.4%}")
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2) + "\n")


if __name__ == "__main__":
    main()
