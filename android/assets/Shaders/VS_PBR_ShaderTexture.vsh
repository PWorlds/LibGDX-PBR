//
//  PBR_ShaderTexture.vsh
//

#ifdef GL_ES
precision highp float;
#endif

attribute vec3    a_position;
attribute vec3    a_normal;
attribute vec2    a_texCoord0;

varying vec3    eye;
varying vec3    normal;
varying vec3    halfvecLight0;

uniform mat4      u_projTrans;
uniform mat4      u_worldTrans;

uniform vec3      vLight0;

varying vec2 texCoord;
varying vec3 worldNormal;

void main(void)
{
    vec4 p = vec4(a_position,1);
    gl_Position = u_projTrans * (u_worldTrans * p);

    texCoord = mod(a_texCoord0,1.0);
    worldNormal = vec3(mat3(u_projTrans[0].xyz, u_projTrans[1].xyz, u_projTrans[2].xyz) * a_normal);

    normal = worldNormal;
    eye = -(u_projTrans * p).xyz;
    halfvecLight0 = normalize(-vLight0) + normalize(eye);
}
