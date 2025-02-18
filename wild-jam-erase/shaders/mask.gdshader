shader_type canvas_item;

uniform vec2 holeCenter;
uniform float holeRadius;

varying vec2 p;

// pseudo-random function based on coordinates
float random(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}

void vertex() {
    p = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	COLOR = tex_color;
	
	if (tex_color.a > 0.01) {
		float gridSize = 3.0;
		vec2 gridPos = floor(p / gridSize) * gridSize;
		float randOffset = random(gridPos) * gridSize * 20.0;
		float adjustedRadius = holeRadius + randOffset - gridSize * 1.0;
		float dist = clamp(length(gridPos - holeCenter), 0.0, length(gridPos - holeCenter));
		COLOR.a = step(adjustedRadius, dist);
	}   

}
