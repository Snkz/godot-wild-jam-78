shader_type canvas_item;

uniform vec2 holeCenter;
uniform float holeRadius;

varying vec2 p;

void vertex(){
	p = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0) ).xy;
}

void fragment(){
	COLOR.a = step(holeRadius, length(p - holeCenter));
}