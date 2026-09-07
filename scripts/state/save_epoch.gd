class_name SaveEpoch
extends RefCounted


static func apply_once(
	legacy_path: String,
	marker_path: String,
	marker_contents: String
) -> bool:



	if legacy_path.is_empty() or marker_path.is_empty():
		return false
	if FileAccess.file_exists(marker_path):
		return true
	for suffix in ["", ".bak", ".tmp"]:
		var candidate: = legacy_path + String(suffix)
		if FileAccess.file_exists(candidate):
			var remove_error: = DirAccess.remove_absolute(
				ProjectSettings.globalize_path(candidate)
			)
			if remove_error != OK:
				return false
	var marker: = FileAccess.open(marker_path, FileAccess.WRITE)
	if marker == null:
		return false
	marker.store_string(marker_contents)
	marker.flush()
	return true
