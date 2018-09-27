shader_type spatial;
render_mode depth_test_disable, depth_draw_never, unshaded, cull_disabled;

uniform vec3 linear_velocity; 
uniform vec3 angular_velocity; //rads
uniform int iteration_count : hint_range(2, 50);
uniform float intensity : hint_range(0, 1);


void fragment()
{ 
	float depth = texture(DEPTH_TEXTURE, SCREEN_UV).r;
	
	//Turn the current pixel from ndc to world coordinates
	vec3 pixel_pos_ndc = vec3(SCREEN_UV*2.0-1.0, depth*2.0-1.0); 
    vec4 pixel_pos_clip = INV_PROJECTION_MATRIX * vec4(pixel_pos_ndc,1.0);
    vec3 pixel_pos_cam = pixel_pos_clip.xyz / pixel_pos_clip.w;
	vec3 pixel_pos_world = (inverse(INV_CAMERA_MATRIX) * vec4(pixel_pos_cam, 1.0)).xyz;
	
	//Calculate total velocity which combines linear velocity and angular velocity
	vec3 cam_pos = inverse(INV_CAMERA_MATRIX)[3].xyz; //Correct
	vec3 r = pixel_pos_world - cam_pos;
	vec3 total_velocity = linear_velocity + cross(angular_velocity, r);
	
	//Offset the world pos by the total velocity, then project back to ndc coordinates
	vec3 pixel_prevpos_world = pixel_pos_world - total_velocity;
	vec3 pixel_prevpos_cam =  ((INV_CAMERA_MATRIX) * vec4(pixel_prevpos_world, 1.0)).xyz;
	vec4 pixel_prevpos_clip =  PROJECTION_MATRIX * vec4(pixel_prevpos_cam, 1.0);
	vec3 pixel_prevpos_ndc = pixel_prevpos_clip.xyz / pixel_prevpos_clip.w;
	
	//Calculate how much the pixel moved in ndc space
	vec2 pixel_diff_ndc = pixel_prevpos_ndc.xy - pixel_pos_ndc.xy; 
	
	vec3 col = vec3(0.0);
	float counter = 0.0;
	for (int i = 0; i < iteration_count; i++)
	{
		vec2 offset = pixel_diff_ndc * (float(i) / float(iteration_count) - 0.5) * intensity; 
		col += textureLod(SCREEN_TEXTURE, SCREEN_UV + offset,0.0).rgb;
		counter++;
	}
	ALBEDO = col / counter;
}