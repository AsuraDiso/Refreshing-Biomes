uniform mat4 MatrixP;
uniform mat4 MatrixV;
uniform mat4 MatrixW;
uniform vec4 TIMEPARAMS;
// FIXED: Matched to vec4 to align perfectly with the Pixel Shader
uniform vec4 FLOAT_PARAMS; 

#ifdef GL_ES
precision mediump float;
#endif

attribute vec4 POS2D_UV;                  // x, y, u + samplerIndex * 2, v

varying vec3 PS_TEXCOORD;
varying vec3 PS_POS;

void main()
{
    vec3 POSITION = vec3(POS2D_UV.xy, 0);
    // Take the samplerIndex out of the U.
    float samplerIndex = floor(POS2D_UV.z / 2.0);
    vec3 TEXCOORD0 = vec3(POS2D_UV.z - 2.0 * samplerIndex, POS2D_UV.w, samplerIndex);

    vec3 object_pos = POSITION.xyz;
    vec4 world_pos = MatrixW * vec4(object_pos, 1.0);
    
    PS_POS = world_pos.xyz;

    // Apply the lowering/height adjustment ONLY for vertex screen positioning
    world_pos.y += FLOAT_PARAMS.z;
    
    //if(FLOAT_PARAMS.z < 0.0)
    //{
    //    float world_x = MatrixW[3][0];
    //    float world_z = MatrixW[3][2];
    //    world_pos.y += sin(world_x + world_z + TIMEPARAMS.x * 3.0) * 0.025;
    //}

    mat4 mtxPV = MatrixP * MatrixV;
    vec4 screen_pos = mtxPV * world_pos;
    gl_Position = screen_pos;

    PS_TEXCOORD = TEXCOORD0;
}