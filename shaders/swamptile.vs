#define UV_FRAMES_PER_SIDE 8.0

#ifdef GL_ES
    precision highp float;
#endif

uniform mat4 MatrixP;
uniform mat4 MatrixV;
uniform mat4 MatrixW;

attribute vec3 POSITION;
attribute vec3 TEXCOORD0_LIFE;
attribute vec4 DIFFUSE;

varying vec3 PS_POS;
varying vec3 PS_TEXCOORD_LIFE;
varying vec4 PS_COLOUR;

float round(float x)
{
	if (fract(x) >= 0.5)
	{
		return floor(x) + 1.0;
	}
	else
	{
		return floor(x);
	}
}

void main()
{
	vec3 tile_center = vec3(
		floor(POSITION.y) - 1000.0,
		0.0,
		round((POSITION.y - floor(POSITION.y)) * 2001.0 - 1000.0)
	);

	vec3 object_pos = vec3(
		floor(POSITION.x) - 1000.0,
		0.0,
		floor(POSITION.z) - 1000.0
	);

	vec3 local_vert_pos = vec3(
		object_pos.x - tile_center.x,
		0.0,
		object_pos.z - tile_center.z
	);

	float vert1 = -round((POSITION.x - floor(POSITION.x)) * 33.0);
	float vert2 = -round((POSITION.z - floor(POSITION.z)) * 33.0);
	float vert3 = -TEXCOORD0_LIFE.x + 1.0;
	float vert4 = -TEXCOORD0_LIFE.y + 1.0;

	if (local_vert_pos.x < 0.0 && local_vert_pos.z < 0.0)
	{
		object_pos.y = vert1;
	}
	else if(local_vert_pos.x > 0.0 && local_vert_pos.z < 0.0)
	{
		object_pos.y = vert2;
	}
	else if(local_vert_pos.x < 0.0 && local_vert_pos.z > 0.0)
	{
		object_pos.y = vert3;
	}
	else if(local_vert_pos.x > 0.0 && local_vert_pos.z > 0.0)
	{
		object_pos.y = vert4;
	}
	else
	{
		object_pos.y = 0.0;
	}
	
	vec4 world_pos = MatrixW * vec4(object_pos, 1.0);

	mat4 mtxPV = MatrixP * MatrixV;
	gl_Position = mtxPV * world_pos;

	PS_POS.xyz = world_pos.xyz;

	vec2 uv_local = TEXCOORD0_LIFE.xy;
	float ix = floor(tile_center.x / 4.0 + 0.5) + 10000.0;
	float iz = floor(tile_center.z / 4.0 + 0.5) + 10000.0;
	
	// Use world-space repeating UVs mapped into the same atlas frame
	float TILE_REPEAT = 2.0; // adjust to make texture appear smaller/larger
	vec2 frameIndex = floor(TEXCOORD0_LIFE.xy * UV_FRAMES_PER_SIDE);
	vec2 uv_intracell = fract(world_pos.xz * TILE_REPEAT);
	vec2 uv_mapped = (frameIndex + uv_intracell) / UV_FRAMES_PER_SIDE;

	PS_TEXCOORD_LIFE.xy = uv_mapped;
	PS_TEXCOORD_LIFE.z = TEXCOORD0_LIFE.z;
	PS_COLOUR = DIFFUSE;
	PS_COLOUR.rgb *= PS_COLOUR.a;
}