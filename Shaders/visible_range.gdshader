shader_type canvas_item;

uniform float radius = 100.0;
uniform vec4 ring_color : source_color;
uniform float fade_alpha = 1.0;

varying vec2 local_position;

void vertex() {
	local_position = VERTEX;
}

void fragment() {
	float dist = length(local_position);

	float gradient = smoothstep(0.0, radius, dist);
	float fill_alpha = mix(0.4, 0.1, gradient);

	COLOR = vec4(
		ring_color.rgb,
		fill_alpha * fade_alpha
	);
}
