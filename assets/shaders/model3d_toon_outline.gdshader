shader_type canvas_item;

uniform bool enable_toon = true;
uniform float toon_steps : hint_range(1.0, 8.0) = 4.0;
uniform bool enable_outline = true;
uniform vec4 outline_color : source_color = vec4(0.06, 0.06, 0.08, 1.0);
uniform float outline_size : hint_range(0.0, 4.0) = 1.0;
uniform bool enable_pixelate = false;
uniform float pixel_size : hint_range(1.0, 8.0) = 2.0;
uniform float alpha_cutoff : hint_range(0.0, 1.0) = 0.03;
uniform sampler2D source_tex : source_color;
uniform vec2 source_pixel_size = vec2(0.00555556, 0.00555556);

vec2 pixelated_uv(vec2 uv) {
	if (!enable_pixelate || pixel_size <= 1.0) {
		return uv;
	}
	vec2 safe_pixel_size = max(source_pixel_size, vec2(0.000001));
	vec2 texture_size = vec2(1.0) / safe_pixel_size;
	vec2 block_size = vec2(pixel_size) / texture_size;
	return floor(uv / block_size + 0.5) * block_size;
}

vec2 clamp_uv(vec2 uv) {
	vec2 pad = max(source_pixel_size * 0.5, vec2(0.000001));
	return clamp(uv, pad, vec2(1.0) - pad);
}

float sample_alpha(vec2 uv) {
	return texture(source_tex, clamp_uv(uv)).a;
}

void fragment() {
	vec2 uv = clamp_uv(pixelated_uv(UV));
	vec4 col = texture(source_tex, uv);
	float src_alpha = col.a;

	if (enable_toon && src_alpha > alpha_cutoff) {
		float steps = max(toon_steps, 1.0);
		col.rgb = floor(max(col.rgb, vec3(0.0)) * steps + 0.5) / steps;
	}

	if (enable_outline && outline_size > 0.0) {
		vec2 texel = max(source_pixel_size, vec2(0.000001)) * outline_size;
		float edge_alpha = 0.0;
		edge_alpha = max(edge_alpha, sample_alpha(uv + vec2(texel.x, 0.0)));
		edge_alpha = max(edge_alpha, sample_alpha(uv + vec2(-texel.x, 0.0)));
		edge_alpha = max(edge_alpha, sample_alpha(uv + vec2(0.0, texel.y)));
		edge_alpha = max(edge_alpha, sample_alpha(uv + vec2(0.0, -texel.y)));
		edge_alpha = max(edge_alpha, sample_alpha(uv + vec2(texel.x, texel.y)));
		edge_alpha = max(edge_alpha, sample_alpha(uv + vec2(-texel.x, texel.y)));
		edge_alpha = max(edge_alpha, sample_alpha(uv + vec2(texel.x, -texel.y)));
		edge_alpha = max(edge_alpha, sample_alpha(uv + vec2(-texel.x, -texel.y)));

		if (src_alpha <= alpha_cutoff && edge_alpha > alpha_cutoff) {
			col = outline_color;
			col.a = outline_color.a * edge_alpha;
		}
	}

	if (col.a <= alpha_cutoff) {
		COLOR = vec4(0.0);
	} else {
		COLOR = col * COLOR;
	}
}
