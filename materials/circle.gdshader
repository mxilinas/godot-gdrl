shader_type canvas_item;

uniform vec4 color : source_color;

void fragment() {
	vec2 center = vec2(0.5, 0.5);
	float dist = length(center - UV);
	dist = step(dist, 0.5);
	COLOR = vec4(dist) * color;
}