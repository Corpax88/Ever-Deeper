extends RefCounted
## Interior points of the actual ore image, retained inside both pulse extremes.
static func points(sprite: Sprite2D) -> Array[Vector2]:
	var picture := sprite.texture.get_image()
	if picture.is_compressed(): picture.decompress()
	var result: Array[Vector2] = []
	var half := Vector2(picture.get_size())*.5
	for y in range(-48,49,4):
		for x in range(-48,49,4):
			var point := Vector2(x,y)
			var inside := true
			for pulse in [.91,1.035]:
				for margin in [Vector2.ZERO,Vector2(2,0),Vector2(-2,0),Vector2(0,2),Vector2(0,-2)]:
					var texel: Vector2 = ((point+margin)/pulse-sprite.position)/sprite.scale+half
					var ix := int(round(texel.x))
					var iy := int(round(texel.y))
					if ix < 0 or iy < 0 or ix >= picture.get_width() or iy >= picture.get_height() or picture.get_pixel(ix,iy).a < .5:
						inside = false
						break
				if not inside: break
			if inside: result.append(point)
	return result
