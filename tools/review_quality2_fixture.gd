extends SceneTree
var main: Node
var suite: RefCounted
func _initialize() -> void: run.call_deferred()
func settle() -> void:
	for i in 8: await process_frame
	await RenderingServer.frame_post_draw
func sample() -> void:
	suite._quality_geometry()
	suite._quality_feedback()
	suite._quality2_route_snapshot()
	suite._quality2_target_snapshot()
func run() -> void:
	await process_frame
	main=load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	current_scene=main
	await settle()
	main.persistence_active=false
	main._dev_ensure_playing()
	suite=load("res://scripts/qa/suites/skills_browser_review.gd").new(main,main.qa_launcher)
	await suite._command({"kind":"quality2_sale","action":"setup","id":1})
	await settle()
	sample()
	main.treasury_goal_panel.close_panel()
	for scenario in ["source","deep-source","return","hub-donation","donation","podium","rune","cancel-rune"]:
		await suite._command({"kind":"quality2_route","scenario":scenario,"id":2})
		await settle()
		sample()
		print("QUALITY2_FIXTURE_SCENARIO "+scenario)
	await suite._command({"kind":"quality2_target","id":3})
	await settle()
	sample()
	await suite._command({"kind":"quality_feedback","id":4})
	await settle()
	sample()
	print("QUALITY2_FIXTURE_RUNTIME_OK")
	quit()
