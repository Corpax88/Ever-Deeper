extends SceneTree





const CommercePanelScript: Script = preload("res://scripts/ui/commerce_panel.gd")
const StationTransactionFxScript: = preload("res://scripts/world/station_transaction_fx.gd")
const MOSSVEIN_ACTION_PATH: = "res://assets/ui/commerce/mossvein-action-v1.png"
const MOSSVEIN_PLATE_PATH: = "res://assets/ui/commerce/mossvein-plate-v1.png"

const MOBILE_CSS_VIEWPORTS: = [
	Vector2(844.0, 390.0),
	Vector2(852.0, 393.0),
	Vector2(874.0, 402.0),
	Vector2(912.0, 420.0),
	Vector2(932.0, 430.0),
	Vector2(956.0, 440.0),
]
const MOBILE_LOGICAL_HEIGHT: = 720.0
const MIN_CSS_TOUCH_TARGET: = 44.0
const MIN_CSS_FONT_SIZE: = 10.0
const MIN_FORGE_HERO_ICON_RATIO: = 0.74
const MAX_FORGE_HERO_ICON_RATIO: = 0.88
const MIN_FORGE_FOOTER_INSET: = 28.0
const STEP_SECONDS: = 1.0 / 60.0
const MAX_FX_STEPS: = 600

var _checks: = 0
var _failures: Array[String] = []

var _fx_tick_sum: = 0
var _fx_last_cumulative: = 0
var _fx_tick_sequence_exact: = true
var _fx_phases: Array[String] = []
var _fx_started_count: = 0
var _fx_completed_count: = 0
var _fx_completed_skipped: = false

var _panel_actions: Array[String] = []


func _initialize() -> void :
	call_deferred("_run")


func _run() -> void :
	await process_frame
	_check(
		CommercePanelScript.can_instantiate(),
		"Commerce panel script parses and can be instantiated"
	)
	if not CommercePanelScript.can_instantiate():
		printerr(
			"EVER_DEEPER_COMMERCE_COMPONENTS_QA_FAILED checks=%d failures=%d\n- %s"
			%[_checks, _failures.size(), "\n- ".join(_failures)]
		)
		quit(4)
		return
	_test_state_transactions()
	await _test_station_transaction_fx()
	await _test_commerce_panel_mobile_layout()
	if _failures.is_empty():
		print(
			(
				"EVER_DEEPER_COMMERCE_COMPONENTS_QA_OK checks=%d "
				+ "assay=29 protected=5 forge=30+650 resource_cost=100 "
				+ "fx_ticks=987,-650 visual_cap=4 nodes=0 mobile=844x390-956x440 "
				+ "touch_css>=44 font_css>=10 scroll=two_axis themes=8 "
				+ "forge_button_states=10 hero_ratio=0.74-0.88 footer_inset>=28"
			)
			%_checks
		)
		quit(0)
		return
	printerr(
		"EVER_DEEPER_COMMERCE_COMPONENTS_QA_FAILED checks=%d failures=%d\n- %s"
		%[_checks, _failures.size(), "\n- ".join(_failures)]
	)
	quit(4)


func _test_state_transactions() -> void :
	var run_state: Variant = root.get_node_or_null("RunState")
	_check(run_state != null, "RunState autoload is available")
	if run_state == null:
		return



	run_state.reset_run(false)
	run_state.gold = 17
	run_state.cargo["stone"] = 4
	run_state.cargo["copper"] = 3
	run_state.cargo["deep_alloy"] = 5
	var sale_snapshot: Dictionary = run_state.assay_sale_snapshot()
	var protected_row: Dictionary = _row_for_kind(Array(sale_snapshot.get("rows", [])), "deep_alloy")
	_check(int(sale_snapshot.get("total", -1)) == 29, "Assay totals exact unit values", sale_snapshot)
	_check(int(sale_snapshot.get("sellable_pieces", -1)) == 7, "Assay counts sellable pieces exactly", sale_snapshot)
	_check(
		int(protected_row.get("sellable", -1)) == 0 and int(protected_row.get("protected", -1)) == 5,
		"Assay protects endless progression resources",
		protected_row
	)
	_check(run_state.gold == 17 and int(run_state.cargo.stone) == 4, "Assay snapshot does not mutate state")

	var sale_begin: Dictionary = run_state.begin_assay_sale()
	var sale_reused: Dictionary = run_state.begin_assay_sale()
	_check(bool(sale_begin.get("ok", false)), "Assay transaction begins")
	_check(
		String(sale_begin.get("transaction_id", "")) == String(sale_reused.get("transaction_id", ""))
		and bool(sale_reused.get("reused", false)),
		"Assay duplicate begin reuses the pending transaction",
		[sale_begin, sale_reused]
	)
	sale_begin["total"] = 999999
	var poisoned_rows: Array = Array(sale_begin.get("rows", [])).duplicate(true)
	if not poisoned_rows.is_empty():
		var poisoned_row: Dictionary = Dictionary(poisoned_rows[0])
		poisoned_row["sellable"] = 999999
		poisoned_rows[0] = poisoned_row
		sale_begin["rows"] = poisoned_rows
	var sale_after_external_edit: Dictionary = run_state.begin_assay_sale()
	_check(
		int(sale_after_external_edit.get("total", -1)) == 29,
		"Assay pending snapshot is immutable to callers",
		sale_after_external_edit
	)

	var sale_id: = String(sale_reused.get("transaction_id", ""))
	var sale_commit: Dictionary = run_state.commit_assay_sale(sale_id)
	_check(bool(sale_commit.get("ok", false)) and int(sale_commit.get("earned", -1)) == 29, "Assay commit returns exact earnings", sale_commit)
	_check(
		run_state.gold == 46
		and int(run_state.cargo.stone) == 0
		and int(run_state.cargo.copper) == 0
		and int(run_state.cargo.deep_alloy) == 5
		and run_state.total_gold_earned == 29,
		"Assay commit applies exact atomic accounting"
	)
	var sale_recommit: Dictionary = run_state.commit_assay_sale(sale_id)
	_check(
		bool(sale_recommit.get("ok", false))
		and bool(sale_recommit.get("already_committed", false))
		and run_state.gold == 46
		and run_state.total_gold_earned == 29,
		"Assay commit is idempotent",
		sale_recommit
	)


	run_state.reset_run(false)
	run_state.gold = 47
	var forge_snapshot: Dictionary = run_state.forge_purchase_snapshot("pickaxe")
	_check(
		bool(forge_snapshot.get("ready", false))
		and int(forge_snapshot.get("target_level", -1)) == 2
		and int(forge_snapshot.get("gold_required", -1)) == 30,
		"Forge snapshot exposes the exact Worn-to-Iron purchase",
		forge_snapshot
	)
	var forge_begin: Dictionary = run_state.begin_forge_purchase("pickaxe")
	var forge_reused: Dictionary = run_state.begin_forge_purchase("pickaxe")
	_check(
		String(forge_begin.get("transaction_id", "")) == String(forge_reused.get("transaction_id", ""))
		and bool(forge_reused.get("reused", false)),
		"Forge duplicate begin reuses the pending transaction",
		[forge_begin, forge_reused]
	)
	forge_begin["gold_required"] = 1
	var forge_after_external_edit: Dictionary = run_state.begin_forge_purchase("pickaxe")
	_check(
		int(forge_after_external_edit.get("gold_required", -1)) == 30,
		"Forge pending snapshot is immutable to callers",
		forge_after_external_edit
	)
	var forge_id: = String(forge_reused.get("transaction_id", ""))
	var forge_commit: Dictionary = run_state.commit_forge_purchase(forge_id)
	_check(
		bool(forge_commit.get("ok", false))
		and int(forge_commit.get("gold_spent", -1)) == 30
		and run_state.gold == 17
		and run_state.pickaxe_level == 2,
		"Forge commit applies exact gold and level accounting",
		forge_commit
	)
	var forge_recommit: Dictionary = run_state.commit_forge_purchase(forge_id)
	_check(
		bool(forge_recommit.get("already_committed", false))
		and run_state.gold == 17
		and run_state.pickaxe_level == 2,
		"Forge gold purchase commit is idempotent",
		forge_recommit
	)


	run_state.reset_run(false)
	run_state.pickaxe_level = 4
	run_state.emberdeep_unlocked = true
	run_state.gold = 700
	run_state.cargo["emberstone"] = 120
	var final_begin: Dictionary = run_state.begin_forge_purchase("pickaxe")
	var final_cost_rows: Array = Array(Dictionary(final_begin.get("cost", {})).get("resources", []))
	var emberstone_cost: Dictionary = _row_for_kind(final_cost_rows, "emberstone")
	_check(
		bool(final_begin.get("ok", false))
		and int(final_begin.get("gold_required", -1)) == 650
		and int(emberstone_cost.get("required", -1)) == 100,
		"Forge mixed-cost snapshot is exact",
		final_begin
	)
	var final_id: = String(final_begin.get("transaction_id", ""))
	var final_commit: Dictionary = run_state.commit_forge_purchase(final_id)
	_check(
		bool(final_commit.get("ok", false))
		and run_state.gold == 50
		and int(run_state.cargo.emberstone) == 20
		and run_state.pickaxe_level == 5,
		"Forge mixed-cost commit is atomic and exact",
		final_commit
	)
	var final_recommit: Dictionary = run_state.commit_forge_purchase(final_id)
	_check(
		bool(final_recommit.get("already_committed", false))
		and run_state.gold == 50
		and int(run_state.cargo.emberstone) == 20,
		"Forge mixed-cost commit is idempotent",
		final_recommit
	)


func _test_station_transaction_fx() -> void :
	var fx = StationTransactionFxScript.new()
	fx.name = "CommerceComponentsQaFx"
	root.add_child(fx)
	fx.transaction_started.connect(_on_fx_transaction_started)
	fx.phase_changed.connect(_on_fx_phase_changed)
	fx.gold_tick.connect(_on_fx_gold_tick)
	fx.transaction_completed.connect(_on_fx_transaction_completed)
	await process_frame

	_reset_fx_observation()
	var sale_id: int = fx.play_sale(
		[
			{"kind": "stone", "amount": 900},
			{"kind": "copper", "amount": 450},
		],
		987,
		Vector2(20, 30),
		Vector2(260, 110),
		Vector2(500, 32),
		null,
		{
			"transaction_key": "qa:sale:exact",
			"positions_are_local": true,
			"visual_cap": 4,
			"resource_duration": 0.1,
			"gold_duration": 0.1,
			"resource_spawn_window": 0.05,
			"gold_spawn_window": 0.05,
		}
	)
	fx.set_process(false)
	var sale_peak: = _drive_fx(fx)
	var sale_debug: Dictionary = fx.debug_snapshot()
	_check( not fx.busy, "Sale FX completes deterministically", sale_debug)
	_check(
		_fx_tick_sum == 987
		and _fx_last_cumulative == 987
		and _fx_tick_sequence_exact
		and fx.emitted_gold_tick_sum == 987,
		"Sale FX gold ticks sum exactly to the transaction total",
		{"signal_sum": _fx_tick_sum, "debug": sale_debug}
	)
	_check(
		"|".join(_fx_phases) == "resources_to_station|gold_to_wallet",
		"Sale FX preserves resource-then-gold phase order",
		_fx_phases
	)
	_check(
		sale_peak <= 4
		and int(sale_debug.get("peak_active_visuals", 99)) <= 4
		and int(sale_debug.get("visual_cap", 99)) == 4,
		"Sale FX respects its visual cap",
		{"observed_peak": sale_peak, "debug": sale_debug}
	)
	_check(
		fx.get_child_count() == 0
		and not bool(sale_debug.get("per_visual_nodes", true))
		and int(sale_debug.get("physics_nodes", -1)) == 0,
		"Sale FX uses pooled data without per-particle or physics nodes",
		sale_debug
	)
	_check(
		_fx_started_count == 1 and _fx_completed_count == 1 and not _fx_completed_skipped,
		"Sale FX emits one normal lifecycle",
		{"started": _fx_started_count, "completed": _fx_completed_count, "skipped": _fx_completed_skipped}
	)
	var duplicate_sale_id: int = fx.play_sale(
		[{"kind": "stone", "amount": 1}],
		1,
		Vector2.ZERO,
		Vector2.ONE,
		Vector2.ONE * 2.0,
		null,
		{"transaction_key": "qa:sale:exact", "positions_are_local": true}
	)
	_check(
		duplicate_sale_id == sale_id and not fx.busy and _fx_started_count == 1,
		"Sale FX transaction keys suppress duplicate playback"
	)

	_reset_fx_observation()
	fx.play_forge(
		[{"kind": "emberstone", "amount": 100}],
		650,
		Vector2(20, 30),
		Vector2(500, 32),
		Vector2(260, 110),
		null,
		{
			"transaction_key": "qa:forge:exact",
			"positions_are_local": true,
			"visual_cap": 4,
			"resource_duration": 0.1,
			"gold_duration": 0.1,
			"reward_duration": 0.1,
			"resource_spawn_window": 0.05,
			"gold_spawn_window": 0.05,
		}
	)
	fx.set_process(false)
	var forge_peak: = _drive_fx(fx)
	var forge_debug: Dictionary = fx.debug_snapshot()
	_check(
		_fx_tick_sum == -650
		and _fx_last_cumulative == -650
		and _fx_tick_sequence_exact
		and fx.emitted_gold_tick_sum == -650,
		"Forge FX gold ticks sum exactly to the negative cost",
		{"signal_sum": _fx_tick_sum, "debug": forge_debug}
	)
	_check(
		"|".join(_fx_phases) == "inputs_to_forge|upgrade_reward",
		"Forge FX preserves inputs-then-reward phase order",
		_fx_phases
	)
	_check(
		forge_peak <= 4
		and int(forge_debug.get("peak_active_visuals", 99)) <= 4
		and _fx_completed_count == 1
		and not _fx_completed_skipped,
		"Forge FX completes under the visual cap",
		{"observed_peak": forge_peak, "debug": forge_debug}
	)
	fx.queue_free()
	await process_frame


func _test_commerce_panel_mobile_layout() -> void :
	var first_css: Vector2 = MOBILE_CSS_VIEWPORTS[0]
	var first_logical: = _logical_viewport_for_css(first_css)
	root.size = Vector2i(roundi(first_logical.x), roundi(first_logical.y))
	var panel = CommercePanelScript.new()
	panel.name = "CommerceComponentsQaPanel"
	root.add_child(panel)
	panel.action_confirmed.connect(_on_panel_action_confirmed)
	await process_frame
	panel.open_commerce(_mobile_panel_config())
	var snapshot: Dictionary = {}
	for css_size_value in MOBILE_CSS_VIEWPORTS:
		var css_size: Vector2 = css_size_value
		var logical_size: = _logical_viewport_for_css(css_size)
		var scale_to_css: = css_size.y / MOBILE_LOGICAL_HEIGHT
		root.size = Vector2i(roundi(logical_size.x), roundi(logical_size.y))
		panel.apply_landscape_layout_for_test(logical_size)
		await process_frame
		await process_frame
		panel.apply_landscape_layout_for_test(logical_size)
		await process_frame
		snapshot = panel.interaction_snapshot()
		var metrics: Dictionary = panel.layout_metrics(logical_size)
		var panel_rect: Rect2 = Rect2(metrics.get("panel_rect", Rect2()))
		var safe_rect: Rect2 = Rect2(metrics.get("safe_rect", Rect2()))
		_check(
			bool(metrics.get("iphone_landscape", false))
			and bool(metrics.get("fits_width", false))
			and bool(metrics.get("fits_height", false))
			and _rect_inside(panel_rect, safe_rect),
			"Commerce panel fits the %dx%d CSS safe area" % [roundi(css_size.x), roundi(css_size.y)],
			metrics
		)
		_check(
			bool(snapshot.get("touch_targets_valid", false))
			and float(snapshot.get("touch_target_rendered_minimum", 0.0)) * scale_to_css >= MIN_CSS_TOUCH_TARGET,
			"Commerce controls stay at least 44 CSS px at %dx%d" % [roundi(css_size.x), roundi(css_size.y)],
			{"css": css_size, "scale": scale_to_css, "snapshot": snapshot}
		)
		_check(
			float(snapshot.get("minimum_font_size", 0)) * scale_to_css >= MIN_CSS_FONT_SIZE,
			"Commerce copy stays readable at %dx%d" % [roundi(css_size.x), roundi(css_size.y)],
			{"css": css_size, "scale": scale_to_css, "snapshot": snapshot}
		)
	_check(
		bool(snapshot.get("catalog_horizontal_scroll", false))
		and bool(snapshot.get("overview_vertical_scroll", false)),
		"Commerce panel exposes touch scrolling on both content axes",
		snapshot
	)
	var brushed_metal: Control = panel.get_node_or_null("CommerceFrame/BrushedMetal") as Control
	var forged_chrome: Control = panel.get_node_or_null("CommerceFrame/ForgedChrome") as Control
	var hero_well: Control = panel.get_node_or_null("CommerceFrame/InnerFrame/SafeMargin/Body/CommerceBody/Catalog/HeroWell") as Control
	var hero_medallion: Control = panel.get_node_or_null("CommerceFrame/InnerFrame/SafeMargin/Body/CommerceBody/Catalog/HeroWell/HeroCenter/HeroMedallion") as Control
	_check(
		brushed_metal != null
		and forged_chrome != null
		and hero_well != null
		and hero_medallion != null,
		"Commerce panel instantiates its forged chrome and hero showcase"
	)
	var horizontal_bar: ScrollBar = panel.catalog_scroll.get_h_scroll_bar()
	var vertical_bar: ScrollBar = panel.overview_scroll.get_v_scroll_bar()
	_check(
		horizontal_bar.max_value > horizontal_bar.page,
		"Commerce catalog actually overflows into horizontal swipe space",
		{"max": horizontal_bar.max_value, "page": horizontal_bar.page}
	)
	_check(
		vertical_bar.max_value > vertical_bar.page,
		"Commerce overview actually overflows into vertical swipe space",
		{"max": vertical_bar.max_value, "page": vertical_bar.page}
	)
	_check(
		panel.select_item("locked")
		and bool(panel.interaction_snapshot().get("selected_locked", false))
		and not bool(panel.interaction_snapshot().get("action_enabled", true)),
		"Locked shop items stay inspectable but cannot be confirmed"
	)
	_check(
		panel.select_item("missing")
		and not bool(panel.interaction_snapshot().get("selected_affordable", true))
		and not bool(panel.interaction_snapshot().get("action_enabled", true)),
		"Unaffordable shop items explain costs without enabling purchase"
	)
	_check(panel.select_item("ready"), "Ready shop item can be reselected")
	var post_selection_css: Vector2 = MOBILE_CSS_VIEWPORTS.back()
	var post_selection_scale: = post_selection_css.y / MOBILE_LOGICAL_HEIGHT
	var post_selection_snapshot: Dictionary = panel.interaction_snapshot()
	_check(
		bool(post_selection_snapshot.get("touch_targets_valid", false))
		and float(post_selection_snapshot.get("minimum_font_size", 0)) * post_selection_scale >= MIN_CSS_FONT_SIZE,
		"Commerce cards preserve mobile touch and type scaling after selection",
		post_selection_snapshot
	)
	var ready_icon_plate: Control = panel.get_node_or_null("CommerceFrame/InnerFrame/SafeMargin/Body/CommerceBody/Catalog/CatalogScroll/ItemCards/Item_ready/Inset/CardRow/IconPlate") as Control
	_check(
		ready_icon_plate != null and ready_icon_plate.custom_minimum_size.x >= 76.0,
		"Commerce selector artwork preserves its mobile touch size after selection"
	)
	panel.primary_button.emit_signal("pressed")
	_check(
		_panel_actions == ["ready"],
		"Commerce panel emits exactly one selected action without mutating economy",
		_panel_actions
	)
	var theme_cases: = {
		"forge": "forge",
		"wayfarer": "wayfarer",
		"starforge": "starforge",
		"workshop:tool_forge": "tool_forge",
		"workshop:light_lab": "light_lab",
		"workshop:wardrobe": "wardrobe",
		"workshop:treasure_chamber": "treasure_chamber",
		"workshop:lift_workshop": "lift_workshop",
	}
	for panel_id_value in theme_cases:
		var themed_config: = _mobile_panel_config()
		themed_config["panel_id"] = panel_id_value
		panel.refresh_commerce(themed_config)
		_check(
			String(panel.interaction_snapshot().get("visual_theme", "")) == String(theme_cases[panel_id_value]),
			"Commerce panel resolves the %s visual identity" % String(theme_cases[panel_id_value])
		)
	await _test_forge_premium_layout_contract(panel)
	panel.close_commerce()
	panel.queue_free()
	await process_frame


func _test_forge_premium_layout_contract(panel: Control) -> void :
	var css_size: = Vector2(932.0, 430.0)
	var logical_size: = _logical_viewport_for_css(css_size)
	root.size = Vector2i(roundi(logical_size.x), roundi(logical_size.y))
	panel.refresh_commerce(_single_item_forge_config())
	panel.apply_landscape_layout_for_test(logical_size)
	await process_frame
	await process_frame
	panel.apply_landscape_layout_for_test(logical_size)
	await process_frame

	var primary_button: Button = panel.get("primary_button") as Button
	var cancel_button: Button = panel.get("cancel_button") as Button
	_check(
		primary_button != null and cancel_button != null,
		"Forge footer instantiates both premium actions"
	)
	if primary_button != null and cancel_button != null:
		for state in ["normal", "hover", "pressed", "focus", "disabled"]:
			var primary_texture_path: = (
				MOSSVEIN_PLATE_PATH if state == "disabled" else MOSSVEIN_ACTION_PATH
			)
			_check_forge_button_texture(
				primary_button,
				state,
				primary_texture_path,
				"primary"
			)
			_check_forge_button_texture(
				cancel_button,
				state,
				MOSSVEIN_PLATE_PATH,
				"cancel"
			)

	var hero_medallion: Control = panel.get("hero_medallion") as Control
	var hero_icon: TextureRect = panel.get("hero_icon") as TextureRect
	var hero_ratio: = 0.0
	var hero_icon_inside: = false
	if hero_medallion != null and hero_icon != null:
		var medallion_extent: = minf(hero_medallion.size.x, hero_medallion.size.y)
		var icon_extent: = minf(hero_icon.size.x, hero_icon.size.y)
		hero_ratio = icon_extent / maxf(1.0, medallion_extent)
		hero_icon_inside = _rect_inside(
			Rect2(hero_icon.position, hero_icon.size),
			Rect2(Vector2.ZERO, hero_medallion.size)
		)
	_check(
		hero_medallion != null
		and hero_icon != null
		and hero_icon_inside
		and hero_ratio >= MIN_FORGE_HERO_ICON_RATIO
		and hero_ratio <= MAX_FORGE_HERO_ICON_RATIO
		and hero_icon.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED,
		"Forge tool dominates its medallion without clipping",
		{
			"ratio": hero_ratio,
			"minimum": MIN_FORGE_HERO_ICON_RATIO,
			"maximum": MAX_FORGE_HERO_ICON_RATIO,
			"inside": hero_icon_inside,
			"medallion_size": hero_medallion.size if hero_medallion != null else Vector2.ZERO,
			"icon_size": hero_icon.size if hero_icon != null else Vector2.ZERO,
		}
	)

	var frame: Control = panel.get("frame") as Control
	var safe_margin: MarginContainer = panel.get("safe_margin") as MarginContainer
	var footer: Control = panel.get("footer") as Control
	var chrome_overlay: Control = panel.get("chrome_overlay") as Control
	var footer_inset: = -1.0
	if frame != null and footer != null:
		footer_inset = frame.get_global_rect().end.y - footer.get_global_rect().end.y
	_check(
		frame != null
		and safe_margin != null
		and footer != null
		and chrome_overlay != null
		and safe_margin.get_theme_constant("margin_bottom") >= roundi(MIN_FORGE_FOOTER_INSET)
		and footer_inset >= MIN_FORGE_FOOTER_INSET
		and footer.z_index > chrome_overlay.z_index,
		"Forge footer clears the ornamental frame and stays above its chrome",
		{
			"inset": footer_inset,
			"minimum": MIN_FORGE_FOOTER_INSET,
			"safe_margin": (
				safe_margin.get_theme_constant("margin_bottom") if safe_margin != null else -1
			),
			"footer_z": footer.z_index if footer != null else -1,
			"chrome_z": chrome_overlay.z_index if chrome_overlay != null else -1,
		}
	)


func _check_forge_button_texture(
	button: Button,
	state: String,
	expected_texture_path: String,
	button_role: String
) -> void :
	var style: StyleBox = button.get_theme_stylebox(state)
	if not style is StyleBoxTexture:
		_check(
			false,
			"Forge %s button uses premium metal in %s state" % [button_role, state],
			{"style_class": style.get_class() if style != null else "null"}
		)
		return
	var texture_style: StyleBoxTexture = style as StyleBoxTexture
	var texture_path: = (
		String(texture_style.texture.resource_path) if texture_style.texture != null else ""
	)
	var margins: = Vector4(
		texture_style.texture_margin_left,
		texture_style.texture_margin_top,
		texture_style.texture_margin_right,
		texture_style.texture_margin_bottom
	)
	var texture_size: = (
		texture_style.texture.get_size() if texture_style.texture != null else Vector2.ZERO
	)
	var region_size: = texture_style.region_rect.size
	var normalized_slices: = Vector4(
		margins.x / maxf(1.0, texture_size.x),
		margins.y / maxf(1.0, texture_size.y),
		margins.z / maxf(1.0, texture_size.x),
		margins.w / maxf(1.0, texture_size.y)
	)
	var symmetric_slices: = (
		absf(normalized_slices.x - normalized_slices.z) <= 0.015
		and absf(normalized_slices.y - normalized_slices.w) <= 0.015
	)
	var valid_slices: = (
		normalized_slices.x >= 0.08
		and normalized_slices.x <= 0.13
		and normalized_slices.z >= 0.08
		and normalized_slices.z <= 0.13
		and normalized_slices.y >= 0.10
		and normalized_slices.y <= 0.17
		and normalized_slices.w >= 0.10
		and normalized_slices.w <= 0.17
		and (region_size.x - margins.x - margins.z) / maxf(1.0, texture_size.x) >= 0.70
		and (region_size.y - margins.y - margins.w) / maxf(1.0, texture_size.y) >= 0.38
	)
	var readable_content_inset: = (
		texture_style.content_margin_left >= 8.0
		and texture_style.content_margin_top >= 8.0
		and texture_style.content_margin_right >= 8.0
		and texture_style.content_margin_bottom >= 8.0
	)
	_check(
		texture_path == expected_texture_path
		and texture_style.draw_center
		and symmetric_slices
		and valid_slices
		and readable_content_inset
		and texture_style.axis_stretch_horizontal
			== StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
		and texture_style.axis_stretch_vertical
			== StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT,
		"Forge %s button uses valid premium metal slices in %s state"
		%[button_role, state],
		{
			"texture": texture_path,
			"expected_texture": expected_texture_path,
			"texture_size": texture_size,
			"region_size": region_size,
			"slice_margins": margins,
			"normalized_slices": normalized_slices,
			"symmetric": symmetric_slices,
			"content_inset": Vector4(
				texture_style.content_margin_left,
				texture_style.content_margin_top,
				texture_style.content_margin_right,
				texture_style.content_margin_bottom
			),
		}
	)


func _logical_viewport_for_css(css_size: Vector2) -> Vector2:
	return Vector2(MOBILE_LOGICAL_HEIGHT * css_size.x / maxf(1.0, css_size.y), MOBILE_LOGICAL_HEIGHT)


func _drive_fx(fx: Node) -> int:
	var steps: = 0
	var observed_peak: = int(Dictionary(fx.debug_snapshot()).get("active_visuals", 0))
	while bool(fx.busy) and steps < MAX_FX_STEPS:
		fx._process(STEP_SECONDS)
		var snapshot: Dictionary = fx.debug_snapshot()
		observed_peak = maxi(observed_peak, int(snapshot.get("active_visuals", 0)))
		steps += 1
	_check(steps < MAX_FX_STEPS, "FX completes inside deterministic step budget", {"steps": steps})
	return observed_peak


func _reset_fx_observation() -> void :
	_fx_tick_sum = 0
	_fx_last_cumulative = 0
	_fx_tick_sequence_exact = true
	_fx_phases.clear()
	_fx_started_count = 0
	_fx_completed_count = 0
	_fx_completed_skipped = false


func _on_fx_transaction_started(_transaction_id: int, _flow: String, _gold_total: int) -> void :
	_fx_started_count += 1


func _on_fx_phase_changed(_transaction_id: int, phase: String) -> void :
	_fx_phases.append(phase)


func _on_fx_gold_tick(
	_transaction_id: int,
	delta: int,
	cumulative_delta: int,
	_total_delta: int
) -> void :
	_fx_tick_sum += delta
	_fx_tick_sequence_exact = _fx_tick_sequence_exact and cumulative_delta == _fx_tick_sum
	_fx_last_cumulative = cumulative_delta


func _on_fx_transaction_completed(_transaction_id: int, _flow: String, skipped: bool) -> void :
	_fx_completed_count += 1
	_fx_completed_skipped = skipped


func _on_panel_action_confirmed(item_id: String) -> void :
	_panel_actions.append(item_id)


func _row_for_kind(rows: Array, kind: String) -> Dictionary:
	for row_value in rows:
		if row_value is Dictionary and String(Dictionary(row_value).get("kind", "")) == kind:
			return Dictionary(row_value)
	return {}


func _rect_inside(inner: Rect2, outer: Rect2) -> bool:
	return (
		inner.position.x >= outer.position.x - 0.1
		and inner.position.y >= outer.position.y - 0.1
		and inner.end.x <= outer.end.x + 0.1
		and inner.end.y <= outer.end.y + 0.1
	)


func _single_item_forge_config() -> Dictionary:
	return {
		"panel_id": "forge",
		"title": "Mossvein Forge",
		"subtitle": "Inspect the change before the hammer falls",
		"selected_item_id": "forge:pickaxe",
		"items": [
			{
				"id": "forge:pickaxe",
				"title": "Runed Pickaxe",
				"subtitle": "Premium single-item layout fixture",
				"texture": "res://assets/tools/pickaxe-runed.png",
				"affordable": true,
				"action_enabled": true,
				"action_label": "Forge",
				"stats": [
					{"id": "power", "label": "Power", "current": 7, "next": 12},
				],
				"costs": [
					{
						"kind": "gold",
						"label": "Gold",
						"owned": 85,
						"required": 85,
						"missing": 0,
					},
				],
			},
		],
	}


func _mobile_panel_config() -> Dictionary:
	var dense_stats: Array = []
	for index in range(12):
		dense_stats.append({
			"id": "stat_%d" % index,
			"label": "Stat %d" % (index + 1),
			"current": index + 1,
			"next": index + 2,
		})
	var dense_costs: Array = []
	for index in range(5):
		dense_costs.append({
			"kind": "material_%d" % index,
			"label": "Material %d" % (index + 1),
			"owned": 10,
			"required": 10,
			"missing": 0,
		})
	return {
		"panel_id": "qa_mobile_shop",
		"title": "Ever Deeper Commerce QA",
		"subtitle": "Swipe the catalog and scroll the full overview",
		"selected_item_id": "ready",
		"items": [
			{
				"id": "ready",
				"title": "Ready Upgrade",
				"subtitle": "Full mobile overflow fixture",
				"description": "A deliberately detailed item used to prove that every line remains reachable without a desktop scrollbar.",
				"affordable": true,
				"action_enabled": true,
				"action_label": "Buy",
				"stats": dense_stats,
				"costs": dense_costs,
			},
			{
				"id": "locked",
				"title": "Future Tool",
				"subtitle": "Inspect before unlocking",
				"locked": true,
				"affordable": true,
				"future_unlock": "Reach the next descent milestone.",
			},
			{
				"id": "missing",
				"title": "Material Upgrade",
				"subtitle": "Requirements are visible",
				"affordable": false,
				"costs": [
					{"kind": "ore", "label": "Ore", "owned": 2, "required": 12, "missing": 10},
				],
			},
			{
				"id": "owned",
				"title": "Owned Finish",
				"subtitle": "Current collection state",
				"current": true,
				"action_enabled": true,
			},
			{
				"id": "equipped",
				"title": "Equipped Finish",
				"subtitle": "Explicit loadout state",
				"equipped": true,
				"action_enabled": true,
			},
		],
	}


func _check(condition: bool, label: String, detail: Variant = null) -> void :
	_checks += 1
	if condition:
		return
	var message: = label
	if detail != null:
		message += " :: %s" % str(detail)
	_failures.append(message)
	push_error("COMMERCE_QA: %s" % message)
