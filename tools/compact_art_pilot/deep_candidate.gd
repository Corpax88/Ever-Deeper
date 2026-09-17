extends "res://tools/compact_art_pilot/north_reference.gd"
## Unapproved art study. Ordinary scenes never load this subclass.
const STUDY_MOSS_CORNER_PATH: String = "res://assets/mossvein/cave-corner-v2.png"
const STUDY_CORNER_CELL := Vector2i(16, 27)
const STUDY_SEED: int = 4608
const STUDY_DEPTH: int = 14
const STUDY_CANVAS_OFFSET := Vector2(-32.0, -32.0)
const STUDY_CANVAS_SIZE := Vector2(128.0, 128.0)
const STUDY_CORNER_TEXTURE: Texture2D = preload("res://tools/compact_art_pilot/assets/moss-ne-three-boulder-unapproved.png")
var compact_art_study_enabled: bool = false
var study_corner_draw_calls: int = 0
var study_corner_drawn_cells: Dictionary = {}
var study_corner_contexts: Dictionary = {}

func _draw_permanent_wall_corners(cell: Vector2i, rect: Rect2, open_sides: Array) -> void:
	# Record the unchanged topology and asset selection of every visited corner
	# owner, including cells that delegate entirely to production.
	study_corner_contexts[str(cell)] = {
		"open_sides":open_sides.duplicate(), "mineable":_cell_diggable(cell),
		"mineable_asset":diggable_corner_texture.resource_path if diggable_corner_texture != null else "",
		"bedrock_asset":cave_wall_corner_texture.resource_path if cave_wall_corner_texture != null else "",
	}
	if not compact_art_study_enabled or not north_edge_study_enabled or cell != STUDY_CORNER_CELL:
		super._draw_permanent_wall_corners(cell, rect, open_sides)
		return
	if int(RunState.world_seed) != STUDY_SEED or current_depth != STUDY_DEPTH or depth_at_position(_cell_center(cell)) != STUDY_DEPTH:
		super._draw_permanent_wall_corners(cell, rect, open_sides)
		return
	if not _cell_diggable(cell) or _is_floor(cell) or open_sides != [true, true, false, false]:
		super._draw_permanent_wall_corners(cell, rect, open_sides)
		return
	if diggable_wall_texture == null or diggable_corner_texture == null or diggable_wall_texture.resource_path != STUDY_MOSS_EDGE_PATH or diggable_corner_texture.resource_path != STUDY_MOSS_CORNER_PATH:
		super._draw_permanent_wall_corners(cell, rect, open_sides)
		return
	# Exactly one eligible corner exists in this guarded topology: NE. Replace
	# its full native corner draw with the complete, unaltered generated PNG.
	# No crop, mask, rotation, reflection, trim or anisotropic scaling is used.
	# The same CanvasItem/material, lighting, draw order and world transform stay.
	var destination := Rect2(Vector2(cell) * TILE_SIZE + STUDY_CANVAS_OFFSET, STUDY_CANVAS_SIZE)
	_draw_canvas.draw_texture_rect(STUDY_CORNER_TEXTURE, destination, false, Color.WHITE)
	study_corner_draw_calls += 1
	study_corner_drawn_cells[cell] = true
