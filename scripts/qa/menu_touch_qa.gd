extends RefCounted
var driver: Node
var main: Node
var checks: int = 0
var failures: Array[String] = []
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label);print("OVERHAUL_CHECK_FAILED ", label)
func settle() -> void:
	for i in 6: await driver.get_tree().process_frame
func point(c: Control, fraction: Vector2 = Vector2(0.5,0.65)) -> Vector2:
	return c.get_global_transform_with_canvas() * (c.size * fraction)
func gesture(kind: String, start: Vector2, delta: Vector2 = Vector2.ZERO, label: String = "") -> void:
	if OS.has_feature("web"):
		driver._acknowledged = false;driver._waiting_for_ack = true
		var size: Vector2 = driver.get_viewport().get_visible_rect().size
		print("EVER_DEEPER_OVERHAUL_INPUT_READY ",JSON.stringify({"kind":kind,"x":start.x,"y":start.y,"dx":delta.x,"dy":delta.y,"label":label,"width":size.x,"height":size.y}))
		check(await driver._wait_for_ack(), "Browser acknowledges " + kind)
	else:
		if kind in ["capture","record_start","record_stop"]: return
		var event = InputEventScreenTouch.new();event.index=5;event.pressed=true;event.position=start
		if kind != "release": driver.get_viewport().push_input(event,true)
		if kind in ["swipe","hold"]:
			for i in range(1,7):
				var drag = InputEventScreenDrag.new();drag.index=5;drag.position=start+delta*float(i)/6.0;drag.relative=delta/6.0
				driver.get_viewport().push_input(drag,true);await driver.get_tree().process_frame
		event=InputEventScreenTouch.new();event.index=5;event.position=start+delta;event.canceled=kind=="cancel"
		if kind != "hold": driver.get_viewport().push_input(event,true)
	await settle()
func rest_carousel() -> void:
	for i in range(180):
		if not main.commerce_panel.catalog_scroll.moving: break
		await driver.get_tree().process_frame
	await settle()

func swipe(scroll: ScrollContainer, horizontal: bool, label: String) -> void:
	check(scroll is TouchScrollContainer, label + " uses shared finger scrolling")
	scroll.scroll_horizontal=0;scroll.scroll_vertical=0
	await settle()
	print("TOUCH_RANGE ",label," ",scroll.get_v_scroll_bar().max_value,"/",scroll.get_v_scroll_bar().page," h=",scroll.get_h_scroll_bar().max_value,"/",scroll.get_h_scroll_bar().page," rect=",scroll.get_global_rect())
	var before: int = scroll.scroll_horizontal if horizontal else scroll.scroll_vertical
	await gesture("swipe",point(scroll),Vector2(-110,0) if horizontal else Vector2(0,-100))
	scroll.velocity=Vector2.ZERO
	check((scroll.scroll_horizontal if horizontal else scroll.scroll_vertical)>before+20,label + " scrolls by dragging content")
	await gesture("capture",Vector2.ZERO,Vector2.ZERO,label)
func run(d: Node, m: Node) -> bool:
	driver=d;main=m
	driver.get_tree().root.content_scale_size=Vector2i(1560,720)
	driver.get_tree().root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_IGNORE
	await settle()
	await test_pause_modal()
	await test_wardrobe()
	await test_light_lab()
	driver._prepare_pet_state({"location":"mine","variant":"ready","tab":"skills"})
	await settle()
	var journal = main.get_node("CompanionInterface").journal
	var learn: Button=journal.find_child("Learn_trailrunner",true,false)
	var gold: int=RunState.gold
	await gesture("swipe",point(learn,Vector2(0.5,0.5)),Vector2(0,-100))
	journal.scroll.velocity=Vector2.ZERO
	check(journal.scroll.scroll_vertical>30,"Pet skill cards swipe from Learn button")
	check(RunState.gold==gold and not MoleSkills.has_skill("trailrunner"),"Swipe over Learn never buys a skill")
	await gesture("capture",Vector2.ZERO,Vector2.ZERO,"pet-skills-swiped")
	journal.scroll.scroll_vertical=0;await settle()
	await gesture("cancel",point(learn,Vector2(0.5,0.5)))
	check(RunState.gold==gold,"Canceled finger never buys a skill")
	await gesture("tap",point(learn,Vector2(0.5,0.5)))
	check(MoleSkills.has_skill("trailrunner") and RunState.gold==gold-35,"A deliberate tap still learns exactly once")
	await swipe(journal.scroll,false,"pet-text-swiped")
	journal.close_journal()
	var cargo: Dictionary={}
	for id in RunState.RESOURCE_IDS:cargo[id]=20
	main.resource_inventory.open_inventory(cargo,{},false);await settle()
	await swipe(main.resource_inventory.find_child("Scroll",true,false),false,"inventory-swiped")
	main.resource_inventory.close_inventory()
	main.premium_menu.open_menu(true,"Mossvein",true,false);main.premium_menu.show_achievements();await settle()
	await swipe(main.premium_menu.achievement_scroll,false,"achievements-swiped")
	main.premium_menu.close_menu()
	# Preview is a deliberate selection, independent of browsing and buying.
	driver._prepare_commerce_capture("starforge_ready_crusher");await settle()
	var panel = main.commerce_panel
	var carousel = panel.catalog_scroll
	var original_cargo: Dictionary = RunState.cargo.duplicate(true)
	check(not panel.swipe_pager.horizontal_enabled,"Three Starforge options stay fixed")
	var confirmations: Array[String] = []
	var on_confirm = func(id: String): confirmations.append(id)
	panel.action_confirmed.connect(on_confirm)
	for index in [1,2,0,1]:
		var card: Button = panel.catalog_strip.get_child(index)
		await gesture("tap",point(card))
		check(panel.selected_item_id()==String(panel._items[index].id),"Tap immediately previews core " + str(index))
		check(panel.hero_icon.texture==panel._item_texture(panel._items[index]),"Preview art matches tapped core " + str(index))
		check(carousel.scroll_horizontal==0,"All three cores remain visible after tap")
		for other in panel.catalog_strip.get_children():
			check(carousel.get_global_rect().encloses(other.get_global_rect()),"Core card remains fully visible")
		await gesture("capture",Vector2.ZERO,Vector2.ZERO,"tap-core-"+str(index))
	check(RunState.cargo==original_cargo and RunState.starforge_variant.is_empty() and confirmations.is_empty(),"Preview never spends materials, equips or confirms")
	await gesture("swipe",point(carousel),Vector2(-110,0));await rest_carousel()
	check(panel.selected_item_id()=="starforge:swift" and carousel.scroll_horizontal==0,"Swiping a short list does not change preview or hide options")
	await gesture("cancel",point(panel.catalog_strip.get_child(2)));await rest_carousel()
	check(panel.selected_item_id()=="starforge:swift","Canceled tap never selects another core")
	var comet_point: Vector2 = point(panel.catalog_strip.get_child(1))
	await gesture("tap",point(panel.catalog_strip.get_child(0)))
	await gesture("hold",comet_point,Vector2(8,0))
	await gesture("release",comet_point+Vector2(8,0))
	check(panel.selected_item_id()=="starforge:swift","Small finger movement still counts as a preview tap")
	await gesture("tap",point(panel.primary_button))
	check(confirmations==["starforge:swift"],"Forge button confirms the previewed core exactly once")
	check(RunState.starforge_variant=="swift" and RunState.cargo.astralite==33 and RunState.cargo.crownstone==33,"Only Forge Core purchases and equips the selected core")
	panel.action_confirmed.disconnect(on_confirm)
	panel.close_commerce()
	for fixture in ["workshop_tool_forge_baseline","workshop_light_lab_baseline","workshop_wardrobe_baseline"]:
		driver._prepare_commerce_capture(fixture);await settle()
		carousel=panel.catalog_scroll
		var selected: String = panel.selected_item_id()
		var cargo_before: Dictionary = RunState.cargo.duplicate(true)
		var first: Button = panel.catalog_strip.get_child(0)
		var original_x: float = first.get_global_rect().position.x
		await gesture("hold",point(carousel),Vector2(-110,0))
		check(carousel.held and first.get_global_rect().position.x < original_x-30,"Long shop list follows the finger: "+fixture)
		check(panel.selected_item_id()==selected,"Held swipe leaves preview unchanged: "+fixture)
		await gesture("release",point(carousel)+Vector2(-110,0));await rest_carousel()
		check(carousel.scroll_horizontal>40 and panel.selected_item_id()==selected,"Swipe browses without selecting: "+fixture)
		var target: Button = null
		for card in panel.catalog_strip.get_children():
			if carousel.get_global_rect().encloses(card.get_global_rect()) and String(card.get_meta("item_id"))!=selected:
				target=card;break
		check(target!=null,"A browsed card is available to tap: "+fixture)
		if target!=null:
			var target_id: String=String(target.get_meta("item_id"))
			var offset: int=carousel.scroll_horizontal
			await gesture("tap",point(target))
			check(panel.selected_item_id()==target_id,"Tap selects after browsing: "+fixture)
			check(carousel.scroll_horizontal==offset,"Tap keeps browsed list in place: "+fixture)
			check(panel.hero_icon.texture==panel._item_texture(panel.selected_item()),"Workshop preview art matches selection: "+fixture)
		check(RunState.cargo==cargo_before,"Workshop browsing and preview never spend materials: "+fixture)
		await gesture("capture",Vector2.ZERO,Vector2.ZERO,fixture+"-tap-preview")
		panel.close_commerce()
	driver._prepare_commerce_capture("forge_mastery_rank_five_ready");await settle()
	var detail: ScrollContainer=panel.overview_scroll
	if detail.get_v_scroll_bar().max_value > detail.get_v_scroll_bar().page + 20:
		await swipe(detail,false,"shop-details-swiped")
	else:
		check(detail is TouchScrollContainer,"Shop details retain touch scrolling")
	panel.close_commerce()
	if main.developer_menu != null:
		main.developer_menu.open_menu()
		await settle()
		await swipe(main.developer_menu.scroll,false,"dev-tools-swiped")
		main.developer_menu.close_menu()
	print("EVER_DEEPER_OVERHAUL_GAMEPLAY_%s checks=%d failures=%s" % ["OK" if failures.is_empty() else "FAILED",checks,JSON.stringify(failures)])
	return failures.is_empty()

func test_pause_modal() -> void:
	driver._prepare_commerce_capture("starforge_owned_active")
	main.commerce_panel.close_commerce()
	main.automated_mode = false
	main.game_started = true
	main.surface_context = "starforge"
	main._refresh_context_button()
	await settle()
	var browse: Button = main.premium_hud.context_button
	var settings: Button = main.premium_menu.main_card.get_node("Settings")
	main._open_start_menu()
	await settle()
	# Force the exact overlap irrespective of desktop/mobile viewport scaling.
	var saved_position: Vector2 = browse.global_position
	browse.global_position = point(settings, Vector2(0.5, 0.5)) - browse.size * 0.5
	await gesture("tap", point(settings, Vector2(0.5, 0.5)))
	check(main.menu_open and main.premium_menu.detail_view.visible, "Settings receives tap over underlying Starforge Browse")
	check(not main.commerce_panel.is_open(), "Pause menu tap cannot open Starforge")
	main._perform_context()
	check(not main.commerce_panel.is_open(), "Context callback is blocked while paused")
	await gesture("tap", point(browse, Vector2(0.5, 0.5)))
	check(not main.commerce_panel.is_open(), "Settings blocks underlying Browse hit area")
	await gesture("capture", Vector2.ZERO, Vector2.ZERO, "settings-blocks-starforge")
	browse.global_position = saved_position
	main._hide_start_menu()
	await settle()
	await gesture("tap", point(browse, Vector2(0.5, 0.5)))
	check(main.commerce_panel.is_open(), "Browse works again after closing pause menu")
	main.commerce_panel.close_commerce()
	main.automated_mode = true


func test_wardrobe() -> void:
	driver._prepare_overhaul_extra({"kind":"overhaul_wardrobe", "level":1, "variant":"missing"})
	await settle()
	var panel = main.commerce_panel
	check(panel._items.size() == 5, "Wardrobe has exactly five distinct colors")
	check(panel.primary_button.disabled, "Unaffordable outfit unlock disabled")
	check(not RunState.set_endless_outfit("deepheart"), "Locked outfit cannot be equipped")
	var outfit_before: String = RunState.endless_outfit
	var resource: String = String(RunState.workshop_status("wardrobe").next_upgrade.resource)
	var cost: int = int(RunState.workshop_status("wardrobe").next_upgrade.cost)
	RunState.cargo[resource] = cost + 11
	panel.refresh_commerce(driver.CommerceCatalogScript.workshop_config("wardrobe", RunState.workshop_status("wardrobe"), main.hub_world.workshop_selection_preview("wardrobe")))
	await settle()
	panel._select_item("workshop:upgrade")
	check(RunState.endless_outfit == outfit_before, "Preview does not equip outfit")
	await gesture("tap", point(panel.primary_button))
	check(int(RunState.workshop_status("wardrobe").level) == 2 and int(RunState.cargo[resource]) == 11, "Unlock charges exact existing price once")
	check(RunState.endless_outfit == outfit_before, "Unlock leaves current clothes on")
	check(panel.selected_item_id() == "workshop:equip:expedition", "Unlock keeps newly owned outfit in preview")
	await gesture("tap", point(panel.primary_button))
	check(RunState.endless_outfit == "expedition" and int(RunState.cargo[resource]) == 11, "Wear equips for free after unlock")
	check(panel.primary_button.disabled, "Wearing button cannot double equip")
	await gesture("capture", Vector2.ZERO, Vector2.ZERO, "wardrobe-new-outfit-worn")
	panel.close_commerce()
	var saved: Dictionary = RunState.serialize()
	check(RunState.deserialize(saved) and RunState.endless_outfit == "expedition", "Outfit persists through save reload")
	driver._prepare_overhaul_extra({"kind":"overhaul_wardrobe", "level":5, "outfit":"miner"})
	await settle()
	for outfit in RunState.ENDLESS_OUTFIT_IDS:
		panel._select_item("workshop:equip:" + outfit)
		await settle()
		var preview = panel.hero_icon.get_node("OutfitPreview")
		check(preview.outfit == outfit and preview._sprite.texture.resource_path.begins_with("res://assets/hero/dad/"), "Current hero preview: " + outfit)
		check(preview._sprite.material.get_shader_parameter("cloth_color") == preview.Hero.OUTFIT_COLORS[outfit], "Production outfit color: " + outfit)
		if not panel.primary_button.disabled: await gesture("tap", point(panel.primary_button))
		check(RunState.endless_outfit == outfit, "Correct outfit equipped: " + outfit)
		await gesture("capture", Vector2.ZERO, Vector2.ZERO, "wardrobe-wearing-" + outfit)
	panel.close_commerce()
	await settle()
	check(not ResourceLoader.has_cached("res://assets/hero/dad/wardrobe/crossed-arms-v2.png"), "Closing wardrobe releases the full-resolution portrait from the resource cache")


func test_light_lab() -> void:
	driver._prepare_light_state({"level": 1, "variant": "missing"})
	await settle()
	var panel = main.commerce_panel
	check(panel.primary_button.disabled, "Light upgrade requires materials")
	check(not RunState.set_endless_light_style("deepheart"), "Locked light style cannot equip")
	var preview = panel.hero_well.get_node("LightPreview")
	var cargo: Dictionary = RunState.cargo.duplicate(true)
	await gesture("tap", point(preview.before_button))
	check(is_equal_approx(preview.lamp.effective_range_multiplier, RunState.light_range_for_level(1)), "Before preview uses current physical range")
	await gesture("capture", Vector2.ZERO, Vector2.ZERO, "light-before-upgrade")
	await gesture("tap", point(preview.after_button))
	check(is_equal_approx(preview.lamp.effective_range_multiplier, RunState.light_range_for_level(2)), "After preview uses upgraded physical range")
	check(is_equal_approx(preview.lamp.effective_energy_multiplier, RunState.light_energy_for_level(2)), "After preview uses upgraded brightness")
	check(RunState.cargo == cargo and int(RunState.workshop_status("light_lab").level) == 1, "Preview never spends or upgrades")
	await gesture("capture", Vector2.ZERO, Vector2.ZERO, "light-after-upgrade")
	var recipe: Dictionary = RunState.workshop_status("light_lab").next_upgrade
	RunState.cargo[recipe.resource] = int(recipe.cost) + 9
	panel.refresh_commerce(driver.CommerceCatalogScript.workshop_config("light_lab",RunState.workshop_status("light_lab"),{"current":"standard"}))
	panel._select_item("workshop:upgrade")
	await settle()
	await gesture("tap", point(panel.primary_button))
	check(int(RunState.workshop_status("light_lab").level) == 2 and RunState.cargo[recipe.resource] == 9, "Upgrade consumes exact existing price once")
	check(panel.selected_item_id() == "workshop:equip:standard", "Upgrade returns to current beam, avoiding accidental next purchase")
	panel.close_commerce()
	driver._prepare_light_state({"level":5,"style":"standard"})
	await settle()
	cargo = RunState.cargo.duplicate(true)
	for style in RunState.ENDLESS_LIGHT_STYLE_IDS:
		var current: String = RunState.endless_light_style
		panel._select_item("workshop:equip:"+style)
		await settle()
		preview = panel.hero_well.get_node("LightPreview")
		check(preview.lamp.applied_style_id == style, "Real beam preview: "+style)
		check(RunState.endless_light_style == current and RunState.cargo == cargo, "Preview leaves loadout and cargo unchanged: "+style)
		if not panel.primary_button.disabled: await gesture("tap",point(panel.primary_button))
		check(RunState.endless_light_style == style and RunState.cargo == cargo, "Explicit Use beam equips for free: "+style)
		await gesture("capture",Vector2.ZERO,Vector2.ZERO,"light-equipped-"+style)
	panel.close_commerce()
	await settle()
	check(panel.find_children("*", "SubViewport", true, false).is_empty(), "Closing light workshop releases all offscreen preview viewports")
	var saved: Dictionary = RunState.serialize()
	check(RunState.deserialize(saved) and RunState.endless_light_style == "deepheart", "Light choice persists after reload")
