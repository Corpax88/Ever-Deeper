shader_type canvas_item;
render_mode unshaded;
varying vec4 sprite_modulate;

// Keep the Mossvein/Moonglass panorama visible only where that world exists.
// Emberdeep and Starfall use opaque ground, so sampling these two full-screen
// textures to the right of the authored boundary is invisible mobile overdraw.
uniform float world_right = 2240.0;
varying float world_x;

void vertex() {
	sprite_modulate = COLOR;
	world_x = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).x;
}

void fragment() {
	if (world_x > world_right) {
		discard;
	}
	COLOR = texture(TEXTURE, UV) * sprite_modulate;
}
