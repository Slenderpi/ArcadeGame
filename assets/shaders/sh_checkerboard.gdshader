shader_type spatial;

/**
Size of checkers.
Checkers are uniform in size, regardless of the size and scale of the mesh.
The position of the checkers also ignores the position and rotation of the mesh.
 */
uniform float checker_size : hint_range(0.1, 10) = 1.0;
/** Color for half of the checkers. */
uniform vec4 color1 : source_color = vec4(1.0, 1.0, 1.0, 1.0);
/** Color for other half of the checkers. */
uniform vec4 color2 : source_color = vec4(0.66, 0.66, 0.66, 1.0);

varying vec3 world_pos;

void vertex() {
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 grid = floor(world_pos.xz / checker_size);
    float checker = mod(grid.x + grid.y, 2.0);
    ALBEDO = mix(color1.rgb, color2.rgb, checker);
}