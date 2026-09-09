shader_type canvas_item;
uniform vec3 cloth_color : source_color = vec3(0.12, 0.25, 0.17);
uniform float recolor = 0.0;

void fragment() {
    vec4 original = COLOR;
    // Only the authored green fabric has this hue. Skin, hair, brass, leather,
    // boots and glasses retain their original color and shading in every outfit.
    float green = original.g - max(original.r, original.b);
    float fabric = smoothstep(0.005, 0.025, green) * recolor;
    float lightness = dot(original.rgb, vec3(0.2126, 0.7152, 0.0722));
    float target_lightness = max(dot(cloth_color, vec3(0.2126, 0.7152, 0.0722)), 0.01);
    vec3 dyed = cloth_color * lightness / target_lightness;
    COLOR = vec4(mix(original.rgb, dyed, fabric), original.a);
}
