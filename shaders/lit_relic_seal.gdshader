shader_type canvas_item;
// Light follows the carved native inlay. The stone's scale never animates.
uniform vec4 resonance : source_color = vec4(0.5, 0.95, 0.85, 1.0);
uniform float strength = 0.0;
uniform float pulse = 0.0;
void fragment() {
	vec4 stone = COLOR;
	float inlay = clamp(max((stone.r - stone.g * 1.4) * 3.0, (stone.b - stone.r) * 4.0), 0.0, 1.0);
	float glow = strength * (1.0 + pulse * sin(TIME * 5.0));
	COLOR = vec4(stone.rgb + resonance.rgb * inlay * glow, stone.a);
}
