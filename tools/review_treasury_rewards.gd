extends SceneTree
## Scoped rendered reward/card review against the actual production package.
var main: Node
var state: Node
var goals: Script
var card: Control
var output: String
var checks: Array = []
var snapshots: Array = []

func _initialize() -> void:
	run.call_deferred()

func check(label: String, passed: bool) -> void:
	checks.append({"name":label,"passed":passed})
	if not passed: print("TREASURY_REWARDS_MISMATCH "+label)

func settle() -> void:
	for _frame in 4: await process_frame
	await RenderingServer.frame_post_draw

func tap(button: Button) -> void:
	var at: Vector2=button.get_global_transform_with_canvas()*(button.size*0.5)
	var down: InputEventScreenTouch=InputEventScreenTouch.new()
	down.index=7;down.position=at;down.pressed=true
	Input.parse_input_event(down)
	await process_frame
	var up: InputEventScreenTouch=InputEventScreenTouch.new()
	up.index=7;up.position=at;up.pressed=false
	Input.parse_input_event(up)
	await settle()

func geometry(label: String) -> void:
	var canvas: Rect2=Rect2(Vector2.ZERO,Vector2(root.size))
	var rects: Dictionary={}
	for name in ["heading","title","detail","progress_bar","progress","equipped","source","claim_button","pin_button","close_button"]:
		var control: Control=card.get(name)
		if not control.is_visible_in_tree(): continue
		var rect: Rect2=root.get_final_transform()*control.get_global_transform_with_canvas()*Rect2(Vector2.ZERO,control.size)
		rects[name]=rect
		check(label+" "+name+" on screen",canvas.encloses(rect))
		if control is Label:
			var font: Font=control.get_theme_font("font")
			var font_size: int=control.get_theme_font_size("font_size")
			check(label+" "+name+" text height fits",control.get_line_count()*font.get_height(font_size)<=control.size.y+1)
			if control.autowrap_mode==TextServer.AUTOWRAP_OFF:
				for line in control.text.split("\n"):
					check(label+" "+name+" text width fits",font.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x<=control.size.x+1)
		elif control is Button:
			check(label+" "+name+" touch height",rect.size.y>=88)
	for a in rects:
		for b in rects:
			# Abutting header bounds share an edge; canvas scaling can round that
			# common edge by a few millionths of a pixel.
			if a<b: check(label+" "+a+" separate from "+b,not rects[a].grow(-0.05).intersects(rects[b].grow(-0.05)))
	snapshots.append({"case":label,"title":card.title.text,"detail":card.detail.text,"progress":card.progress.text,"equipped":card.equipped.text,"source":card.source.text,"claim":card.claim_button.text,"rects":rects})

func capture(label: String) -> void:
	await settle()
	geometry(label)
	root.get_texture().get_image().save_png(output.path_join(label+".png"))

func open(kind: String, amount: int, held: int=0) -> void:
	if card.visible: card.close_panel()
	state.treasury_totals[kind]=amount
	if kind=="wallet_gold": state.gold=held
	else: state.cargo[kind]=held
	card.open_goal(kind)
	await settle()

func run() -> void:
	output=OS.get_environment("MODS_OUT")
	if output.is_empty() or DisplayServer.get_name()=="headless":
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(output)
	await process_frame
	goals=load("res://scripts/state/treasury_goals.gd")
	main=load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main);current_scene=main
	for _frame in 5: await process_frame
	state=root.get_node("RunState")
	state.initialize_persistence(output.path_join("save.json"))
	state.reset_run(false)
	main._dev_ensure_playing()
	main._dev_seed_victory_state()
	main._dev_jump_hub()
	main.quick_tutorial.dismiss()
	main.get_node("MinerTraining").set_process(false)
	main.achievement_toast.clear()
	card=main.treasury_goal_panel
	for width in [667,844]:
		root.size=Vector2i(width*2,750 if width==667 else 780)
		root.content_scale_size=root.size
		await settle()
		state.treasury_goals=goals.clean({})
		for amount in [56000,95000,100000]:
			await open("copper",amount,8000 if amount==56000 else 5000)
			check(str(width)+" collection material and real reward "+str(amount),card.title.text=="COPPER COLLECTION" and card.detail.text.to_lower().contains("permanent") and not card.claim_button.visible)
			check(str(width)+" accurate delivered and held "+str(amount),card.progress.text.contains(card._number(amount)+" / 100,000 delivered") and card.progress.text.contains("8,000 held" if amount==56000 else "5,000 held"))
			check(str(width)+" no active-mod claim for collection "+str(amount),not card.equipped.visible and card.pin_button.disabled==(amount==100000))
			await capture(str(width)+"-collection-"+str(amount))
		for kind in goals.MODS:
			await open(kind,56000,12345)
			check(str(width)+" locked mod "+kind,card.claim_button.disabled and card.claim_button.text=="FILL PODIUM TO UNLOCK")
			await capture(str(width)+"-mod-"+kind)
		await open("wallet_gold",100000,6000)
		check(str(width)+" new claim explains automatic equip",card.claim_button.text=="CLAIM & EQUIP" and card.equipped.text.contains("Equipped: None"))
		await capture(str(width)+"-claim-ready")
		await tap(card.claim_button)
		check(str(width)+" actual touch claims and equips",goals.active_mod()=="resonance" and card.claim_button.text=="UNEQUIP" and card.equipped.text.contains("Equipped: Resonance"))
		await capture(str(width)+"-equipped")
		await tap(card.claim_button)
		check(str(width)+" actual touch unequips",goals.active_mod().is_empty() and card.claim_button.text=="EQUIP" and bool(state.treasury_goals.resonance_claimed))
		await capture(str(width)+"-unequipped")
		await tap(card.claim_button)
		await open("rootiron",100000,987)
		check(str(width)+" another equipped mod is disclosed",card.equipped.text.contains("Equipped: Resonance") and card.equipped.text.contains("replaces it") and card.claim_button.text=="CLAIM & EQUIP")
		await capture(str(width)+"-replace-equipped")
		await tap(card.claim_button)
		check(str(width)+" actual touch replaces only active mod",goals.active_mod()=="twin_auger" and not bool(state.treasury_goals.resonance_enabled) and bool(state.treasury_goals.resonance_claimed))
		await capture(str(width)+"-replacement-active")
		# Every material title is dynamic; check the full real catalog for fit.
		for kind in goals.Ledger.keys():
			await open(kind,34000,90123)
			geometry(str(width)+"-catalog-"+kind)
		card.close_panel()
	var passed: bool=true
	for row in checks: passed=passed and row.passed
	FileAccess.open(output.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":passed,"checks":checks},"  "))
	FileAccess.open(output.path_join("snapshots.json"),FileAccess.WRITE).store_string(JSON.stringify(snapshots,"  "))
	print("TREASURY_REWARDS_OK "+str(checks.size()) if passed else "TREASURY_REWARDS_FAILED")
	quit(0 if passed else 1)
