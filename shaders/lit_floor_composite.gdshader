shader_type canvas_item;
// Composite the original floor and wash before their shared linear lighting.
uniform vec4 floor_tint : source_color = vec4(1.0);
uniform vec4 floor_wash : source_color = vec4(0.0);
varying vec4 item_modulate;

void vertex() {
	item_modulate = COLOR;
}

void fragment() {
	vec4 floor_color = COLOR * floor_tint;
	vec4 wash_color = item_modulate * floor_wash;
	float floor_weight = floor_color.a * (1.0 - wash_color.a);
	float alpha = floor_weight + wash_color.a;
	COLOR = vec4((floor_color.rgb * floor_weight + wash_color.rgb * wash_color.a) / max(alpha, 0.000001), alpha);
}
