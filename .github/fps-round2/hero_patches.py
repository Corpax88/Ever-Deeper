"""QA-only native CPU variants. transform(text, kind) preserves original methods.

Use repo text matching EXPECTED hashes, not stale runtime_motion.gd. Both compared
modes must use this same source-instrumented PCK. Compiled-original vs source
baseline must separately pass output parity; no timing attribution across those.
All toggles default false. No resource, timing, resolution or art changes.
"""
import hashlib

EXPECTED = {
    "rig": ("scripts/player/native_worn/native_rig.gd", "6b86f246c77a99c186b3018342d777d295b5ce5d7b142f63d0a872f21f922698"),
    "contact": ("scripts/player/native_worn/task_motion.gd", "4946e722a77231c5a47f34bf4af85536ccabbb2e3c0e4f3283b54db154e25f9a"),
}

RIG_ADDED = '''

# QA round 2. Cache data is immutable after configure; no pose frequency change.
var qa_round2_bind_cache: bool = false
var qa_round2_hero_profile: bool = false
var qa_round2_bind_calls: int = 0
var qa_round2_bind_usec: int = 0
var _qa_round2_bind_rows: Array = []

func _qa_round2_prepare_bind() -> void:
\tif not _qa_round2_bind_rows.is_empty(): return
\tfor index in skeleton.get_bone_count():
\t\tvar name: String = skeleton.get_bone_name(index)
\t\tif rest.has(name) and imported_rest.has(name):
\t\t\t_qa_round2_bind_rows.append([index,name,Transform3D(rest[name]).affine_inverse(),Transform3D(imported_rest[name])])

func _qa_round2_apply_cached(pose: Dictionary) -> void:
\tif skeleton == null: return
\t_qa_round2_prepare_bind()
\tfor row in _qa_round2_bind_rows:
\t\tvar name: String = row[1]
\t\tif not pose.has(name): continue
\t\tvar native: Transform3D = pose[name]
\t\tnative.origin -= root_native
\t\tvar delta: Transform3D = native * Transform3D(row[2])
\t\tskeleton.set_bone_global_pose(int(row[0]), mapping * delta * mapping_inverse * Transform3D(row[3]))

func _apply(pose: Dictionary) -> void:
\tvar started: int = Time.get_ticks_usec() if qa_round2_hero_profile else 0
\tif qa_round2_bind_cache: _qa_round2_apply_cached(pose)
\telse: _qa_round2_apply_original(pose)
\tif qa_round2_hero_profile:
\t\tqa_round2_bind_calls += 1
\t\tqa_round2_bind_usec += Time.get_ticks_usec() - started

func qa_round2_compare_bind_matrices(pose: Dictionary) -> Dictionary:
\tif skeleton == null: return {"exact":false,"error":"Missing skeleton"}
\t_qa_round2_prepare_bind()
\tvar checked: int = 0
\tvar mismatch: Array[String] = []
\tfor row in _qa_round2_bind_rows:
\t\tvar name: String = row[1]
\t\tif not pose.has(name): continue
\t\tvar native: Transform3D = pose[name]
\t\tnative.origin -= root_native
\t\tvar original_delta: Transform3D = native * Transform3D(rest[name]).affine_inverse()
\t\tvar cached_delta: Transform3D = native * Transform3D(row[2])
\t\tvar original: Transform3D = mapping * original_delta * mapping_inverse * Transform3D(imported_rest[name])
\t\tvar cached: Transform3D = mapping * cached_delta * mapping_inverse * Transform3D(row[3])
\t\tif original != cached: mismatch.append(name)
\t\tchecked += 1
\treturn {"exact":not checked == 0 and mismatch.is_empty(),"checked":checked,"mismatch":mismatch}
'''

CONTACT_ADDED = '''

# QA round 2. Both baseline and candidate keep the same exhaustive search order.
var qa_round2_contact_hoist: bool = false
var qa_round2_contact_profile: bool = false
var qa_round2_contact_calls: int = 0
var qa_round2_contact_usec: int = 0

func plan_contact(screen_target: Vector2, surfaces: Array = [], record_failure: bool = true) -> bool:
\tvar started: int = Time.get_ticks_usec() if qa_round2_contact_profile else 0
\tvar ok: bool
\tif qa_round2_contact_hoist: ok = _qa_round2_contact_hoisted(screen_target,surfaces,record_failure)
\telse: ok = _qa_round2_contact_original(screen_target,surfaces,record_failure)
\tif qa_round2_contact_profile:
\t\tqa_round2_contact_calls += 1
\t\tqa_round2_contact_usec += Time.get_ticks_usec() - started
\treturn ok
'''


def transform(text: str, kind: str) -> str:
    path, expected = EXPECTED[kind]
    assert hashlib.sha256(text.encode()).hexdigest() == expected, f"Unexpected authoritative ancestor: {path}"
    assert "qa_round2_" not in text
    if kind == "rig":
        assert text.count("func _apply(pose: Dictionary) -> void:") == 1
        text = text.replace("func _apply(pose: Dictionary) -> void:", "func _qa_round2_apply_original(pose: Dictionary) -> void:")
        needle = "func configure(candidate: String, pose_only: bool = false) -> bool:\n"
        assert text.count(needle) == 1
        text = text.replace(needle, needle + "\t_qa_round2_bind_rows.clear()\n")
        return text + RIG_ADDED
    start = text.index("func plan_contact(")
    end = text.index("\nfunc aimed(", start)
    original = text[start:end]
    hoisted = original.replace("func plan_contact(", "func _qa_round2_contact_hoisted(", 1)
    needle = "\t\t\tfor iy in 9:\n"
    assert hoisted.count(needle) == 1
    hoisted = hoisted.replace(needle,
        "\t\t\tvar pitch_bases: Array[Basis] = []\n"
        "\t\t\tfor pitch_index in 19:\n"
        "\t\t\t\tpitch_bases.append(Basis(pitch_axis,deg_to_rad(float(pitch_index)*5.0)))\n" + needle)
    needle = "var tool := Transform3D(Basis(pitch_axis,pitch)*swivel_basis,Vector3.ZERO)"
    assert hoisted.count(needle) == 1
    hoisted = hoisted.replace(needle,"var tool := Transform3D(pitch_bases[ip]*swivel_basis,Vector3.ZERO)")
    text = text[:start] + original.replace("func plan_contact(","func _qa_round2_contact_original(",1) + text[end:]
    return text + CONTACT_ADDED + "\n" + hoisted


if __name__ == "__main__":
    import pathlib, sys
    if len(sys.argv) != 4:
        raise SystemExit("usage: hero-cpu-patches.py rig|contact INPUT OUTPUT")
    pathlib.Path(sys.argv[3]).write_text(transform(pathlib.Path(sys.argv[2]).read_text(), sys.argv[1]))
