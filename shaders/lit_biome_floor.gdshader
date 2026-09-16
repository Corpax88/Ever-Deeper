shader_type canvas_item;
// Native geology textures meet in a world-anchored, irregular sediment seam.
// Only a boundary strip samples the neighbouring biome; texture density is 1:1.
uniform vec4 floor_tint : source_color = vec4(1.0);
uniform vec4 floor_wash : source_color = vec4(0.0);
uniform vec4 previous_wash : source_color = vec4(0.0);
uniform vec4 next_wash : source_color = vec4(0.0);
uniform sampler2D previous_floor : source_color, filter_linear, repeat_enable;
uniform sampler2D next_floor : source_color, filter_linear, repeat_enable;
uniform sampler2D boundary_noise : filter_linear, repeat_enable;
uniform float world_origin_y = 0.0;
uniform float band_start = 0.0;
uniform float band_height = 1408.0;
uniform bool first_band = false;
varying vec4 item_modulate;
varying vec2 world_position;

void vertex() {
	item_modulate = COLOR;
	world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy + vec2(0.0, world_origin_y);
}

void fragment() {
	vec4 native_floor = COLOR;
	vec4 wash = floor_wash;
	float local_y = world_position.y - band_start;
	if ((!first_band && local_y < 200.0) || local_y > band_height - 200.0) {
		float contour = (texture(boundary_noise, world_position / 768.0).r - 0.5) * 200.0;
		if (local_y < 200.0) {
			float mix_amount = 1.0 - smoothstep(-78.0, 78.0, local_y + contour);
			vec4 adjacent = texture(previous_floor, world_position / vec2(textureSize(previous_floor, 0))) * item_modulate;
			native_floor = mix(native_floor, adjacent, mix_amount);
			wash = mix(wash, previous_wash, mix_amount);
		} else {
			float mix_amount = smoothstep(-78.0, 78.0, local_y - band_height + contour);
			vec4 adjacent = texture(next_floor, world_position / vec2(textureSize(next_floor, 0))) * item_modulate;
			native_floor = mix(native_floor, adjacent, mix_amount);
			wash = mix(wash, next_wash, mix_amount);
		}
	}
	vec4 floor_color = native_floor * floor_tint;
	vec4 wash_color = item_modulate * wash;
	float floor_weight = floor_color.a * (1.0 - wash_color.a);
	float alpha = floor_weight + wash_color.a;
	COLOR = vec4((floor_color.rgb * floor_weight + wash_color.rgb * wash_color.a) / max(alpha, 0.000001), alpha);
}
