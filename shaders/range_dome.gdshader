shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, unshaded;

uniform vec4 base_color : source_color = vec4(0.08, 0.65, 0.95, 0.18);
uniform vec4 rim_color : source_color = vec4(0.35, 0.92, 1.0, 0.85);
uniform vec4 wave_color : source_color = vec4(0.65, 1.0, 0.92, 1.0);
uniform float rim_power : hint_range(0.5, 6.0) = 2.2;
uniform float wave_speed : hint_range(0.2, 8.0) = 2.4;
uniform float wave_frequency : hint_range(2.0, 30.0) = 14.0;
uniform float wave_thickness : hint_range(0.02, 0.4) = 0.10;
uniform float grid_density : hint_range(5.0, 60.0) = 28.0;
uniform float master_alpha : hint_range(0.0, 1.0) = 1.0;
uniform float deploy_progress : hint_range(0.0, 1.0) = 1.0;
uniform float flash_intensity : hint_range(0.0, 2.0) = 0.0;
uniform float time_offset = 0.0;

varying float v_norm_height;

void vertex() {
	// In SphereMesh, UV.y is 0.0 at apex and 1.0 at base.
	// 1.0 - UV.y rises from 0.0 at the ground to 1.0 at the dome apex.
	v_norm_height = clamp(1.0 - UV.y, 0.0, 1.0);
}

void fragment() {
	// 1. Deployment Cutoff: discard portion above the rising wavefront
	if (v_norm_height > deploy_progress) {
		discard;
	}
	
	// 2. Blazing Energy Wavefront (leading edge of deployment)
	float deploy_edge = abs(v_norm_height - deploy_progress);
	float leading_crest = smoothstep(0.12, 0.0, deploy_edge) * step(0.001, deploy_progress) * step(deploy_progress, 0.999);
	
	vec3 norm = normalize(NORMAL);
	vec3 v_dir = normalize(VIEW);
	float n_dot_v = clamp(abs(dot(norm, v_dir)), 0.0, 1.0);
	float fresnel = pow(1.0 - n_dot_v, rim_power);
	
	float cur_time = TIME + time_offset;
	
	// Ascending rippling waves
	float wave_phase = UV.y * wave_frequency - cur_time * wave_speed;
	float sin_wave = sin(wave_phase);
	float wave_crest = smoothstep(1.0 - wave_thickness, 1.0, sin_wave);
	
	// Secondary faster radiant ripple
	float ripple_phase = UV.y * (wave_frequency * 0.65) - cur_time * (wave_speed * 1.6);
	float ripple = smoothstep(0.88, 1.0, sin(ripple_phase));
	
	// Subtle sci-fi holographic grid / scanlines
	vec2 g_uv = fract(UV * grid_density);
	float grid_lines = max(step(0.94, g_uv.x), step(0.94, g_uv.y)) * 0.18;
	
	// Equator/base ring glow accent
	float base_rim = smoothstep(0.85, 1.0, UV.y) * 0.4;
	
	// Composite luminous colors
	vec3 out_col = base_color.rgb;
	out_col = mix(out_col, rim_color.rgb, fresnel * 0.75 + base_rim);
	out_col += wave_color.rgb * (wave_crest * 1.4 + ripple * 0.9);
	out_col += rim_color.rgb * grid_lines;
	
	// Add leading deployment crest blazing light
	out_col += wave_color.rgb * (leading_crest * 3.5);
	
	// Add shield initialization flash burst
	out_col += rim_color.rgb * (flash_intensity * 1.6);
	
	// Transparency
	float dynamic_alpha = base_color.a * 0.4 + fresnel * 0.65 + wave_crest * 0.75 + ripple * 0.45 + grid_lines * 0.3 + base_rim;
	dynamic_alpha = max(dynamic_alpha, leading_crest * 0.95);
	dynamic_alpha += flash_intensity * 0.55;
	dynamic_alpha = clamp(dynamic_alpha * master_alpha, 0.0, 0.95);
	
	ALBEDO = out_col;
	ALPHA = dynamic_alpha;
}
