shader_type canvas_item;

uniform vec2 blend_y;
uniform bool fade_in;

varying float world_y;

void vertex() {
	world_y = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).y;
}

void fragment() {
	float blend = smoothstep(blend_y.x, blend_y.y, world_y);
	COLOR.a *= fade_in ? blend : 1.0 - blend;
}
