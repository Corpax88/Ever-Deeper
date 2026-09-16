shader_type canvas_item;
// Preserve every nonzero alpha sample, including filtered fringe texels.
// Fully transparent art needs no per-light or shadow work.
void fragment() {
	if (COLOR.a == 0.0) discard;
}
