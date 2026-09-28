"""Consume exclusively owned fresh motion poses; preserve public copy semantics.

Starts from untouched DEV15.16 task source. No contact-pitch hoist, inverse-rest
change, QA switch, persistent pose cache, changed arithmetic, or altered state.
"""
import hashlib

EXPECTED = {
    "source": "scripts/player/native_worn/task_motion.gd",
    "source_sha256": "4946e722a77231c5a47f34bf4af85536ccabbb2e3c0e4f3283b54db154e25f9a",
    "original_file": "../fps-round2/contact-original.gd",
    "remap": "scripts/player/native_worn/task_motion.gd.remap",
    "remap_sha256": "b768c773900a6cda757c71b6634ff230b3a2b091615373b3eaf359e1ad210b32",
    "active": "scripts/player/native_worn/task_motion.gdc",
    "active_sha256": "ec2341e53515837a62197ba6a6754ffdb719bf1ba1cffc9cdc952b33c57027e6",
}
PRESERVE_RUNTIME_SHA256 = "2f5594057629eb9e15ad5385155da7cecd0aab3a418eb8648a0116eca311f720"

HELPERS = '''

# These two private methods consume a freshly produced pose. They must never
# receive bank, shown, older, transition_source, or a caller-owned pose.
func _rotate_fresh_sample(family: String, at: float, angle: float, translation: Vector3 = Vector3.ZERO) -> Dictionary:
	# Every branch of the approved mix creates fresh outer/bones dictionaries.
	# Interior weights still borrow bank.contacts; detach that nested dictionary
	# once so the returned pose retains rotate_pose's fully independent ownership.
	var result: Dictionary = sample(family,at)
	result.contacts = result.contacts.duplicate(true)
	var transform := Transform3D(Basis(Vector3(0,0,1),angle),translation)
	for name in result.bones: result.bones[name] = transform*result.bones[name]
	return result

func _world_owned(pose: Dictionary) -> Dictionary:
	# Only freshly returned aimed() / _rotate_fresh_sample() results call here.
	for name in pose.bones: pose.bones[name].origin += root_position
	return pose
'''


def _once(text: str, before: str, after: str) -> str:
    assert text.count(before) == 1, f"Expected exactly one: {before!r}"
    return text.replace(before, after, 1)


def transform(text: str) -> str:
    assert hashlib.sha256(text.encode()).hexdigest() == EXPECTED['source_sha256'], 'Unexpected original task source'
    text = _once(text,
        'var result := rotate_pose(sample("mine",at),contact_yaw)',
        'var result := _rotate_fresh_sample("mine",at,contact_yaw)')
    text = _once(text,
        'var wanted := _world(aimed(phase) if mode == "mine" and aim_ready else rotate_pose(sample(mode,phase),yaw))',
        'var wanted := _world_owned(aimed(phase) if mode == "mine" and aim_ready else _rotate_fresh_sample(mode,phase,yaw))')
    text = _once(text, 'displayed = _world(aimed(.42))', 'displayed = _world_owned(aimed(.42))')
    assert 'pitch_bases' not in text and 'qa_round2_' not in text
    return text + HELPERS


def qa_reference_scripts(original_task: str, active_runtime: str) -> dict[str, str]:
    assert hashlib.sha256(original_task.encode()).hexdigest() == EXPECTED['source_sha256']
    assert hashlib.sha256(active_runtime.encode()).hexdigest() == PRESERVE_RUNTIME_SHA256
    return {
        'scripts/qa/suites/fixes_v2_task_original.gd': original_task,
        'scripts/qa/suites/fixes_v2_motion_original.gd': _once(active_runtime,
            'extends "res://scripts/player/native_worn/task_motion.gd"',
            'extends "res://scripts/qa/suites/fixes_v2_task_original.gd"'),
    }


if __name__ == '__main__':
    import sys
    from pathlib import Path
    assert len(sys.argv) == 3, 'Usage: motion_patch.py ORIGINAL_TASK_GD OUTPUT_GD'
    Path(sys.argv[2]).write_text(transform(Path(sys.argv[1]).read_text()))
