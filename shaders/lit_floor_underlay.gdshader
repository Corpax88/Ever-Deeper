shader_type canvas_item;
// One lighting evaluation for the original opaque underlay and tinted texture.
// Preserve straight-alpha source-over composition, including item modulation.
uniform vec4 floor_tint : source_color = vec4(1.0);
uniform vec4 floor_underlay : source_color = vec4(0.0);
varying vec4 item_modulate;
void vertex() { item_modulate = COLOR; }
void fragment() {
    vec4 top = COLOR * floor_tint;
    vec4 bottom = item_modulate * floor_underlay;
    float bottom_weight = bottom.a * (1.0 - top.a);
    float alpha = top.a + bottom_weight;
    COLOR = vec4((top.rgb * top.a + bottom.rgb * bottom_weight) / max(alpha, 0.000001), alpha);
}
