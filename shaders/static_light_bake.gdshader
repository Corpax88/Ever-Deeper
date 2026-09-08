shader_type canvas_item;
render_mode unshaded, blend_add;
// Premultiply the source once. Opaque output keeps the cached field's alpha at one.
void fragment() {
	COLOR = vec4(COLOR.rgb * COLOR.a, 1.0);
}
