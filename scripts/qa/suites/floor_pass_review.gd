extends "res://scripts/qa/suites/lit_chunks_review.gd"
## Reuse the same deterministic fixture and timed/paired renderer driver.
## baseline/restored = DEV6; combined = one pass; sections = 128px chunks;
## optimized = both. This is an experiment, not a release default.

func set_variant(id: String) -> void:
	world.lit_floor_chunks.enabled = true
	world.lit_draw_sections.enabled = true
	world.lit_floor_chunks.composite_pass = id in ["combined", "optimized"]
	world.lit_floor_chunks.chunk_size = 128 if id in ["sections", "optimized"] else 256
	world.queue_redraw()
