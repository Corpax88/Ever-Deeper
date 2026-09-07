shader_type canvas_item;
uniform float text_height = 60.0;
varying float local_y;
void vertex() { local_y = VERTEX.y; }
void fragment() {
 float y = clamp(local_y / text_height, 0.0, 1.0);
 vec3 metal = mix(vec3(1.0,0.87,0.68), vec3(0.56,0.29,0.14), smoothstep(0.12,0.90,y));
 metal += vec3(0.17,0.13,0.08) * exp(-pow((y-0.28)*19.0,2.0));
 COLOR.rgb *= metal;
}
