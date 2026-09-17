#!/usr/bin/env python3
"""Archive captured RGB frames losslessly, then verify every decoded frame.

Source PNG or explicitly described raw RGBA8 frames are read only. The archive
is storage; visual acceptance still requires the pixels and their sample timeline.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import threading
import time

from PIL import Image


def digest(path: Path) -> str:
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def write_receipt(folder: Path, receipt: dict) -> None:
    (folder / "archive.json").write_text(json.dumps(receipt, indent=2) + "\n")


def read_pixels(path: Path, capture: dict, capture_format: str, width: int, height: int) -> tuple[bytes, dict]:
    """Return exact RGB pixels only after checking dimensions, bytes and opacity."""
    if capture_format == "rgba8":
        expected = {"format": "rgba8", "width": width, "height": height,
                    "byte_count": width * height * 4, "row_stride_bytes": width * 4,
                    "row_order": "top_to_bottom", "channel_order": "RGBA"}
        if any(capture.get(key) != value for key, value in expected.items()):
            raise RuntimeError("Raw frame description differs from tight RGBA8: " + path.name)
        data = path.read_bytes()
        if len(data) != width * height * 4:
            raise RuntimeError("Raw RGBA8 byte count differs from declared dimensions: " + path.name)
        image = Image.frombytes("RGBA", (width, height), data)
        capture_hash = hashlib.sha256(data).hexdigest()
    else:
        with Image.open(path) as source:
            if source.format != "PNG" or source.size != (width, height):
                raise RuntimeError("Native PNG frame format or size changed: " + path.name)
            image = source.convert("RGBA")
        capture_hash = digest(path)
    alpha = image.getchannel("A").getextrema()
    if alpha != (255, 255):
        raise RuntimeError("RGB archive requires opaque capture pixels: " + path.name)
    rgb = image.convert("RGB").tobytes()
    if len(rgb) != width * height * 3:
        raise RuntimeError("RGB conversion did not retain the complete frame")
    identity = {"capture_format": capture_format, "capture_sha256": capture_hash,
                "capture_bytes": path.stat().st_size, "width": width, "height": height,
                "alpha_minmax": list(alpha), "rgb_bytes": len(rgb),
                "rgb_sha256": hashlib.sha256(rgb).hexdigest()}
    identity["raw_sha256" if capture_format == "rgba8" else "png_sha256"] = capture_hash
    if capture_format == "rgba8":
        identity.update(row_stride_bytes=width * 4, row_order="top_to_bottom", channel_order="RGBA")
    return rgb, identity


def critical_sample_indices(report: dict, indices: list[int]) -> set[int]:
    critical = set()
    required_events = {"release_before_contact", "move_away_during_anticipation", "first_real_impact", "release_after_delivered_contact"}
    for event in report.get("events", []):
        if event["name"] in required_events:
            before = [index for index in indices if index <= event["after_sample"]]
            after = [index for index in indices if index > event["after_sample"]]
            if before: critical.add(max(before))
            if after: critical.add(min(after))
    for stage in ("cancel_release", "walk_stop", "post_hit_release"):
        selected = [capture["sample"] for capture in report["captures"] if capture["stage"] == stage]
        if selected: critical.add(max(selected))
    return critical


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", type=Path, required=True, help="Case containing hero-motion-coverage.json and PNG or raw RGBA8 captures")
    parser.add_argument("--output", type=Path, required=True, help="Fresh archive folder; original images are never removed")
    parser.add_argument("--ffmpeg", default="ffmpeg")
    parser.add_argument("--ffprobe", default="ffprobe")
    parser.add_argument("--codec", choices=["auto", "libx264rgb", "ffv1"], default="auto")
    parser.add_argument("--fps", type=int, default=60)
    parser.add_argument("--threads", type=int, choices=[1, 2], default=2)
    parser.add_argument("--timeout", type=int, default=300, help="Bound for each encoder/decoder process, including pipe writes")
    parser.add_argument("--require-complete", action="store_true", help="Require a captured frame for every sample and a matching fixed-step timeline")
    args = parser.parse_args()
    folder = args.input.resolve()
    output = args.output.resolve()
    if output.exists() and any(output.iterdir()):
        parser.error("Archive output must be fresh; previous evidence is retained")
    if args.fps <= 0 or args.timeout <= 0:
        parser.error("FPS and timeout must be positive")
    report_path = folder / "hero-motion-coverage.json"
    report = json.loads(report_path.read_text())
    captures = report["captures"]
    samples = report["samples"]
    capture_format = report.get("capture_format", "png")
    if capture_format not in ("png", "rgba8"):
        parser.error("Unsupported capture format: " + str(capture_format))
    indices = [capture["sample"] for capture in captures]
    if not indices or indices != sorted(set(indices)):
        parser.error("Captured sample order must be nonempty, unique and increasing")
    if any(type(index) is not int or index < 0 or index >= len(samples) for index in indices):
        parser.error("Every capture must identify an existing sample")
    paths = []
    for capture in captures:
        name = capture["file"]
        suffix = ".rgba" if capture_format == "rgba8" else ".png"
        if Path(name).name != name or not name.endswith(suffix) or not (folder / name).is_file():
            parser.error("Capture must name an existing local " + capture_format + " frame: " + name)
        paths.append(folder / name)
    complete = indices == list(range(len(samples)))
    fixed_timeline = all(abs((after["simulated_seconds"] - before["simulated_seconds"]) - 1 / args.fps) < 1e-6
                         for before, after in zip(samples, samples[1:]))
    if args.require_complete and (not complete or not fixed_timeline):
        parser.error("Continuous archive requires every captured sample and matching fixed-step FPS; use capture --all-frames")
    output.mkdir(parents=True, exist_ok=True)
    receipt = {
        "schema": 2, "status": "pending", "verified_rgb": False,
        "capture_format": capture_format, "capture_origin": report.get("capture_origin", "godot_frame_post_draw"),
        "archiver_sha256": digest(Path(__file__)),
        "source_report_sha256": digest(report_path), "source_sha": report.get("source_sha"),
        "pack_sha256": report.get("pack_sha256"), "gear": report.get("gear"), "direction": report.get("direction"),
        "source_case_passed": report.get("passed"), "source_framing_passed": report.get("framing", {}).get("passed"),
        "actual_viewport": report.get("actual_viewport"), "captured_frames": len(paths), "observed_samples": len(samples),
        "all_observed_frames_present": complete, "fixed_step_timeline_matches_fps": fixed_timeline,
        "archive_fps": args.fps,
        "timing": "Complete fixed-step capture" if complete and fixed_timeline else "Ordered captured-frame archive only; source sequence gaps are not filled. Use the sample/event JSON for timing.",
        "source_capture_bytes": sum(path.stat().st_size for path in paths),
        "original_png_bytes": sum(path.stat().st_size for path in paths) if capture_format == "png" else 0,
        "raw_capture_bytes": sum(path.stat().st_size for path in paths) if capture_format == "rgba8" else 0,
        "source_captures_retained": False, "original_pngs_retained": False if capture_format == "png" else None,
        "raw_captures_retained": False if capture_format == "rgba8" else None,
        "opaque_alpha_verified": False, "critical_source_pngs_retained": False,
        "regenerated_image_policy": "Decoded RGB pixels must match every recorded RGB hash. Newly encoded PNG file bytes are not claimed to match source PNGs or raw capture files. Critical supplied PNG copies retain their original PNG byte hashes.",
        "frames": [], "critical_pngs": [],
        "visual_acceptance": False, "physical_iphone": False, "fps_claim": False,
    }
    write_receipt(output, receipt)
    started = time.monotonic()
    try:
        version = subprocess.check_output([args.ffmpeg, "-version"], text=True, timeout=10).splitlines()[0]
        encoders = subprocess.check_output([args.ffmpeg, "-hide_banner", "-encoders"], text=True, stderr=subprocess.DEVNULL, timeout=10)
        codec = args.codec
        if codec == "auto":
            codec = "libx264rgb" if "libx264rgb" in encoders else "ffv1"
        if codec not in encoders:
            raise RuntimeError(f"Installed ffmpeg does not expose {codec}")
        width, height = report["actual_viewport"]
        if [width, height] != [1696, 780]:
            raise RuntimeError("Expected the actual 1696x780 native capture")
        temporary_video = output / "motion-unverified.mkv"
        command = [args.ffmpeg, "-hide_banner", "-loglevel", "warning", "-nostdin", "-n",
                   "-f", "rawvideo", "-pixel_format", "rgb24", "-video_size", f"{width}x{height}",
                   "-framerate", str(args.fps), "-i", "pipe:0", "-an", "-c:v", codec, "-threads", str(args.threads)]
        if codec == "libx264rgb":
            command += ["-crf", "0", "-preset", "veryslow", "-pix_fmt", "rgb24"]
        else:
            command += ["-level", "3", "-coder", "1", "-context", "1", "-slicecrc", "1", "-pix_fmt", "bgr0"]
        command += [str(temporary_video)]
        receipt.update(ffmpeg_version=version, codec=codec, encode_command=command)
        with (output / "encode.log").open("wb") as log:
            process = subprocess.Popen(command, stdin=subprocess.PIPE, stdout=subprocess.DEVNULL, stderr=log)
            watchdog = threading.Timer(args.timeout, process.kill)
            watchdog.start()
            try:
                for index, (path, capture) in enumerate(zip(paths, captures)):
                    rgb, identity = read_pixels(path, capture, capture_format, width, height)
                    sample = samples[capture["sample"]]
                    receipt["frames"].append({"archive_frame": index, "file": path.name, "sample": capture["sample"],
                                               "drawn_frame": sample["drawn_frame"], "simulated_seconds": sample["simulated_seconds"],
                                               "stage": sample["stage"], **identity})
                    process.stdin.write(rgb)
                process.stdin.close()
                code = process.wait(timeout=args.timeout)
                if code:
                    raise RuntimeError(f"Lossless encoder exited {code}; see encode.log")
            finally:
                watchdog.cancel()
                if process.poll() is None:
                    process.kill()
                    process.wait(timeout=10)
        receipt["opaque_alpha_verified"] = True
        write_receipt(output, receipt)
        probe = json.loads(subprocess.check_output([
            args.ffprobe, "-v", "error", "-select_streams", "v:0", "-show_entries",
            "stream=codec_name,pix_fmt,width,height,r_frame_rate", "-of", "json", str(temporary_video),
        ], text=True, timeout=30))
        receipt["video_stream"] = probe["streams"][0]
        decode_command = [args.ffmpeg, "-hide_banner", "-loglevel", "error", "-nostdin",
                          "-threads", str(args.threads), "-i", str(temporary_video), "-map", "0:v:0",
                          "-pix_fmt", "rgb24", "-fps_mode", "passthrough", "-f", "framehash", "-hash", "sha256", "pipe:1"]
        decoded = subprocess.run(decode_command, capture_output=True, text=True, timeout=args.timeout)
        (output / "decode.log").write_text(decoded.stderr)
        (output / "decoded-rgb.framehash").write_text(decoded.stdout)
        if decoded.returncode:
            raise RuntimeError(f"Lossless decoder exited {decoded.returncode}; see decode.log")
        actual_hashes = []
        for line in decoded.stdout.splitlines():
            if not line or line.startswith("#"):
                continue
            columns = [column.strip() for column in line.split(",")]
            if len(columns) != 6 or int(columns[4]) != width * height * 3:
                raise RuntimeError("Decoded frame is not complete RGB24")
            actual_hashes.append(columns[5])
        expected_hashes = [frame["rgb_sha256"] for frame in receipt["frames"]]
        receipt["decoded_frames"] = len(actual_hashes)
        receipt["mismatched_frames"] = [index for index, (actual, expected) in enumerate(zip(actual_hashes, expected_hashes)) if actual != expected]
        if len(actual_hashes) != len(expected_hashes) or receipt["mismatched_frames"]:
            raise RuntimeError("Decoded RGB count or per-frame SHA-256 differs from original pixels")
        critical_indices = critical_sample_indices(report, indices)
        supplied = report.get("critical_pngs", [])
        raw_critical = {entry["sample"]: entry for entry in supplied}
        if capture_format == "rgba8" and (len(raw_critical) != len(supplied) or set(raw_critical) != critical_indices):
            raise RuntimeError("Raw capture must supply exactly the selected critical native PNGs")
        critical = output / "critical-pngs"
        critical.mkdir()
        for frame in receipt["frames"]:
            if frame["sample"] in critical_indices:
                if capture_format == "rgba8":
                    entry = raw_critical[frame["sample"]]
                    name = entry["file"]
                    if Path(name).name != name or not name.endswith(".png"):
                        raise RuntimeError("Critical PNG must be a local PNG filename")
                    if (entry.get("source_raw_file") != frame["file"] or entry.get("source_raw_sha256") != frame["raw_sha256"]
                            or entry.get("generated_from_raw") is not True):
                        raise RuntimeError("Critical PNG does not identify its exact raw source frame")
                    if report.get("rendered") and entry.get("origin") != "godot_png_from_stored_rgba8":
                        raise RuntimeError("Rendered raw evidence requires Godot-encoded critical PNGs")
                    _, png_identity = read_pixels(folder / name, {}, "png", width, height)
                    png_hash = entry["png_sha256"]
                    if png_identity["png_sha256"] != png_hash or png_identity["rgb_sha256"] != frame["rgb_sha256"]:
                        raise RuntimeError("Critical native PNG pixels differ from the stored raw frame")
                    critical_identity = {**entry, "rgb_sha256": frame["rgb_sha256"]}
                else:
                    name, png_hash = frame["file"], frame["png_sha256"]
                    critical_identity = {"sample": frame["sample"], "png_sha256": png_hash,
                                         "rgb_sha256": frame["rgb_sha256"], "origin": receipt["capture_origin"],
                                         "generated_from_raw": False}
                destination = critical / name
                shutil.copyfile(folder / name, destination)
                if digest(destination) != png_hash:
                    raise RuntimeError("Critical PNG copy failed its source hash")
                receipt["critical_pngs"].append({**critical_identity, "file": "critical-pngs/" + name})
        receipt["critical_source_pngs_retained"] = all(
            digest(folder / Path(entry["file"]).name) == entry["png_sha256"] for entry in receipt["critical_pngs"])
        shutil.copyfile(report_path, output / report_path.name)
        # The matrix's aggregate results are still in progress here. Preserve
        # the immutable plan and complete case report, not a partial global pass.
        for name in ("coverage-plan.json",):
            if (folder.parent / name).is_file():
                shutil.copyfile(folder.parent / name, output / name)
        receipt["source_captures_retained"] = all(digest(folder / frame["file"]) == frame["capture_sha256"] for frame in receipt["frames"])
        receipt["original_pngs_retained" if capture_format == "png" else "raw_captures_retained"] = receipt["source_captures_retained"]
        if not receipt["source_captures_retained"] or not receipt["critical_source_pngs_retained"]:
            raise RuntimeError("Source capture or critical PNG changed during archiving")
        video = output / "motion-lossless.mkv"
        temporary_video.rename(video)
        # Some synchronized workspaces retain the staging name after rename.
        # Remove only an identical encoder-owned duplicate, never source PNGs.
        if temporary_video.exists():
            if digest(temporary_video) != digest(video):
                raise RuntimeError("Staging and verified video differ after rename")
            temporary_video.unlink()
        receipt.update(status="verified", verified_rgb=True, video=video.name, video_sha256=digest(video),
                       video_bytes=video.stat().st_size, critical_png_bytes=sum(path.stat().st_size for path in critical.iterdir()),
                       elapsed_seconds=round(time.monotonic() - started, 3), decode_command=decode_command)
        receipt["video_to_source_capture_ratio"] = receipt["video_bytes"] / receipt["source_capture_bytes"]
        receipt["video_to_original_png_ratio"] = receipt["video_bytes"] / receipt["original_png_bytes"] if capture_format == "png" else None
        write_receipt(output, receipt)
        print(f"VERIFIED {len(paths)} decoded RGB hashes; video {receipt['video_bytes']} bytes, {capture_format} sources {receipt['source_capture_bytes']} bytes", flush=True)
        print(f"Retained {len(receipt['critical_pngs'])} critical PNGs and all sample/event JSON; originals unchanged.", flush=True)
        return 0
    except (OSError, ValueError, KeyError, TypeError, subprocess.SubprocessError, RuntimeError) as error:
        receipt.update(status="failed", error=str(error), elapsed_seconds=round(time.monotonic() - started, 3))
        write_receipt(output, receipt)
        print("ARCHIVE_FAILED " + str(error), flush=True)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
