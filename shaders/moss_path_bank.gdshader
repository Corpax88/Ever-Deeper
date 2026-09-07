shader_type canvas_item;
render_mode unshaded;

uniform vec2 content_scale = vec2(1.0);
uniform float spread : hint_range(0.0, 0.18) = 0.08;
uniform vec4 edge_color : source_color = vec4(0.065, 0.095, 0.045, 1.0);
uniform vec4 inner_color : source_color = vec4(0.20, 0.28, 0.12, 1.0);
uniform vec4 source_tint : source_color = vec4(0.55, 0.65, 0.40, 1.0);
uniform float bank_opacity : hint_range(0.0, 1.0) = 0.84;
uniform sampler2D source_texture : source_color, filter_linear;

float source_alpha(vec2 uv) {
	float inside = step(0.0, uv.x) * step(0.0, uv.y) * step(uv.x, 1.0) * step(uv.y, 1.0);
	return texture(source_texture, clamp(uv, vec2(0.0), vec2(1.0))).a * inside;
}

void fragment() {
	vec2 source_uv = (UV - vec2(0.5)) / content_scale + vec2(0.5);
	vec4 source = texture(source_texture, clamp(source_uv, vec2(0.0), vec2(1.0)));
	float core = source.a * step(0.0, source_uv.x) * step(0.0, source_uv.y) * step(source_uv.x, 1.0) * step(source_uv.y, 1.0);
	float halo = core;
	halo = max(halo, source_alpha(source_uv + vec2(spread, 0.0)));
	halo = max(halo, source_alpha(source_uv + vec2(-spread, 0.0)));
	halo = max(halo, source_alpha(source_uv + vec2(0.0, spread)));
	halo = max(halo, source_alpha(source_uv + vec2(0.0, -spread)));
	float organic_alpha = smoothstep(0.04, 0.62, halo);
	float inner_mix = smoothstep(0.06, 0.82, core);
	float grain = fract(sin(dot(FRAGCOORD.xy, vec2(12.9898, 78.233))) * 43758.5453);
	vec3 authored_color = mix(inner_color.rgb, source.rgb * source_tint.rgb, 0.82);
	vec3 bank_color = mix(edge_color.rgb, authored_color, inner_mix);
	bank_color *= 0.97 + grain * 0.06;
	COLOR = vec4(bank_color, organic_alpha * bank_opacity);
}
