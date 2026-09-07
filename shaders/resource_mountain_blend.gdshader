shader_type canvas_item;
render_mode unshaded;
uniform sampler2D next_stage : filter_linear;
uniform float stage_mix : hint_range(0.0,1.0) = 0.0;
varying vec4 tint;
void vertex() { tint = COLOR; }
void fragment() {
    vec4 a=texture(TEXTURE,UV);
    vec4 b=texture(next_stage,UV);
    float coverage=mix(a.a,b.a,stage_mix);
    vec3 rgb=mix(a.rgb*a.a,b.rgb*b.a,stage_mix)/max(coverage,0.00001);
    COLOR=vec4(rgb,coverage)*tint;
}
