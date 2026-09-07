shader_type canvas_item;
uniform sampler2D cloth_mask : filter_linear, repeat_disable;
uniform vec3 cloth_color : source_color = vec3(0.12, 0.25, 0.17);
uniform float recolor = 0.0;
void fragment() {
    // Fragment COLOR already includes the sprite texture and its modulation.
    vec4 original = COLOR;
    float mask_value = texture(cloth_mask, UV).r * recolor;
    float lightness = dot(original.rgb, vec3(0.2126, 0.7152, 0.0722));
    float target_lightness = max(dot(cloth_color, vec3(0.2126, 0.7152, 0.0722)), 0.01);
    vec3 dyed = cloth_color * lightness / target_lightness;
    COLOR = vec4(mix(original.rgb, dyed, mask_value), original.a);
}
