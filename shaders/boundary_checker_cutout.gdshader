shader_type canvas_item;
render_mode unshaded;

// The legacy boundary PNG contains a baked light checkerboard rather than
// transparency. Key only bright, low-chroma pixels so the dark rock, moss,
// roots and blue crystals remain intact while the fake background disappears.
void fragment() {
	vec4 color = texture(TEXTURE, UV);
	float brightest = max(color.r, max(color.g, color.b));
	float darkest = min(color.r, min(color.g, color.b));
	float chroma = brightest - darkest;
	float luminance = dot(color.rgb, vec3(0.299, 0.587, 0.114));
	float near_neutral = 1.0 - smoothstep(0.025, 0.12, chroma);
	float checker_brightness = smoothstep(0.68, 0.84, luminance);
	color.a *= 1.0 - near_neutral * checker_brightness;
	COLOR = color;
}
