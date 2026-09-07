shader_type canvas_item;
render_mode unshaded;
varying vec4 sprite_modulate;

void vertex() { sprite_modulate = COLOR; }

void fragment() {
	vec4 texel = texture(TEXTURE, UV);
	float brightest = max(texel.r, max(texel.g, texel.b));
	float darkest = min(texel.r, min(texel.g, texel.b));
	float chroma = brightest - darkest;
	float luminance = dot(texel.rgb, vec3(0.299, 0.587, 0.114));
	float near_neutral = 1.0 - smoothstep(0.018, 0.075, chroma);
	float near_white = smoothstep(0.86, 0.965, luminance);
	texel.a *= 1.0 - near_neutral * near_white;
	COLOR = texel * sprite_modulate;
}
