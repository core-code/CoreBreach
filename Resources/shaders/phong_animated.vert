

uniform mat4 modelViewProjectionMatrix;
uniform mat4 modelViewMatrix;
uniform mat3 normalMatrix;

attribute vec4 vertex;
attribute vec2 texcoord0;
attribute vec3 normal;

varying_vert vec2 texcoord;
varying_vert vec3 position;
varying_vert vec3 normalVector;

void main( void )
{

	normalVector = normalize(normalMatrix * normal);
	position	= vec3(modelViewMatrix * vertex);

    texcoord    = texcoord0.xy;

    gl_Position = modelViewProjectionMatrix * vertex;
}

