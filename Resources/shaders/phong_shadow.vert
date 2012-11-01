

#ifdef SHADOW
	#if defined(S_2)
		uniform mat4 shadowMatrix[2];
		varying_vert vec4 shadowTexCoord[2];
	#elif defined(S_1)
        uniform mat4 shadowMatrix[1];
		varying_vert vec4 shadowTexCoord[1];
	#else
		#error fuck
	#endif
#endif




attribute vec4 vertex;
attribute vec3 normal;
attribute vec2 texcoord0;

uniform mat4 modelViewProjectionMatrix;
uniform mat4 modelViewMatrix;
uniform mat3 normalMatrix;

varying_vert vec3 position;

#ifdef TEXTURING
    varying_vert vec2 texcoord;
#endif
#ifdef LIGHT
    varying_vert vec3 normalVector;
#endif

void main(void)
{
	position	= vec3(modelViewMatrix * vertex);
#ifdef LIGHT
	normalVector = normalize(normalMatrix * normal);
#endif

#ifdef TEXTURING
    texcoord    = texcoord0.xy;
#endif

    gl_Position = modelViewProjectionMatrix * vertex;


#ifdef SHADOW
	#if defined(S_2)
		shadowTexCoord[0] = shadowMatrix[0] * modelViewMatrix * vertex;
		shadowTexCoord[1] = shadowMatrix[1] * modelViewMatrix * vertex;
	#elif defined(S_1)
		shadowTexCoord[0] = shadowMatrix[0] * modelViewMatrix * vertex;
	#else
		#error fuck
	#endif
#endif
}