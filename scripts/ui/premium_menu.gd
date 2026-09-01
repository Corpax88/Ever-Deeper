class_name PremiumMenu
extends Control

signal continue_requested
signal new_game_requested
signal new_game_confirmed

const LOGO: = preload("res://assets/branding/ever-deeper-logo.png")
const GOLD: = Color("d7b45a")
const GOLD_BRIGHT: = Color("ffe3a0")
const MINT: = Color("a8e3bc")
const MUTED: = Color("789384")
const INK: = Color("07120d")
const IPHONE_LANDSCAPE_ASPECT: = 1.95
const DEV_RELEASE_VERSION: = "0.43.1-dev.2"


static func release_version() -> String:
	if OS.has_feature("ever_deeper_dev"):
		return DEV_RELEASE_VERSION
	return String(ProjectSettings.get_setting("application/config/version", "0.0.0"))


static func release_label() -> String:
	var build_name: = "DEV BUILD  ·  " if OS.has_feature("ever_deeper_dev") else ""
	return "EVER DEEPER  ·  %sIPHONE LANDSCAPE %s" % [build_name, release_version()]

var main_view: Control
var detail_view: Control
var confirm_view: Control
var main_card: Panel
var detail_card: Panel
var confirm_card: Panel
var detail_title: Label
var detail_body: Control
var continue_button: Button
var achievements_button: Button
var save_hint: Label
var menu_kicker: Label
var music_slider: HSlider
var sfx_slider: HSlider
var achievement_count_label: Label
var achievement_scroll: ScrollContainer
var achievement_rows: Dictionary = {}
var achievement_highlight_id: = ""
var achievement_highlight_tween: Tween
var _pause_mode: = false
var audio_director: Node
var achievement_service: Node


func _ready() -> void :
	audio_director = get_node("/root/AudioDirector")
	achievement_service = get_node("/root/AchievementService")
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 100
	_build_backdrop()
	_build_main_view()
	_build_detail_view()
	_build_confirmation()
	get_viewport().size_changed.connect(_apply_responsive_layout)
	achievement_service.updated.connect(_refresh_achievement_count)
	call_deferred("_apply_responsive_layout")
	visible = false


func open_menu(has_save: bool, location: String, is_pause: bool, storage_uncertain: bool) -> void :
	_pause_mode = is_pause
	visible = true
	main_view.visible = true
	detail_view.visible = false
	confirm_view.visible = false
	menu_kicker.text = "EXPEDITION PAUSED" if is_pause else "THE DEPTHS ARE CALLING"
	continue_button.disabled = not has_save
	continue_button.text = (
		("RETURN TO MINE\n%s" % location)
		if is_pause
		else ("CONTINUE\n%s" % location) if has_save
		else "CONTINUE\nNO EXPEDITION FOUND"
	)
	save_hint.text = (
		"THIS BROWSER MAY NOT KEEP PROGRESS AFTER THE TAB CLOSES"
		if storage_uncertain
		else "YOUR EXPEDITION SAVES AUTOMATICALLY"
	)
	_refresh_achievement_count()
	continue_button.grab_focus()


func close_menu() -> void :
	if music_slider != null:
		audio_director.set_music_volume(float(music_slider.value) / 100.0)
	if sfx_slider != null:
		audio_director.set_sfx_volume(float(sfx_slider.value) / 100.0)
	visible = false


func show_new_game_confirmation() -> void :
	confirm_view.visible = true
	var cancel: = confirm_view.get_node("Card/Cancel") as Button
	cancel.grab_focus()


func is_confirming() -> bool:
	return visible and confirm_view.visible


func cancel_confirmation() -> void :
	confirm_view.visible = false
	audio_director.play_ui("cancel")


func _build_backdrop() -> void :
	var background: = ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color("06110c")
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var upper_glow: = ColorRect.new()
	upper_glow.anchor_right = 1.0
	upper_glow.offset_bottom = 270.0
	upper_glow.color = Color(0.05, 0.2, 0.11, 0.42)
	upper_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(upper_glow)
	var lower_glow: = ColorRect.new()
	lower_glow.anchor_top = 1.0
	lower_glow.anchor_right = 1.0
	lower_glow.anchor_bottom = 1.0
	lower_glow.offset_top = -180.0
	lower_glow.color = Color(0.09, 0.105, 0.035, 0.18)
	lower_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lower_glow)
	var top_line: = ColorRect.new()
	top_line.anchor_right = 1.0
	top_line.offset_left = 24.0
	top_line.offset_top = 17.0
	top_line.offset_right = -24.0
	top_line.offset_bottom = 19.0
	top_line.color = Color(GOLD, 0.72)
	top_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top_line)


func _build_main_view() -> void :
	main_view = Control.new()
	main_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(main_view)
	main_card = Panel.new()
	var card: = main_card
	card.name = "Card"
	card.anchor_left = 0.5
	card.anchor_top = 0.5
	card.anchor_right = 0.5
	card.anchor_bottom = 0.5
	card.offset_left = -520.0
	card.offset_top = -300.0
	card.offset_right = 520.0
	card.offset_bottom = 300.0
	card.add_theme_stylebox_override("panel", _panel_style(Color("0b1d14"), GOLD, 18, 2))
	main_view.add_child(card)

	var logo: = TextureRect.new()
	logo.name = "Logo"
	logo.position = Vector2(52, 66)
	logo.size = Vector2(410, 174)
	logo.texture = LOGO
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(logo)

	menu_kicker = _label("THE DEPTHS ARE CALLING", 9, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	menu_kicker.name = "Kicker"
	menu_kicker.position = Vector2(52, 242)
	menu_kicker.size = Vector2(410, 26)
	card.add_child(menu_kicker)
	var premise: = _label("MINE FORGOTTEN WORLDS\nBUILD YOUR DEEP BASE\nAWAKEN THE HEART BELOW", 12, MINT, HORIZONTAL_ALIGNMENT_CENTER)
	premise.name = "Premise"
	premise.position = Vector2(76, 298)
	premise.size = Vector2(362, 108)
	premise.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	premise.add_theme_constant_override("line_spacing", 8)
	card.add_child(premise)
	var divider: = ColorRect.new()
	divider.name = "Divider"
	divider.position = Vector2(506, 52)
	divider.size = Vector2(1, 496)
	divider.color = Color(GOLD, 0.28)
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(divider)

	continue_button = _menu_button("CONTINUE", true)
	continue_button.name = "Continue"
	continue_button.position = Vector2(552, 66)
	continue_button.size = Vector2(434, 78)
	continue_button.pressed.connect( func():
		audio_director.unlock_from_user_gesture()
		continue_requested.emit()
	)
	card.add_child(continue_button)

	var new_game: = _menu_button("NEW GAME\nBEGIN A FRESH DESCENT", false)
	new_game.name = "NewGame"
	new_game.position = Vector2(552, 158)
	new_game.size = Vector2(434, 68)
	new_game.pressed.connect( func():
		audio_director.unlock_from_user_gesture()
		new_game_requested.emit()
	)
	card.add_child(new_game)

	achievements_button = _menu_button("ACHIEVEMENTS\n0 / 50 UNLOCKED", false)
	achievements_button.name = "Achievements"
	achievements_button.position = Vector2(552, 240)
	achievements_button.size = Vector2(434, 68)
	achievements_button.pressed.connect( func():
		audio_director.play_ui("open")
		show_achievements()
	)
	card.add_child(achievements_button)

	var settings: = _menu_button("SETTINGS\nAUDIO & OPTIONS", false)
	settings.name = "Settings"
	settings.position = Vector2(552, 322)
	settings.size = Vector2(434, 68)
	settings.pressed.connect( func():
		audio_director.play_ui("open")
		_show_settings()
	)
	card.add_child(settings)

	save_hint = _label("YOUR EXPEDITION SAVES AUTOMATICALLY", 8, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	save_hint.name = "SaveHint"
	save_hint.position = Vector2(552, 421)
	save_hint.size = Vector2(434, 44)
	save_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.add_child(save_hint)

	var rule: = ColorRect.new()
	rule.name = "Rule"
	rule.position = Vector2(576, 496)
	rule.size = Vector2(386, 1)
	rule.color = Color(GOLD, 0.26)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(rule)
	var version: = _label(release_label(), 7, Color("53685b"), HORIZONTAL_ALIGNMENT_CENTER)
	version.name = "Version"
	version.position = Vector2(552, 512)
	version.size = Vector2(434, 30)
	card.add_child(version)


func displayed_release_label() -> String:
	if main_card == null or not main_card.has_node("Version"):
		return ""
	return String((main_card.get_node("Version") as Label).text)


func _build_detail_view() -> void :
	detail_view = Control.new()
	detail_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	detail_view.visible = false
	add_child(detail_view)
	detail_card = Panel.new()
	var card: = detail_card
	card.name = "Card"
	card.anchor_left = 0.5
	card.anchor_top = 0.5
	card.anchor_right = 0.5
	card.anchor_bottom = 0.5
	card.offset_left = -520.0
	card.offset_top = -300.0
	card.offset_right = 520.0
	card.offset_bottom = 300.0
	card.add_theme_stylebox_override("panel", _panel_style(Color("0b1d14"), GOLD, 18, 2))
	detail_view.add_child(card)
	detail_title = _label("SETTINGS", 21, GOLD_BRIGHT, HORIZONTAL_ALIGNMENT_CENTER)
	detail_title.position = Vector2(48, 22)
	detail_title.size = Vector2(944, 36)
	card.add_child(detail_title)
	var subtitle: = _label("EXPEDITION LEDGER", 8, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	subtitle.name = "Subtitle"
	subtitle.position = Vector2(48, 59)
	subtitle.size = Vector2(944, 20)
	card.add_child(subtitle)
	detail_body = Control.new()
	detail_body.name = "Body"
	detail_body.position = Vector2(80, 92)
	detail_body.size = Vector2(880, 410)
	card.add_child(detail_body)
	var back: = _menu_button("BACK", false)
	back.name = "Back"
	back.position = Vector2(410, 526)
	back.size = Vector2(220, 52)
	back.pressed.connect( func():
		audio_director.play_ui("cancel")
		_show_main_view()
	)
	card.add_child(back)


func _build_confirmation() -> void :
	confirm_view = Control.new()
	confirm_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	confirm_view.visible = false
	add_child(confirm_view)
	var shade: = ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0, 0, 0, 0.82)
	confirm_view.add_child(shade)
	confirm_card = Panel.new()
	var card: = confirm_card
	card.name = "Card"
	card.anchor_left = 0.5
	card.anchor_top = 0.5
	card.anchor_right = 0.5
	card.anchor_bottom = 0.5
	card.offset_left = -260.0
	card.offset_top = -155.0
	card.offset_right = 260.0
	card.offset_bottom = 155.0
	card.add_theme_stylebox_override("panel", _panel_style(Color("101d15"), GOLD, 17, 2))
	confirm_view.add_child(card)
	var kicker: = _label("A NEW DESCENT", 9, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	kicker.name = "Kicker"
	kicker.position = Vector2(28, 22)
	kicker.size = Vector2(464, 22)
	card.add_child(kicker)
	var title: = _label("REPLACE THIS EXPEDITION?", 18, GOLD_BRIGHT, HORIZONTAL_ALIGNMENT_CENTER)
	title.name = "Title"
	title.position = Vector2(28, 55)
	title.size = Vector2(464, 32)
	card.add_child(title)
	var copy: = _label("Your current run will be replaced.\nAchievements and audio settings stay with you.", 10, Color("b2c9b8"), HORIZONTAL_ALIGNMENT_CENTER)
	copy.name = "Copy"
	copy.position = Vector2(42, 105)
	copy.size = Vector2(436, 58)
	card.add_child(copy)
	var cancel: = _menu_button("KEEP SAVE", false)
	cancel.name = "Cancel"
	cancel.position = Vector2(28, 212)
	cancel.size = Vector2(220, 62)
	cancel.pressed.connect(cancel_confirmation)
	card.add_child(cancel)
	var confirm: = _menu_button("NEW GAME", true)
	confirm.name = "Confirm"
	confirm.position = Vector2(272, 212)
	confirm.size = Vector2(220, 62)
	confirm.pressed.connect( func():
		confirm_view.visible = false
		new_game_confirmed.emit()
	)
	card.add_child(confirm)


func _apply_responsive_layout(size_override: Vector2 = Vector2.ZERO) -> void :
	if main_card == null or detail_card == null or confirm_card == null:
		return
	var viewport_size: Vector2 = size_override if size_override != Vector2.ZERO else get_viewport().get_visible_rect().size
	if viewport_size.x <= 1.0 or viewport_size.y <= 1.0:
		return
	var iphone: = viewport_size.x / viewport_size.y >= IPHONE_LANDSCAPE_ASPECT
	if iphone:
		_layout_iphone_landscape(viewport_size)
	else:
		_layout_design_landscape(viewport_size)


func apply_iphone_layout_for_test(viewport_size: Vector2) -> Dictionary:
	_apply_responsive_layout(viewport_size)
	return layout_snapshot(viewport_size)


func layout_snapshot(viewport_size: Vector2) -> Dictionary:
	var iphone: = viewport_size.x / maxf(viewport_size.y, 1.0) >= IPHONE_LANDSCAPE_ASPECT
	var main_size: = Vector2(1160, 620) if iphone else Vector2(1040, 600)
	var detail_size: = Vector2(1120, 620) if iphone else Vector2(1040, 600)
	var confirm_size: = Vector2(660, 370) if iphone else Vector2(520, 310)
	return {
		"iphone": iphone,
		"safe_rect": Rect2(34, 24, viewport_size.x - 68, viewport_size.y - 48),
		"main": Rect2((viewport_size - main_size) * 0.5, main_size),
		"detail": Rect2((viewport_size - detail_size) * 0.5, detail_size),
		"confirm": Rect2((viewport_size - confirm_size) * 0.5, confirm_size),
		"version_label": displayed_release_label(),
		"version_font_size": (main_card.get_node("Version") as Label).get_theme_font_size("font_size"),
		"continue": Rect2(main_card.get_node("Continue").position, main_card.get_node("Continue").size),
		"new_game": Rect2(main_card.get_node("NewGame").position, main_card.get_node("NewGame").size),
		"achievements": Rect2(main_card.get_node("Achievements").position, main_card.get_node("Achievements").size),
		"settings": Rect2(main_card.get_node("Settings").position, main_card.get_node("Settings").size),
		"back": Rect2(detail_card.get_node("Back").position, detail_card.get_node("Back").size),
		"confirm_cancel": Rect2(confirm_card.get_node("Cancel").position, confirm_card.get_node("Cancel").size),
		"confirm_accept": Rect2(confirm_card.get_node("Confirm").position, confirm_card.get_node("Confirm").size),
	}


func minimum_touch_targets_are_valid(minimum_height: float = 44.0) -> bool:
	for button in [
		continue_button,
		main_card.get_node("NewGame"),
		achievements_button,
		main_card.get_node("Settings"),
		detail_card.get_node("Back"),
		confirm_card.get_node("Cancel"),
		confirm_card.get_node("Confirm"),
	]:
		if (button as Button).size.y < minimum_height:
			return false
	return true


func _layout_iphone_landscape(viewport_size: Vector2) -> void :
	_center_card(main_card, viewport_size, Vector2(1160, 620))
	_place(main_card.get_node("Logo"), Rect2(54, 60, 438, 184))
	_place(menu_kicker, Rect2(54, 246, 438, 34))
	_place(main_card.get_node("Premise"), Rect2(76, 302, 394, 132))
	_place(main_card.get_node("Divider"), Rect2(532, 44, 2, 532))
	_place(continue_button, Rect2(580, 50, 526, 92))
	_place(main_card.get_node("NewGame"), Rect2(580, 156, 526, 82))
	_place(achievements_button, Rect2(580, 252, 526, 82))
	_place(main_card.get_node("Settings"), Rect2(580, 348, 526, 82))
	_place(save_hint, Rect2(580, 451, 526, 46))
	_place(main_card.get_node("Rule"), Rect2(610, 518, 466, 2))
	_place(main_card.get_node("Version"), Rect2(580, 530, 526, 38))
	continue_button.add_theme_font_size_override("font_size", 26)
	for button in [main_card.get_node("NewGame"), achievements_button, main_card.get_node("Settings")]:
		(button as Button).add_theme_font_size_override("font_size", 21)
	menu_kicker.add_theme_font_size_override("font_size", 17)
	(main_card.get_node("Premise") as Label).add_theme_font_size_override("font_size", 20)
	save_hint.add_theme_font_size_override("font_size", 15)
	(main_card.get_node("Version") as Label).add_theme_font_size_override("font_size", 17)

	_center_card(detail_card, viewport_size, Vector2(1120, 620))
	_place(detail_title, Rect2(48, 18, 1024, 48))
	_place(detail_card.get_node("Subtitle"), Rect2(48, 64, 1024, 28))
	_place(detail_body, Rect2(120, 98, 880, 412))
	_place(detail_card.get_node("Back"), Rect2(420, 522, 280, 82))
	detail_title.add_theme_font_size_override("font_size", 27)
	(detail_card.get_node("Subtitle") as Label).add_theme_font_size_override("font_size", 15)
	(detail_card.get_node("Back") as Button).add_theme_font_size_override("font_size", 20)

	_center_card(confirm_card, viewport_size, Vector2(660, 370))
	_place(confirm_card.get_node("Kicker"), Rect2(34, 24, 592, 30))
	_place(confirm_card.get_node("Title"), Rect2(34, 62, 592, 44))
	_place(confirm_card.get_node("Copy"), Rect2(52, 120, 556, 74))
	_place(confirm_card.get_node("Cancel"), Rect2(34, 250, 282, 86))
	_place(confirm_card.get_node("Confirm"), Rect2(344, 250, 282, 86))
	(confirm_card.get_node("Kicker") as Label).add_theme_font_size_override("font_size", 16)
	(confirm_card.get_node("Title") as Label).add_theme_font_size_override("font_size", 25)
	(confirm_card.get_node("Copy") as Label).add_theme_font_size_override("font_size", 17)
	(confirm_card.get_node("Cancel") as Button).add_theme_font_size_override("font_size", 20)
	(confirm_card.get_node("Confirm") as Button).add_theme_font_size_override("font_size", 21)


func _layout_design_landscape(viewport_size: Vector2) -> void :
	_center_card(main_card, viewport_size, Vector2(1040, 600))
	_place(main_card.get_node("Logo"), Rect2(52, 66, 410, 174))
	_place(menu_kicker, Rect2(52, 242, 410, 26))
	_place(main_card.get_node("Premise"), Rect2(76, 298, 362, 108))
	_place(main_card.get_node("Divider"), Rect2(506, 52, 1, 496))
	_place(continue_button, Rect2(552, 66, 434, 78))
	_place(main_card.get_node("NewGame"), Rect2(552, 158, 434, 68))
	_place(achievements_button, Rect2(552, 240, 434, 68))
	_place(main_card.get_node("Settings"), Rect2(552, 322, 434, 68))
	_place(save_hint, Rect2(552, 421, 434, 44))
	_place(main_card.get_node("Rule"), Rect2(576, 496, 386, 1))
	_place(main_card.get_node("Version"), Rect2(552, 512, 434, 30))
	continue_button.add_theme_font_size_override("font_size", 14)
	for button in [main_card.get_node("NewGame"), achievements_button, main_card.get_node("Settings")]:
		(button as Button).add_theme_font_size_override("font_size", 12)
	menu_kicker.add_theme_font_size_override("font_size", 9)
	(main_card.get_node("Premise") as Label).add_theme_font_size_override("font_size", 12)
	save_hint.add_theme_font_size_override("font_size", 8)
	(main_card.get_node("Version") as Label).add_theme_font_size_override("font_size", 9)

	_center_card(detail_card, viewport_size, Vector2(1040, 600))
	_place(detail_title, Rect2(48, 22, 944, 36))
	_place(detail_card.get_node("Subtitle"), Rect2(48, 59, 944, 20))
	_place(detail_body, Rect2(80, 92, 880, 410))
	_place(detail_card.get_node("Back"), Rect2(410, 526, 220, 52))
	detail_title.add_theme_font_size_override("font_size", 21)
	(detail_card.get_node("Subtitle") as Label).add_theme_font_size_override("font_size", 8)
	(detail_card.get_node("Back") as Button).add_theme_font_size_override("font_size", 12)

	_center_card(confirm_card, viewport_size, Vector2(520, 310))
	_place(confirm_card.get_node("Kicker"), Rect2(28, 22, 464, 22))
	_place(confirm_card.get_node("Title"), Rect2(28, 55, 464, 32))
	_place(confirm_card.get_node("Copy"), Rect2(42, 105, 436, 58))
	_place(confirm_card.get_node("Cancel"), Rect2(28, 212, 220, 62))
	_place(confirm_card.get_node("Confirm"), Rect2(272, 212, 220, 62))
	(confirm_card.get_node("Kicker") as Label).add_theme_font_size_override("font_size", 9)
	(confirm_card.get_node("Title") as Label).add_theme_font_size_override("font_size", 18)
	(confirm_card.get_node("Copy") as Label).add_theme_font_size_override("font_size", 10)
	(confirm_card.get_node("Cancel") as Button).add_theme_font_size_override("font_size", 12)
	(confirm_card.get_node("Confirm") as Button).add_theme_font_size_override("font_size", 14)


func _center_card(card: Control, viewport_size: Vector2, card_size: Vector2) -> void :
	_place(card, Rect2((viewport_size - card_size) * 0.5, card_size))


func _place(control: Control, rect: Rect2) -> void :
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 0.0
	control.anchor_bottom = 0.0
	control.offset_left = rect.position.x
	control.offset_top = rect.position.y
	control.offset_right = rect.end.x
	control.offset_bottom = rect.end.y


func _show_main_view() -> void :
	_clear_detail_body()
	detail_view.visible = false
	main_view.visible = true
	_refresh_achievement_count()
	continue_button.grab_focus()


func _show_settings() -> void :
	main_view.visible = false
	detail_view.visible = true
	detail_title.text = "SETTINGS"
	_clear_detail_body()
	var iphone: = _iphone_layout_active()
	var intro: = _label("Tune the mine for headphones or phone speakers.", 16 if iphone else 9, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	intro.position = Vector2(0, 0)
	intro.size = Vector2(880, 42)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_body.add_child(intro)
	music_slider = _add_volume_control("MUSIC", audio_director.music_volume_percent(), 52)
	sfx_slider = _add_volume_control("SOUND EFFECTS", audio_director.sfx_volume_percent(), 172)
	var note: = _label("Separate levels are saved on this device.\nThe first tap also wakes audio on iPhone.", 16 if iphone else 9, Color("88a493"), HORIZONTAL_ALIGNMENT_CENTER)
	note.position = Vector2(0, 306)
	note.size = Vector2(880, 58)
	detail_body.add_child(note)
	music_slider.grab_focus()


func _add_volume_control(title: String, value: int, y: float) -> HSlider:
	var iphone: = _iphone_layout_active()
	var panel: = Panel.new()
	panel.position = Vector2(4, y)
	panel.size = Vector2(872, 112 if iphone else 104)
	panel.add_theme_stylebox_override("panel", _panel_style(Color("10251a"), Color(GOLD, 0.45), 13, 1))
	detail_body.add_child(panel)
	var title_label: = _label(title, 20 if iphone else 11, MINT, HORIZONTAL_ALIGNMENT_LEFT)
	title_label.position = Vector2(16, 12)
	title_label.size = Vector2(620, 25)
	panel.add_child(title_label)
	var value_label: = _label("%d%%" % value, 20 if iphone else 11, GOLD_BRIGHT, HORIZONTAL_ALIGNMENT_RIGHT)
	value_label.name = "Value"
	value_label.position = Vector2(780, 12)
	value_label.size = Vector2(68, 25)
	panel.add_child(value_label)
	var slider: = HSlider.new()
	slider.position = Vector2(16, 40 if iphone else 45)
	slider.size = Vector2(820, 66 if iphone else 48)
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 1
	slider.value = value
	slider.custom_minimum_size.y = 66 if iphone else 48
	slider.value_changed.connect( func(next_value: float):
		value_label.text = "%d%%" % roundi(next_value)
		audio_director.unlock_from_user_gesture()
		if title == "MUSIC":
			audio_director.set_music_volume(next_value / 100.0, false)
		else:
			audio_director.set_sfx_volume(next_value / 100.0, false)
	)
	slider.drag_ended.connect( func(_changed: bool):
		if title == "MUSIC":
			audio_director.set_music_volume(slider.value / 100.0)
		else:
			audio_director.set_sfx_volume(slider.value / 100.0)
		audio_director.play_ui("confirm")
	)
	panel.add_child(slider)
	return slider


func show_achievements(highlight_id: String = "") -> void :
	achievement_highlight_id = highlight_id
	achievement_service.evaluate()
	main_view.visible = false
	detail_view.visible = true
	detail_title.text = "ACHIEVEMENTS"
	_clear_detail_body()
	achievement_count_label = _label("", 18 if _iphone_layout_active() else 10, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	achievement_count_label.position = Vector2(0, -6)
	achievement_count_label.size = Vector2(880, 28)
	detail_body.add_child(achievement_count_label)
	achievement_scroll = ScrollContainer.new()
	achievement_scroll.position = Vector2(0, 30)
	achievement_scroll.size = Vector2(880, 370)
	achievement_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	detail_body.add_child(achievement_scroll)
	var list: = VBoxContainer.new()
	list.custom_minimum_size = Vector2(864, 0)
	list.add_theme_constant_override("separation", 8)
	achievement_scroll.add_child(list)
	achievement_rows.clear()
	for value in achievement_service.definitions():
		var definition: Dictionary = Dictionary(value)
		var row: Control = _achievement_row(definition)
		list.add_child(row)
		achievement_rows[String(definition.id)] = row
	_refresh_achievement_count()
	if not achievement_highlight_id.is_empty():
		call_deferred("_focus_highlighted_achievement")


func _achievement_row(definition: Dictionary) -> Control:
	var iphone: = _iphone_layout_active()
	var unlocked: bool = bool(achievement_service.is_unlocked(String(definition.id)))
	var row: = PanelContainer.new()
	row.custom_minimum_size = Vector2(864, 92 if iphone else 76)
	row.add_theme_stylebox_override("panel", _panel_style(
		Color("12291d") if unlocked else Color("0b1711"),
		Color(GOLD, 0.58) if unlocked else Color("304238"), 11, 1
	))
	var line: = HBoxContainer.new()
	line.add_theme_constant_override("separation", 10)
	row.add_child(line)
	var icon: = TextureRect.new()
	icon.custom_minimum_size = Vector2(78, 78) if iphone else Vector2(64, 64)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var asset_path: = "res://%s" % String(definition.asset)
	if ResourceLoader.exists(asset_path):
		icon.texture = load(asset_path)
	icon.modulate = Color.WHITE if unlocked else Color(0.26, 0.31, 0.28, 0.72)
	line.add_child(icon)
	var copy: = VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 2)
	line.add_child(copy)
	var title: = _label(String(definition.title).to_upper(), 18 if iphone else 10, GOLD_BRIGHT if unlocked else Color("7e8c82"), HORIZONTAL_ALIGNMENT_LEFT)
	title.custom_minimum_size.y = 22
	copy.add_child(title)
	var description: = _label(String(definition.description), 15 if iphone else 8, Color("a8bbaa") if unlocked else Color("59685e"), HORIZONTAL_ALIGNMENT_LEFT)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.size_flags_vertical = Control.SIZE_EXPAND_FILL
	copy.add_child(description)
	var state: = _label("UNLOCKED" if unlocked else "LOCKED", 13 if iphone else 7, GOLD if unlocked else Color("45564b"), HORIZONTAL_ALIGNMENT_LEFT)
	copy.add_child(state)
	return row


func _focus_highlighted_achievement() -> void :
	if achievement_scroll == null or achievement_highlight_id.is_empty():
		return
	var row: Control = achievement_rows.get(achievement_highlight_id) as Control
	if row == null or not is_instance_valid(row):
		return
	achievement_scroll.ensure_control_visible(row)
	row.pivot_offset = row.size * 0.5
	if achievement_highlight_tween != null and achievement_highlight_tween.is_valid():
		achievement_highlight_tween.kill()
	achievement_highlight_tween = create_tween()
	achievement_highlight_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	achievement_highlight_tween.set_loops(3)
	achievement_highlight_tween.tween_property(row, "modulate", Color(1.2, 1.12, 0.72, 1.0), 0.22)
	achievement_highlight_tween.tween_property(row, "modulate", Color.WHITE, 0.38)


func _iphone_layout_active() -> bool:
	var viewport_size: = get_viewport().get_visible_rect().size
	return viewport_size.x / maxf(viewport_size.y, 1.0) >= IPHONE_LANDSCAPE_ASPECT


func _refresh_achievement_count() -> void :
	var text: = "%d / %d UNLOCKED" % [achievement_service.unlocked_count(), achievement_service.definitions().size()]
	if achievements_button != null:
		achievements_button.text = "ACHIEVEMENTS\n%s" % text
	if achievement_count_label != null:
		achievement_count_label.text = text


func _clear_detail_body() -> void :
	if music_slider != null:
		audio_director.set_music_volume(float(music_slider.value) / 100.0)
	if sfx_slider != null:
		audio_director.set_sfx_volume(float(sfx_slider.value) / 100.0)
	music_slider = null
	sfx_slider = null
	achievement_count_label = null
	achievement_scroll = null
	achievement_rows.clear()
	achievement_highlight_id = ""
	if achievement_highlight_tween != null and achievement_highlight_tween.is_valid():
		achievement_highlight_tween.kill()
	achievement_highlight_tween = null
	for child in detail_body.get_children():
		child.queue_free()


func _menu_button(text_value: String, primary: bool) -> Button:
	var button: = Button.new()
	button.text = text_value
	button.add_theme_font_size_override("font_size", 14 if primary else 12)
	button.add_theme_color_override("font_color", GOLD_BRIGHT if primary else Color("e6d7a7"))
	button.add_theme_color_override("font_disabled_color", Color("59655d"))
	button.add_theme_stylebox_override("normal", _panel_style(Color("183322") if primary else Color("10261a"), Color(GOLD, 0.76 if primary else 0.42), 12, 2 if primary else 1))
	button.add_theme_stylebox_override("hover", _panel_style(Color("234b31"), GOLD, 12, 2))
	button.add_theme_stylebox_override("pressed", _panel_style(Color("0c1b13"), GOLD_BRIGHT, 12, 2))
	button.add_theme_stylebox_override("focus", _panel_style(Color(0, 0, 0, 0), GOLD_BRIGHT, 12, 2))
	return button


func _panel_style(fill: Color, border: Color, radius: int, width: int) -> StyleBoxFlat:
	var style: = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


func _label(text_value: String, font_size: int, color: Color, alignment: HorizontalAlignment) -> Label:
	var label: = Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
