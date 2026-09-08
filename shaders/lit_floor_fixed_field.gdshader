shader_type canvas_item;
uniform vec4 floor_tint : source_color = vec4(1.0);
uniform vec4 floor_wash : source_color = vec4(0.0);
uniform sampler2D fixed_field : filter_linear, repeat_disable;
uniform vec2 fixed_origin;
uniform vec2 fixed_inv_size;
uniform float fixed_energy;
uniform bool fixed_enabled = true;
uniform vec4 ambient;
varying vec4 item_modulate;
varying vec2 floor_position;
varying vec4 floor_albedo;

void vertex() {
	item_modulate = COLOR;
	floor_position = VERTEX;
}

void fragment() {
	vec4 floor_color = COLOR * floor_tint;
	vec4 wash_color = item_modulate * floor_wash;
	float floor_weight = floor_color.a * (1.0 - wash_color.a);
	float alpha = floor_weight + wash_color.a;
	floor_albedo = vec4((floor_color.rgb * floor_weight + wash_color.rgb * wash_color.a) / max(alpha, 0.000001), alpha);
	vec3 fixed_light = fixed_enabled ? texture(fixed_field, (floor_position - fixed_origin) * fixed_inv_size).rgb * fixed_energy : vec3(0.0);
	COLOR = vec4(floor_albedo.rgb * (vec3(1.0) + fixed_light / max(ambient.rgb, vec3(0.000001))), floor_albedo.a);
}

void light() {
	// Only moving lights reach this path. They multiply the original albedo.
	LIGHT = vec4(LIGHT_COLOR.rgb * LIGHT_ENERGY * floor_albedo.rgb, LIGHT_COLOR.a);
}
