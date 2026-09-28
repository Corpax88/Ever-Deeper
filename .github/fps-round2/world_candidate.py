"""QA-only per-search collision memoization for exact DEV15.16 companion.

No production source is edited. Patch the original source with transform(text),
remap SOURCE_PATH to the patched source, and verify the PCK entry digests below.
The original _path_to body is retained verbatim under a private alternate name.
"""
import hashlib

SOURCE_PATH = "scripts/companion/mole_companion.gd"
ORIGINAL_REMAP_PATH = SOURCE_PATH + ".remap"
ORIGINAL_REMAP_SHA256 = "ac73e224f4fe5b2f676b549a8ff565d72d014dfbab8fb31d2696482d18572946"
ORIGINAL_ACTIVE_PATH = "scripts/companion/mole_companion.gdc"
ORIGINAL_ACTIVE_SHA256 = "5fe20072148eea2f9f8970bfca594a511f89a1fd71561e11417f0460b81e4067"
EXPECTED_SOURCE_SHA256 = "5c485b1e41ad40fe6c71368c7824b92932bc9a1f0114e732ed1300b9e6d7be73"
SOURCE_PROVENANCE = "ab0c12ff579134e0a092946bd92973e4599a073c; unchanged through DEV15.16 patch chain"

_VARS = """
# QA-only FPS round 2. Cache lifetime is one synchronous path search.
var qa_world_cache_enabled: bool = false
var _qa_world_search_active: bool = false
var _qa_world_blocked_cache: Dictionary = {}
var qa_world_path_calls: int = 0
var qa_world_path_usec: int = 0
var qa_world_blocked_calls: int = 0
var qa_world_blocked_evaluations: int = 0
var qa_world_cache_hits: int = 0
var qa_world_cache_peak: int = 0

"""

_METHODS = """

func qa_world_reset_counters() -> void:
	assert(not _qa_world_search_active)
	_qa_world_blocked_cache.clear()
	qa_world_path_calls = 0
	qa_world_path_usec = 0
	qa_world_blocked_calls = 0
	qa_world_blocked_evaluations = 0
	qa_world_cache_hits = 0
	qa_world_cache_peak = 0

func qa_world_snapshot() -> Dictionary:
	return {
		"enabled": qa_world_cache_enabled,
		"path_calls": qa_world_path_calls,
		"path_usec": qa_world_path_usec,
		"blocked_calls": qa_world_blocked_calls,
		"blocked_evaluations": qa_world_blocked_evaluations,
		"cache_hits": qa_world_cache_hits,
		"cache_peak": qa_world_cache_peak,
		"cache_entries_after_search": _qa_world_blocked_cache.size(),
		"search_active": _qa_world_search_active,
	}

func _blocked(point: Vector2) -> bool:
	if not _qa_world_search_active:
		return _qa_world_blocked_original(point)
	qa_world_blocked_calls += 1
	if qa_world_cache_enabled and _qa_world_blocked_cache.has(point):
		qa_world_cache_hits += 1
		return bool(_qa_world_blocked_cache[point])
	qa_world_blocked_evaluations += 1
	var result: bool = _qa_world_blocked_original(point)
	if qa_world_cache_enabled:
		_qa_world_blocked_cache[point] = result
		qa_world_cache_peak = maxi(qa_world_cache_peak, _qa_world_blocked_cache.size())
	return result

func _path_to(point: Vector2) -> Array[Vector2]:
	assert(not _qa_world_search_active)
	var started: int = Time.get_ticks_usec()
	_qa_world_blocked_cache.clear()
	_qa_world_search_active = true
	var result: Array[Vector2] = _qa_world_path_original(point)
	_qa_world_search_active = false
	_qa_world_blocked_cache.clear()
	qa_world_path_calls += 1
	qa_world_path_usec += Time.get_ticks_usec() - started
	return result
"""


def transform(text: str) -> str:
    assert hashlib.sha256(text.encode()).hexdigest() == EXPECTED_SOURCE_SHA256, "Unexpected companion source"
    assert text.count("func _blocked(point: Vector2) -> bool:") == 1
    assert text.count("func _path_to(point: Vector2) -> Array[Vector2]:") == 1
    assert text.count("var path_searches: int = 0\n") == 1
    text = text.replace("var path_searches: int = 0\n", "var path_searches: int = 0\n" + _VARS)
    text = text.replace("func _blocked(point: Vector2) -> bool:", "func _qa_world_blocked_original(point: Vector2) -> bool:")
    text = text.replace("func _path_to(point: Vector2) -> Array[Vector2]:", "func _qa_world_path_original(point: Vector2) -> Array[Vector2]:")
    return text + _METHODS


if __name__ == "__main__":
    import sys
    from pathlib import Path
    assert len(sys.argv) == 3, "Usage: world-candidate.py original.gd qa-output.gd"
    Path(sys.argv[2]).write_text(transform(Path(sys.argv[1]).read_text()))
