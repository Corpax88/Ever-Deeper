extends "res://tools/review_native_rig.gd"
## Bounded lighting calibration, using unchanged native matrices and material maps.

func _reference_poses() -> void:
	var world_environment: Environment
	var fill: Light3D
	for child in rig.viewport.get_children():
		if child is WorldEnvironment: world_environment = child.environment
		if child is Light3D and child.name == "soft cool fill": fill = child
	assert(world_environment != null and fill != null)
	var cases: Array[Dictionary] = [
		{"id": "original_settings", "exposure": 1.0, "contrast": 1.25, "fill_specular": 1.0},
		{"id": "fill_diffuse_only", "exposure": 1.0, "contrast": 1.25, "fill_specular": 0.0},
		{"id": "agx_native_contrast", "exposure": 1.0, "contrast": 1.5, "fill_specular": 1.0},
		{"id": "half_exposure", "exposure": .5, "contrast": 1.5, "fill_specular": 1.0},
		{"id": "two_thirds_exposure", "exposure": .6666667, "contrast": 1.5, "fill_specular": 1.0},
	]
	for calibration in cases:
		world_environment.tonemap_exposure = float(calibration.exposure)
		world_environment.tonemap_agx_contrast = float(calibration.contrast)
		world_environment.adjustment_enabled = calibration.id in ["original_settings", "fill_diffuse_only"]
		fill.light_specular = float(calibration.fill_specular)
		for cell in [0, 12]:
			var id: String = "%s_cell_%02d" % [calibration.id, cell]
			rig.set_reference_pose("mine", float(cell)/50.0)
			for frame in 3: await process_frame
			await RenderingServer.frame_post_draw
			var picture: Image = rig.viewport.get_texture().get_image()
			picture.save_png(output.path_join(id + "-raw.png"))
			picture.resize(200, 200, Image.INTERPOLATE_LANCZOS)
			picture.save_png(output.path_join(id + ".png"))
			var error: float = rig.reference_pose_error()
			if error > .00001: failures.append("Native matrix mismatch: " + id)
			stages.append({"id": id, "native_cell": cell, "calibration": calibration,
				"lighting_profile": lighting_profile, "native_pose_error": error,
				"raw_raster_size": raster_size, "maps_unchanged": true})
			print("NATIVE_LIGHTING_SAMPLE ", id)
