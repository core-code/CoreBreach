

uniform mat4 modelViewProjectionMatrix;

attribute vec4 vertex;
attribute vec2 texcoord0;

varying_vert vec2 texcoord;


void main( void )
{
    gl_Position = modelViewProjectionMatrix * vertex;
    texcoord    = texcoord0.xy;
}