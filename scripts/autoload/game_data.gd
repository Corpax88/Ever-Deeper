extends Node

const DATA_PATH: = "res://data/ever_deeper_v0381.json"
const MANIFEST_PATH: = "res://data/source_manifest.json"

var data: Dictionary = {}
var manifest: Dictionary = {}


func _enter_tree() -> void :
	data = _load_json(DATA_PATH)
	manifest = _load_json(MANIFEST_PATH)
	_validate_core_contract()


func _load_json(path: String) -> Dictionary:
	assert (FileAccess.file_exists(path), "Missing production data: %s" % path)
	var file: = FileAccess.open(path, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	assert (parsed is Dictionary, "Invalid production JSON: %s" % path)
	return parsed


func _validate_core_contract() -> void :
	assert (String(manifest.source_version) == "0.38.1")
	assert (String(manifest.source_commit) == "d175489fd0bbd3d934481493eb9b4b7a668f461e")
	assert (int(manifest.parity_counts.assets) == 263)
	assert (int(manifest.parity_counts.mines) == 4)
	assert (int(manifest.parity_counts.achievements) == 50)
	assert (int(data.WORLD.width) == 4480)
	assert (int(data.WORLD.height) == 1280)


func world() -> Dictionary:
	return data.WORLD


func mine(id: String) -> Dictionary:
	assert (data.MINE_DEFINITIONS.has(id), "Unknown mine: %s" % id)
	return data.MINE_DEFINITIONS[id]


func station(id: String) -> Dictionary:
	assert (data.STATIONS.has(id), "Unknown station: %s" % id)
	return data.STATIONS[id]


func source_label() -> String:


	return "Ever Deeper · Deep Foundations 0.43"
