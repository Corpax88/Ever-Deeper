shader_type canvas_item;

uniform float greeting : hint_range(0.0, 1.0) = 0.0;
varying vec4 sprite_tint;

void vertex() {
	sprite_tint = COLOR;
}

void fragment() {
	// The upper body breathes and nods while the boots hold their ground.
	float torso = 1.0 - smoothstep(0.22, 0.88, UV.y);
	float head = 1.0 - smoothstep(0.18, 0.48, UV.y);
	float breath = sin(TIME * 2.1);
	vec2 motion = vec2(
		(0.010 * breath + 0.026 * greeting) * torso,
		-0.017 * breath * torso + 0.043 * greeting * head
	);
	COLOR = texture(TEXTURE, clamp(UV - motion, vec2(0.0), vec2(1.0))) * sprite_tint;
}
