"""Headless reach/projection probe; no native mesh or images are evaluated.

The actual rig validation and native rendered comparison remain mandatory.
"""
from pathlib import Path
import argparse
import hashlib
import json
import math
import sys
import bpy
from mathutils import Vector
from bpy_extras.object_utils import world_to_camera_view

parser = argparse.ArgumentParser()
parser.add_argument("--output", type=Path, required=True)
args = parser.parse_args(sys.argv[sys.argv.index("--") + 1:])
source = Path(__file__).resolve().parents[1] / "hero_v28"
sys.path.insert(0, str(source))
import native_motion as motion
import premium_motion as pm
import locomotion

scene = bpy.context.scene
scene.render.resolution_x = scene.render.resolution_y = 200
scene.render.resolution_percentage = 100
camera_data = bpy.data.cameras.new("WorkingPlaneProbeCamera")
camera_data.type = "ORTHO"
camera_data.ortho_scale = 2.9
camera = bpy.data.objects.new("WorkingPlaneProbeCamera", camera_data)
scene.collection.objects.link(camera)
scene.camera = camera
camera.location = (6, 6, 7)
camera.rotation_euler = (Vector((0, -.10, .98)) - camera.location).to_track_quat("-Z", "Y").to_euler()
bpy.context.view_layer.update()
origin = world_to_camera_view(scene, camera, Vector())
dx = (world_to_camera_view(scene, camera, Vector((1, 0, 0))) - origin) * 160
dy = (world_to_camera_view(scene, camera, Vector((0, 1, 0))) - origin) * 160
from mathutils import Matrix
jacobian = Matrix(((dx.x, dy.x), (-dx.y, -dy.y)))
g = jacobian.inverted() @ Vector((0, -1))
ground = Vector((g.x, g.y, 0))
heading = pm.heading_matrix(ground)
phases = sorted(set([i / 128 for i in range(129)] + [.24, .40, .55, .575, .625, .68, .82]))
originals = [(q, motion.sample("worn", "mine", q, ground, 340)) for q in phases]
results = []
for lateral in [0, -.10, -.15, -.20, -.25, -.30]:
    for retreat in [0, .025, .05, .075, .10, .125]:
        if lateral == 0 and retreat != 0:
            continue
        delta = heading @ Vector((lateral, retreat, 0))
        projected = world_to_camera_view(scene, camera, delta) - origin
        result = {"lateral_native": lateral, "retreat_native": retreat,
                  "screen_offset_160px": [projected.x * 160, -projected.y * 160],
                  "passed": True, "max_shoulder_wrist_distance": 0,
                  "max_grip_spacing_error": 0, "max_foot_change": 0,
                  "max_tool_axis_change": 0, "sample_count": 0}
        for q, pose in originals:
            try:
                shifted = pm._assemble("worn", pose["torso"], pose["head"], pose["rear"] + delta,
                                       pose["axis"], pose["tool_normal"],
                                       {s: pose["legs"][s][0] for s in ("R", "L")},
                                       {s: pose["legs"][s][2] for s in ("R", "L")},
                                       pose["bit_angle"], pose["contacts"],
                                       {s: pose["legs"][s][1] for s in ("R", "L")})
                result["max_shoulder_wrist_distance"] = max(result["max_shoulder_wrist_distance"],
                                                            *[(p[2] - p[0]).length for p in shifted["arms"].values()])
                result["max_grip_spacing_error"] = max(result["max_grip_spacing_error"],
                                                       abs((shifted["grips"]["L"]-shifted["grips"]["R"]).length - .145))
                result["max_foot_change"] = max(result["max_foot_change"],
                                                *[(shifted["legs"][s][2]-pose["legs"][s][2]).length for s in ("R", "L")])
                result["max_tool_axis_change"] = max(result["max_tool_axis_change"],
                                                      (shifted["axis"]-pose["axis"]).length)
                result["sample_count"] += 1
            except ValueError as error:
                result.update(passed=False, failure_phase=q, failure=str(error))
                break
        results.append(result)
report = {"rendered": False, "native_mesh_loaded": False, "purpose": "Dense native target reach and exact camera projection only; cannot prove visual visibility or evaluated rig grip",
          "source_checkpoint": "f34bf7486f560ba104c137009a5affe50d2a642b",
          "blender": bpy.app.version_string, "camera": {"position": [6, 6, 7], "target": [0, -.10, .98], "ortho_scale": 2.9},
          "ground_per_screen_pixel": list(ground), "heading_degrees": math.degrees(math.atan2(ground.x, -ground.y)),
          "phases": phases, "unchanged": ["actual upward tool axis and normal", "torso and head", "ankle endpoints only; this probe does not compare sole orientation or complete leg chains", "constructed rigid two-hand grip spacing; evaluated attachment untested", "native contact phase .55 and mechanical .68/.42"],
          "source_hashes": {name: hashlib.sha256((source/name).read_bytes()).hexdigest() for name in ["native_motion.py", "premium_motion.py", "locomotion.py"]},
          "cases": results}
args.output.parent.mkdir(parents=True, exist_ok=True)
args.output.write_text(json.dumps(report, indent=2) + "\n")
print("WORKING_PLANE_PROBE", json.dumps({"cases": len(results), "passed": sum(r["passed"] for r in results), "output": str(args.output)}))
