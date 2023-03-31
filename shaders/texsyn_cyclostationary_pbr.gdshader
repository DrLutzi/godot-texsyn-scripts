// NOTE: Shader automatically converted from Godot Engine 4.0.stable's StandardMaterial3D.

shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_burley,specular_schlick_ggx;
uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform float point_size : hint_range(0,128);
uniform float roughness : hint_range(0,1);
uniform sampler2D texture_metallic : hint_default_white,filter_linear_mipmap_anisotropic,repeat_enable;
uniform vec4 metallic_texture_channel;
uniform sampler2D texture_roughness : hint_roughness_r,filter_linear_mipmap_anisotropic,repeat_enable;
uniform float specular;
uniform float metallic;
uniform sampler2D texture_normal : hint_roughness_normal,filter_linear_mipmap_anisotropic,repeat_enable;
uniform float normal_scale : hint_range(-16,16);
uniform sampler2D texture_ambient_occlusion : hint_default_white, filter_linear_mipmap_anisotropic,repeat_enable;
uniform vec4 ao_texture_channel;
uniform float ao_light_affect;
uniform sampler2D texture_heightmap : hint_default_black,filter_linear_mipmap_anisotropic,repeat_enable;
uniform float heightmap_scale;
uniform int heightmap_min_layers;
uniform int heightmap_max_layers;
uniform vec2 heightmap_flip;
uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform vec3 uv2_scale;
uniform vec3 uv2_offset;

//Specific to this shader
uniform sampler2D samplerRealization : filter_nearest;
uniform sampler2D mean_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D mean_normal : hint_roughness_normal,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D mean_roughness : hint_roughness_r,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D mean_metallic : hint_default_white, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D mean_heightmap : hint_default_black, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D mean_ambient_occlusion : hint_default_white, filter_linear_mipmap_anisotropic, repeat_enable;

void vertex() {
	UV=UV*uv1_scale.xy+uv1_offset.xy;
}

float rnd21(vec2 p)
{
	return fract(sin(dot(p.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

vec2 rnd22(vec2 p)
{
	return fract(sin(p * mat2(vec2(127.1, 311.7), vec2(269.5, 183.3)) ) * 43758.5453);
}

float W0cos(vec2 uv)
{
	float cosu = sin(uv.x*PI);
	float cosv = sin(uv.y*PI);
	return pow(cosu*cosv*cosu*cosv, 0.5)+0.005;
}

float W1cos(vec2 uv)
{
	uv.x+=0.5;
	uv.y+=0.5;
	float cosu = sin(uv.x*PI);
	float cosv = sin(uv.y*PI);
	return pow(cosu*cosv*cosu*cosv, 0.5)+0.005;
}

vec2 K0(vec2 uv)
{
	vec2 seed;
	seed.x = floor(uv.x);
	seed.y = floor(uv.y);
	return seed*2.0;
}

vec2 K1(vec2 uv)
{
	vec2 seed;
	seed = vec2(floor(uv.x+0.5), floor(uv.y+0.5));
	return seed*2.0 + vec2(1.0, 1.0);
}

//#define EXEMPLARS_ALREADY_CENTERED

#ifdef EXEMPLARS_ALREADY_CENTERED
#define MEAN_CENTER(mean) 0.
#define MEAN_CENTER_3D(mean) vec3(0.0, 0.0, 0.0)
#else
#define MEAN_CENTER(mean) mean
#define MEAN_CENTER_3D(mean) mean
#endif

#define TILING(sampler, uv) textureGrad(sampler, uv, Gx, Gy)
#define BLENDING(first, second) (first)*w.x + (second)*w.y
#define ADJUST_STATS(value, mean) value/length(w) + mean
#define MEAN(samplerMean) textureGrad(samplerMean, base_uv, Gx, Gy)
#define TILING_AND_BLENDING_3D(sampler, mean) \
	ADJUST_STATS(BLENDING(	TILING(sampler, UVK0).rgb - MEAN_CENTER_3D(mean), \
							TILING(sampler, UVK1).rgb - MEAN_CENTER_3D(mean)), mean)
#define TILING_AND_BLENDING_1D(sampler, mean) \
	ADJUST_STATS(BLENDING(	TILING(sampler, UVK0).r - MEAN_CENTER(mean), \
							TILING(sampler, UVK1).r - MEAN_CENTER(mean)), mean)
#define TILING_AND_BLENDING_1D_DOT(sampler, mean, channel) \
	ADJUST_STATS(BLENDING(	dot(TILING(sampler, UVK0), channel) - MEAN_CENTER(mean), \
							dot(TILING(sampler, UVK1), channel) - MEAN_CENTER(mean)), mean)

void fragment() 
{									// scale of the synthesis
	vec2 base_uv = UV;
	{
		//Depth
		vec3 view_dir = normalize(normalize(-VERTEX)*mat3(TANGENT*heightmap_flip.x,-BINORMAL*heightmap_flip.y,NORMAL));
		vec2 Gx, Gy;
		Gx = dFdx(base_uv);									//coordinate derivatives
		Gy = dFdy(base_uv);
		vec2 w;														//weights
		float wSum;													//weights sum
		vec2 k0 = K0(base_uv);										//first tiling
		vec2 k1 = K1(base_uv);										//second tiling
		w = vec2(W0cos(base_uv), W1cos(base_uv));
		wSum = w.x+w.y;
		w/=wSum;
		vec2 UVK0 = base_uv + texture(samplerRealization, vec2(rnd21(k0), 0)).xy;
		vec2 UVK1 = base_uv + texture(samplerRealization, vec2(rnd21(k1), 0)).xy;
		float heightmap_mean = MEAN(mean_heightmap).x;
		float depth = 1.0 - TILING_AND_BLENDING_1D(texture_heightmap, heightmap_mean);
		vec2 ofs = base_uv - view_dir.xy * depth * heightmap_scale * 0.01;
		base_uv=ofs;
	}
	vec2 Gx, Gy;
	Gx = dFdx(base_uv);									//coordinate derivatives
	Gy = dFdy(base_uv);
	vec2 w;														//weights
	float wSum;													//weights sum
	vec2 k0 = K0(base_uv);										//first tiling
	vec2 k1 = K1(base_uv);										//second tiling
	w = vec2(W0cos(base_uv), W1cos(base_uv));
	wSum = w.x+w.y;
	w/=wSum;
	vec2 UVK0 = base_uv + texture(samplerRealization, vec2(rnd21(k0), 0)).xy;
	vec2 UVK1 = base_uv + texture(samplerRealization, vec2(rnd21(k1), 0)).xy;
	
	//Albedo
	vec3 albedo_mean = MEAN(mean_albedo).rgb;
	vec3 albedo_tex = TILING_AND_BLENDING_3D(texture_albedo, albedo_mean);
	ALBEDO = albedo.rgb * albedo_tex.rgb;
	
	//Metallic
	float metallic_mean = dot(MEAN(mean_metallic), metallic_texture_channel);
	float metallic_tex = TILING_AND_BLENDING_1D_DOT(texture_metallic, metallic_mean, metallic_texture_channel);
	METALLIC = metallic_tex * metallic;
	
	//Roughness + Specular
	vec4 roughness_texture_channel = vec4(1.0,0.0,0.0,0.0);
	float roughness_mean = dot(MEAN(mean_roughness), roughness_texture_channel);
	float roughness_tex = TILING_AND_BLENDING_1D_DOT(texture_roughness, roughness_mean, roughness_texture_channel);
	ROUGHNESS = roughness_tex * roughness;
	SPECULAR = specular;
	
	//Normal map
	vec3 normal_mean = MEAN(mean_normal).rgb;
	NORMAL_MAP = TILING_AND_BLENDING_3D(texture_normal, normal_mean);
	NORMAL_MAP_DEPTH = normal_scale;
	
	//AO
	float ao_mean = dot(MEAN(mean_ambient_occlusion), ao_texture_channel);
	AO = TILING_AND_BLENDING_1D_DOT(texture_ambient_occlusion, ao_mean, ao_texture_channel);
	AO_LIGHT_AFFECT = ao_light_affect;
}
