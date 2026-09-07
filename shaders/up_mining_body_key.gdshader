shader_type canvas_item;

// The generated tool-free animation was delivered on a pale preview grid.
// Key only bright, nearly colourless pixels so painted skin, brass, cloth,
// leather and the dark helmet keep their original antialiased edges.
void fragment() {
	vec4 colour = texture(TEXTURE, UV);
	float brightest = max(colour.r, max(colour.g, colour.b));
	float darkest = min(colour.r, min(colour.g, colour.b));
	float chroma = brightest - darkest;
	float brightness = (colour.r + colour.g + colour.b) / 3.0;
	float pale = smoothstep(0.70, 0.84, brightness);
	float neutral = 1.0 - smoothstep(0.05, 0.16, chroma);
	colour.a *= 1.0 - pale * neutral;
	COLOR = colour;
}
