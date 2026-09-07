shader_type canvas_item;
render_mode unshaded;
uniform float left_edge = 2120.0;
uniform float right_edge = 3420.0;
uniform bool last_biome = false;
varying float world_x;
varying vec4 tint;
void vertex() {
    world_x = (MODEL_MATRIX * vec4(VERTEX,0.0,1.0)).x;
    tint = COLOR;
}
void fragment() {
    vec4 pixel = texture(TEXTURE,UV) * tint;
    pixel.a *= smoothstep(left_edge,left_edge+140.0,world_x);
    if (!last_biome) pixel.a *= 1.0-smoothstep(right_edge-140.0,right_edge,world_x);
    COLOR = pixel;
}
