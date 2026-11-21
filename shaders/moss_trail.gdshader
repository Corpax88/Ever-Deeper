shader_type canvas_item;

void fragment() {
	// The camp path is painted vertically. Mirror alternate tiles at the seams.
	float along = 1.0 - abs(mod(UV.x * 0.24, 2.0) - 1.0);
	vec4 earth = texture(TEXTURE, vec2(UV.y, mix(0.15, 0.85, along)));
	float value = dot(earth.rgb, vec3(0.30, 0.59, 0.11));
	COLOR = vec4(mix(earth.rgb, vec3(0.40, 0.32, 0.22) * (0.6 + value), 0.60), earth.a);
}
