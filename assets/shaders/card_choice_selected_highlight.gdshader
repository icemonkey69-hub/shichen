shader_type canvas_item;
render_mode blend_add, unshaded;

uniform vec4 glow_color : source_color = vec4(1.0, 0.85, 0.45, 1.0);
uniform float strength : hint_range(0.0, 2.5) = 0.0;
uniform float flash_strength : hint_range(0.0, 4.0) = 0.0;
uniform float edge_width : hint_range(1.0, 14.0) = 6.5;
uniform float sweep_width : hint_range(0.02, 0.24) = 0.075;
uniform float sweep_progress : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float center_alpha = tex.a;
	vec2 px = TEXTURE_PIXEL_SIZE * edge_width;

	float max_alpha = center_alpha;
	float min_alpha = center_alpha;
	float sample_alpha;

	sample_alpha = texture(TEXTURE, UV + vec2(px.x, 0.0)).a;
	max_alpha = max(max_alpha, sample_alpha);
	min_alpha = min(min_alpha, sample_alpha);
	sample_alpha = texture(TEXTURE, UV + vec2(-px.x, 0.0)).a;
	max_alpha = max(max_alpha, sample_alpha);
	min_alpha = min(min_alpha, sample_alpha);
	sample_alpha = texture(TEXTURE, UV + vec2(0.0, px.y)).a;
	max_alpha = max(max_alpha, sample_alpha);
	min_alpha = min(min_alpha, sample_alpha);
	sample_alpha = texture(TEXTURE, UV + vec2(0.0, -px.y)).a;
	max_alpha = max(max_alpha, sample_alpha);
	min_alpha = min(min_alpha, sample_alpha);
	sample_alpha = texture(TEXTURE, UV + vec2(px.x, px.y)).a;
	max_alpha = max(max_alpha, sample_alpha);
	min_alpha = min(min_alpha, sample_alpha);
	sample_alpha = texture(TEXTURE, UV + vec2(-px.x, px.y)).a;
	max_alpha = max(max_alpha, sample_alpha);
	min_alpha = min(min_alpha, sample_alpha);
	sample_alpha = texture(TEXTURE, UV + vec2(px.x, -px.y)).a;
	max_alpha = max(max_alpha, sample_alpha);
	min_alpha = min(min_alpha, sample_alpha);
	sample_alpha = texture(TEXTURE, UV + vec2(-px.x, -px.y)).a;
	max_alpha = max(max_alpha, sample_alpha);
	min_alpha = min(min_alpha, sample_alpha);

	float alpha_edge = smoothstep(0.04, 0.30, max_alpha - min_alpha);
	float outer_edge = smoothstep(0.02, 0.45, max_alpha) * (1.0 - smoothstep(0.02, 0.34, center_alpha));
	float rim = max(alpha_edge * smoothstep(0.03, 0.35, center_alpha), outer_edge);

	float sweep_position = sweep_progress * 2.25 - 0.55;
	float sweep_line = UV.x + UV.y - sweep_position;
	float sweep = smoothstep(-sweep_width, 0.0, sweep_line) * (1.0 - smoothstep(0.0, sweep_width, sweep_line));
	sweep *= smoothstep(0.08, 0.55, center_alpha);

	float soft_pulse = 0.88 + sin(TIME * 3.4) * 0.12;
	float alpha = rim * strength * soft_pulse;
	alpha += sweep * strength * 0.78;
	alpha += flash_strength * max(rim * 1.25, center_alpha * 0.32);
	alpha = clamp(alpha, 0.0, 1.0);

	vec3 color = glow_color.rgb;
	vec3 sweep_color = mix(color, vec3(1.0, 0.97, 0.82), 0.55);
	vec3 flash_color = mix(sweep_color, vec3(1.0, 1.0, 0.94), clamp(flash_strength, 0.0, 1.0));
	vec3 final_color = mix(color, sweep_color, sweep * 0.85);
	final_color = mix(final_color, flash_color, clamp(flash_strength * 0.65, 0.0, 1.0));
	COLOR = vec4(final_color, alpha * glow_color.a);
}
