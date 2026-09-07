class_name ResourcePickupBurst
extends Node2D

const MAX_VISIBLE: = 3
const MERGE_WINDOW: = 1.15
const APPEAR_SECONDS: = 0.18
const HOLD_SECONDS: = 2.75
const FADE_SECONDS: = 0.75
const TEXT_FONT_SIZE: = 28

const RESOURCE_NAMES: = {
	"stone": "STONE",
	"copper": "COPPER",
	"gold": "GOLD",
	"moonglass": "MOONGLASS",
	"starshard": "STARSHARD",
	"emberstone": "EMBERSTONE",
	"sunslag": "SUNSLAG",
	"astralite": "ASTRALITE",
	"crownstone": "CROWNSTONE",
	"deepstone": "DEEPSTONE",
	"rootiron": "ROOTIRON",
	"ambercore": "AMBERCORE",
	"prismite": "PRISMITE",
	"lunacore": "LUNACORE",
	"magmaite": "MAGMAITE",
	"furnaceheart": "FURNACEHEART",
	"voidglass": "VOIDGLASS",
	"singularity": "SINGULARITY",
	"burrowsteel": "BURROWSTEEL",
	"phasecrystal": "PHASECRYSTAL",
	"infernium": "INFERNIUM",
}

const RESOURCE_COLORS: = {
	"stone": Color("e6dfcf"),
	"copper": Color("f0a35c"),
	"gold": Color("ffd66b"),
	"moonglass": Color("69e8ff"),
	"starshard": Color("c8a8ff"),
	"emberstone": Color("ff7650"),
	"sunslag": Color("ffca59"),
	"astralite": Color("bd91ff"),
	"crownstone": Color("f2c9ff"),
	"deepstone": Color("aebbd0"),
	"rootiron": Color("bf8e68"),
	"ambercore": Color("ffc15d"),
	"prismite": Color("82e5ff"),
	"lunacore": Color("a4d3ff"),
	"magmaite": Color("ff6f47"),
	"furnaceheart": Color("ffad4f"),
	"voidglass": Color("b889ff"),
	"singularity": Color("e6d7ff"),
	"burrowsteel": Color("a9c1c7"),
	"phasecrystal": Color("8ef4ff"),
	"infernium": Color("ff8e56"),
}

var entries: Array[Dictionary] = []


func _ready() -> void :
	z_as_relative = false
	z_index = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(false)


func show_pickup(kind: String, amount: int) -> void :
	var resource_key: = "gold" if kind == "coin" else kind
	if amount <= 0 or resource_key.is_empty():
		return
	set_process(true)
	for index in entries.size():
		var existing: Dictionary = entries[index]
		if String(existing.kind) == resource_key and float(existing.age) <= MERGE_WINDOW:
			existing.amount = int(existing.amount) + amount
			existing.age = APPEAR_SECONDS
			existing.pulse = 0.22
			(existing.label as Label).text = _pickup_text(resource_key, int(existing.amount))
			entries[index] = existing
			return
	while entries.size() >= MAX_VISIBLE:
		_remove_entry(0)
	entries.append(_make_entry(resource_key, amount))


func _process(delta: float) -> void :
	for index in range(entries.size() - 1, -1, -1):
		var entry: Dictionary = entries[index]
		entry.age = float(entry.age) + maxf(0.0, delta)
		entry.pulse = maxf(0.0, float(entry.pulse) - delta)
		var age: = float(entry.age)
		if age >= HOLD_SECONDS + FADE_SECONDS:
			_remove_entry(index)
			continue
		var root: = entry.root as Node2D
		var stack_index: = entries.size() - 1 - index
		var rise: = 12.0 * minf(1.0, age / HOLD_SECONDS)
		root.position = Vector2(0.0, -106.0 - float(stack_index) * 44.0 - rise)
		var pop_scale: = 1.0
		if age < APPEAR_SECONDS:
			pop_scale = lerpf(0.9, 1.0, smoothstep(0.0, APPEAR_SECONDS, age))
		if float(entry.pulse) > 0.0:
			pop_scale += sin(float(entry.pulse) / 0.22 * PI) * 0.06
		root.scale = Vector2.ONE * pop_scale
		var alpha: = 1.0
		if age < APPEAR_SECONDS:
			alpha = smoothstep(0.0, APPEAR_SECONDS, age)
		elif age > HOLD_SECONDS:
			alpha = 1.0 - smoothstep(HOLD_SECONDS, HOLD_SECONDS + FADE_SECONDS, age)
		root.modulate = Color(1.0, 1.0, 1.0, alpha)
		entries[index] = entry


func _make_entry(kind: String, amount: int) -> Dictionary:
	var root: = Node2D.new()
	root.name = "Pickup_%s" % kind
	add_child(root)
	var tint: Color = RESOURCE_COLORS.get(kind, Color("f4e8be"))
	var amount_label: = Label.new()
	amount_label.name = "PickupText"
	amount_label.position = Vector2(-180.0, -24.0)
	amount_label.size = Vector2(360.0, 48.0)
	amount_label.text = _pickup_text(kind, amount)
	amount_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	amount_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	amount_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	amount_label.add_theme_font_size_override("font_size", TEXT_FONT_SIZE)
	amount_label.add_theme_color_override("font_color", tint)
	amount_label.add_theme_color_override("font_outline_color", Color(0.015, 0.02, 0.018, 0.96))
	amount_label.add_theme_constant_override("outline_size", 6)
	root.add_child(amount_label)
	root.scale = Vector2.ONE * 0.9
	root.modulate.a = 0.0
	return {
		"root": root,
		"label": amount_label,
		"kind": kind,
		"amount": amount,
		"age": 0.0,
		"pulse": 0.0,
	}


func _pickup_text(kind: String, amount: int) -> String:
	var display_name: = String(RESOURCE_NAMES.get(kind, kind.replace("_", " ").to_upper()))
	return "+%d %s" % [amount, display_name]


func _remove_entry(index: int) -> void :
	if index < 0 or index >= entries.size():
		return
	var root: = entries[index].root as Node2D
	if is_instance_valid(root):
		root.queue_free()
	entries.remove_at(index)
	if entries.is_empty():
		set_process(false)


func debug_snapshot() -> Dictionary:
	var visible_entries: Array[Dictionary] = []
	for value in entries:
		var entry: Dictionary = value
		visible_entries.append({
			"kind": String(entry.kind),
			"amount": int(entry.amount),
			"age": float(entry.age),
		})
	return {
		"transparent": true,
		"has_panel": false,
		"has_icon": false,
		"presentation": "color_coded_text",
		"color_coded": true,
		"text_font_size": TEXT_FONT_SIZE,
		"max_visible": MAX_VISIBLE,
		"merge_window": MERGE_WINDOW,
		"hold_seconds": HOLD_SECONDS,
		"fade_seconds": FADE_SECONDS,
		"entries": visible_entries,
	}
