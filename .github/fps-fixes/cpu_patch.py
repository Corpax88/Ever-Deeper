"""Two production CPU changes; no QA flags, profiling, or alternate paths.

transform(text, 'contact'|'pet') accepts only the recorded DEV15.16 ancestors.
The caller must also verify ACTIVE/REMAP SHA256 against the immutable PCK.
The native rig, animation stance, mesh, lighting and gameplay remain untouched.
"""
import hashlib

EXPECTED = {
    "contact": {
        "source": "scripts/player/native_worn/task_motion.gd",
        "source_sha256": "4946e722a77231c5a47f34bf4af85536ccabbb2e3c0e4f3283b54db154e25f9a",
        "original_file": "../fps-round2/contact-original.gd",
        "remap": "scripts/player/native_worn/task_motion.gd.remap",
        "remap_sha256": "b768c773900a6cda757c71b6634ff230b3a2b091615373b3eaf359e1ad210b32",
        "active": "scripts/player/native_worn/task_motion.gdc",
        "active_sha256": "ec2341e53515837a62197ba6a6754ffdb719bf1ba1cffc9cdc952b33c57027e6",
    },
    "pet": {
        "source": "scripts/companion/mole_companion.gd",
        "source_sha256": "5c485b1e41ad40fe6c71368c7824b92932bc9a1f0114e732ed1300b9e6d7be73",
        "original_file": "../fps-round2/world-original.gd",
        "remap": "scripts/companion/mole_companion.gd.remap",
        "remap_sha256": "ac73e224f4fe5b2f676b549a8ff565d72d014dfbab8fb31d2696482d18572946",
        "active": "scripts/companion/mole_companion.gdc",
        "active_sha256": "5fe20072148eea2f9f8970bfca594a511f89a1fd71561e11417f0460b81e4067",
    },
}
PRESERVE = {
    "scripts/player/native_worn/runtime_motion.gd": "2f5594057629eb9e15ad5385155da7cecd0aab3a418eb8648a0116eca311f720",
}

PET_HELPERS = '''

# These results live only in the caller's synchronous path search.
# Movement/separation outside that search still use the original collision query.
func _path_point_blocked(point: Vector2, results: Dictionary) -> bool:
\tif results.has(point): return bool(results[point])
\tvar blocked: bool = _blocked(point)
\tresults[point] = blocked
\treturn blocked

func _path_segment_clear(a: Vector2, b: Vector2, results: Dictionary) -> bool:
\tvar steps: int = maxi(1,ceili(a.distance_to(b)/12.0))
\tfor i in range(1,steps+1):
\t\tif _path_point_blocked(a.lerp(b,float(i)/float(steps)),results): return false
\treturn true
'''


def _replace(text, before, after):
    assert text.count(before) == 1, f"Expected one anchor: {before!r}"
    return text.replace(before, after, 1)


def transform(text: str, kind: str) -> str:
    expected = EXPECTED[kind]
    assert hashlib.sha256(text.encode()).hexdigest() == expected["source_sha256"], expected["source"]
    if kind == "contact":
        text = _replace(text, "\t\t\tfor iy in 9:\n",
            "\t\t\t# Pitch depends on this height/point, not the swivel being tested.\n"
            "\t\t\tvar pitch_bases: Array[Basis] = []\n"
            "\t\t\tfor pitch_index in 19:\n"
            "\t\t\t\tpitch_bases.append(Basis(pitch_axis,deg_to_rad(float(pitch_index)*5.0)))\n"
            "\t\t\tfor iy in 9:\n")
        text = _replace(text,
            "var tool := Transform3D(Basis(pitch_axis,pitch)*swivel_basis,Vector3.ZERO)",
            "var tool := Transform3D(pitch_bases[ip]*swivel_basis,Vector3.ZERO)")
    else:
        start = text.index("func _path_to(point: Vector2) -> Array[Vector2]:\n")
        end = text.index("\nfunc _scout_target(", start)
        path = text[start:end]
        path = _replace(path, "\tpath_searches+=1\n", "\tpath_searches+=1\n\tvar collision_results: Dictionary = {}\n")
        path = _replace(path, "if _blocked(center): continue", "if _path_point_blocked(center,collision_results): continue")
        path = _replace(path,
            "if not _segment_clear((Vector2(cell)+Vector2(0.5,0.5))*tile,center): continue",
            "if not _path_segment_clear((Vector2(cell)+Vector2(0.5,0.5))*tile,center,collision_results): continue")
        path = _replace(path,
            "and _segment_clear(global_position,start_center): result.push_front(start_center)",
            "and _path_segment_clear(global_position,start_center,collision_results): result.push_front(start_center)")
        text = text[:start] + path + text[end:] + PET_HELPERS
    assert "qa_round2_" not in text and "qa_world_" not in text
    return text


def qa_reference_scripts(contact_text: str, pet_text: str, active_runtime: str) -> dict[str, str]:
    """QA-only references; never add these resources to the clean candidate."""
    assert hashlib.sha256(contact_text.encode()).hexdigest() == EXPECTED["contact"]["source_sha256"]
    assert hashlib.sha256(pet_text.encode()).hexdigest() == EXPECTED["pet"]["source_sha256"]
    assert hashlib.sha256(active_runtime.encode()).hexdigest() == PRESERVE["scripts/player/native_worn/runtime_motion.gd"]
    return {
        "scripts/qa/suites/fixes_contact_original.gd": contact_text,
        "scripts/qa/suites/fixes_motion_original.gd": _replace(active_runtime,
            'extends "res://scripts/player/native_worn/task_motion.gd"',
            'extends "res://scripts/qa/suites/fixes_contact_original.gd"'),
        "scripts/qa/suites/fixes_pet_original.gd": _replace(pet_text,"class_name MoleCompanion\n", ""),
    }


if __name__ == "__main__":
    import pathlib, sys
    if len(sys.argv) != 4:
        raise SystemExit("usage: cpu_patch.py contact|pet INPUT OUTPUT")
    pathlib.Path(sys.argv[3]).write_text(transform(pathlib.Path(sys.argv[2]).read_text(), sys.argv[1]))
