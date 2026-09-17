extends SceneTree
const Contract = preload("presentation_contract.gd")
var checks: Array[Dictionary] = []
var failures: Array[String] = []
var bank_bytes: PackedByteArray
var bank_sha := ""


func _initialize() -> void:
	call_deferred("run")


func verify(label: String, ok: bool) -> void:
	checks.append({"label": label, "passed": ok})
	if not ok: failures.append(label)


func fresh() -> RefCounted:
	var contract = Contract.new()
	assert(contract.configure(bank_bytes, bank_sha))
	return contract


func proof(capture: Dictionary) -> Dictionary:
	return {"kind": "verified_original_capture", "image_sha256": capture.sha256,
		"bank_sha256": bank_sha, "drawn_frame": capture.drawn_frame}


func packet(identifier: int, state: String, direction: String) -> Dictionary:
	return {"request_id": identifier, "state": state, "direction": direction,
		"gear": "worn", "bank_sha256": bank_sha}


func run() -> void:
	var args := OS.get_cmdline_user_args()
	assert(args.size() == 4, "manifest right-report up-report output")
	bank_bytes = FileAccess.get_file_as_bytes(args[0])
	bank_sha = bank_bytes.get_string_from_utf8().sha256_text()
	verify("Actual original manifest identity", bank_sha == "9a7dd27227512941adbe61a87bd70c4ef6666b9de56606dff7b5f9e97bac4376")
	var invalid = Contract.new()
	verify("Changed bank digest is rejected", not invalid.configure(bank_bytes, "0".repeat(64)))
	var reports: Array = []
	for report_path in [args[1], args[2]]:
		var doc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(report_path))
		var before := JSON.stringify(doc).sha256_text()
		var contract = fresh()
		var source_ids: Array = []
		var bridge_samples := 0
		for index in doc.samples.size():
			var sample: Dictionary = doc.samples[index]
			var capture: Dictionary = doc.captures[index]
			var bytes := FileAccess.get_file_as_bytes(String(report_path).get_base_dir().path_join(capture.path))
			var hashing := HashingContext.new()
			hashing.start(HashingContext.HASH_SHA256)
			hashing.update(bytes)
			verify("%s original %d hash" % [doc.direction,index], hashing.finish().hex_encode() == String(capture.sha256))
			verify("%s original %d draw binding" % [doc.direction,index], int(capture.sample) == index and int(capture.drawn_frame) == int(sample.visual.drawn_frame))
			var identity: String = contract.accept_recorded_draw(sample.visual, proof(capture))
			verify("%s recorded draw %d exact sample" % [doc.direction,index], not identity.is_empty())
			source_ids.append(identity)
			var state := String(sample.visual.logical_state)
			var physical := {"sequence": index, "sample": sample.duplicate(true)}
			verify("%s immutable packet %d" % [doc.direction,index], contract.submit_request(packet(index,state,doc.direction),[physical]))
			var result: Dictionary = contract.resolve(identity)
			verify("%s packet does not replace draw %d" % [doc.direction,index], contract.source_id() == identity and result.source_id == identity)
			if bool(sample.visual.is_bridge):
				bridge_samples += 1
				verify("%s bridge interior remains uncovered %d" % [doc.direction,index], not result.covered and result.reason == "bridge_interior_policy_uncovered")
			# Planning snapshots are caller-owned copies, never mutable ledger aliases.
			result.physical_events.clear()
			verify("%s journal retained %d" % [doc.direction,index], contract.events_snapshot().size() == index+1)
		verify("%s complete physics/damage records unchanged" % doc.direction, JSON.stringify(doc).sha256_text() == before)
		var journal: Array = contract.events_snapshot()
		verify("%s every physical record exact and ordered" % doc.direction, journal.map(func(x):return x.sample) == doc.samples)
		for index in doc.events.size():
			var event: Dictionary = doc.events[index]
			var matching: Array = doc.captures.filter(func(x): return int(x.drawn_frame) == int(event.actual_source_pose.drawn_frame))
			verify("%s event %d has original source frame" % [doc.direction,index], matching.size() == 1)
			if matching.size() != 1: continue
			var ledger = fresh()
			var identity: String = ledger.accept_recorded_draw(event.actual_source_pose, proof(matching[0]))
			var wanted := "mine" if bool(event.mine) else "walk"
			verify("%s pre-coalesced request %d" % [doc.direction,index], ledger.submit_request(packet(1,"idle",doc.direction),[{"sequence":1,"kind":"physical-before"}]))
			var request := packet(2,wanted,doc.direction)
			verify("%s final coalesced request %d" % [doc.direction,index], ledger.submit_request(request,[{"sequence":2,"original_event":event}]))
			request.state = "idle"
			var decision: Dictionary = ledger.resolve(identity)
			verify("%s exact declared event route %d" % [doc.direction,index], decision.covered and decision.reason == "exact_declared_edge_timing_not_yet_validated" and decision.request.state == wanted)
			verify("%s coalescing preserves ordered events %d" % [doc.direction,index], decision.physical_events.size() == 2 and decision.physical_events[1].original_event == event)
			verify("%s stale source rejected %d" % [doc.direction,index], not bool(ledger.resolve(identity+"changed").covered))
			var old_events := JSON.stringify(ledger.events_snapshot())
			verify("%s invalid event batch atomic %d" % [doc.direction,index], not ledger.submit_request(packet(3,wanted,doc.direction),[{"sequence":3},{"sequence":2}]) and JSON.stringify(ledger.events_snapshot()) == old_events)
			verify("%s rapid turn stays uncovered %d" % [doc.direction,index], ledger.submit_request(packet(4,wanted,"left")) and not bool(ledger.resolve(identity).covered))
			var fake: Dictionary = event.actual_source_pose.duplicate(true)
			fake.sample_phase += 0.000001
			verify("%s no nearest-source substitution %d" % [doc.direction,index], fresh().accept_recorded_draw(fake,proof(matching[0])).is_empty())
			fake = event.actual_source_pose.duplicate(true)
			fake.actually_presented = false
			verify("%s selected-only source rejected %d" % [doc.direction,index], fresh().accept_recorded_draw(fake,proof(matching[0])).is_empty())
			fake = event.actual_source_pose.duplicate(true)
			fake.retained_offset[0] += 1.0
			verify("%s altered offset has different identity %d" % [doc.direction,index], fresh().accept_recorded_draw(fake,proof(matching[0])) != identity)
			fake = event.actual_source_pose.duplicate(true)
			fake.local_frame += 0.1
			verify("%s fractional frame cannot truncate into real frame %d" % [doc.direction,index], fresh().accept_recorded_draw(fake,proof(matching[0])).is_empty())
			var fractional := packet(5,wanted,doc.direction)
			fractional.request_id = 5.1
			verify("%s fractional event/request IDs reject %d" % [doc.direction,index], not ledger.submit_request(fractional) and not ledger.submit_request(packet(5,wanted,doc.direction),[{"sequence":3.1}]))
		reports.append({"direction":doc.direction,"source_report":report_path,"samples":doc.samples.size(),"recorded_bridge_frames":bridge_samples,"source_ids":source_ids})
	var output := {"schema":1,"kind":"headless_replay_of_verified_original_draw_records","passed":failures.is_empty(),
		"manifest_sha256":bank_sha,"checks":checks,"failures":failures,"replays":reports,
		"limits":["No new rendering, gameplay, timing or ordinary-input acceptance.","The caller verifies PNG hashes; ledger acknowledgments are recorded evidence, not a live renderer integration.","Only state/heading route metadata is resolved; deadlines, speed, cycle/lifecycle and actual event presentation remain unimplemented."]}
	var file := FileAccess.open(args[3],FileAccess.WRITE)
	file.store_string(JSON.stringify(output,"  ")+"\n")
	file.close()
	print("NATIVE_PRESENTATION_CONTRACT_REPLAY checks=%d failures=%d" % [checks.size(),failures.size()])
	for failure in failures: print(failure)
	quit(0 if failures.is_empty() else 1)
