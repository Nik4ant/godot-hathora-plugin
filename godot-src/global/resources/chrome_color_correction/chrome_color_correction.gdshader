shader_type canvas_item;

uniform highp sampler2D SCREEN_TEXTURE : hint_screen_texture, repeat_disable, filter_nearest;
const float EXTRA_SATURATION = 0.08;
const float EXTRA_VALUE = 0.06;

// Source: https://godotshaders.com/shader/hsv-adjustment/
vec3 rgb2hsv(vec3 c) {
    highp vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    highp vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    highp vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    highp float d = q.x - min(q.w, q.y);
    highp float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}
vec3 hsv2rgb(highp vec3 c) {
    highp vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    highp vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void fragment() {
	highp vec4 color = textureLod(SCREEN_TEXTURE, SCREEN_UV, 0.0);
	
	if (color.rgb != vec3(1.0, 1.0, 1.0) && color.rgb != vec3(0.0, 0.0, 0.0)) {
		highp vec3 hsv = rgb2hsv(color.rgb);
		hsv[1] += EXTRA_SATURATION;
		hsv[2] += EXTRA_VALUE;
		color.rgb = hsv2rgb(hsv);
	}
	COLOR = color;
}