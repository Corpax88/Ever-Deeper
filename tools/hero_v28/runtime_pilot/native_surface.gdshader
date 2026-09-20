shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform sampler2D albedo_map : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D normal_map : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D orm_map : filter_linear_mipmap, repeat_enable;
uniform sampler2D response_map : filter_linear_mipmap, repeat_enable;
uniform bool native_response = false;
uniform float ao_direct = 0.35;

void fragment() {
	ALBEDO = texture(albedo_map, UV).rgb;
	NORMAL_MAP = texture(normal_map, UV).rgb;
	vec3 orm = texture(orm_map, UV).rgb;
	AO = orm.r;
	AO_LIGHT_AFFECT = ao_direct;
	ROUGHNESS = orm.g;
	METALLIC = orm.b;
	SPECULAR = 0.5;
	if (native_response) {
		vec3 response = texture(response_map, UV).rgb;
		SPECULAR = response.r;
		CLEARCOAT = response.g;
		CLEARCOAT_ROUGHNESS = response.b;
	}
}
