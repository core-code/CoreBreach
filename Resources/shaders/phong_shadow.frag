

uniform vec4    color;



const vec2 sm_pcss_factor = vec2(10, 0.3);

#ifdef TEXTURING
uniform sampler2D texUnit;
varying_frag vec2 texcoord;
#endif

varying_frag vec3 position;
#ifdef LIGHT
varying_frag vec3 normalVector;

uniform vec4 	lightmodelproduct_scenecolor;
uniform float 	material_shininess;

uniform float 	light1linearattenuation;
uniform vec3 	light1position;
uniform vec4 	light1product_ambient;
uniform vec4 	light1product_diffuse;
uniform vec4 	light1product_specular;

uniform float 	light2linearattenuation;
uniform vec3 	light2position;
uniform vec4 	light2product_ambient;
uniform vec4 	light2product_diffuse;
uniform vec4 	light2product_specular;
#endif

#ifdef COREMODE
uniform float coreIntensity;
#endif

#ifdef SHADOW
#ifdef S_2
#ifdef PCSS
uniform sampler2D shadowMap[2];
#else
uniform sampler2DShadow shadowMap[2];
#endif
varying_frag vec4 shadowTexCoord[2];
#else
#ifdef S_1
#ifdef PCSS
uniform sampler2D shadowMap[1];
#else
uniform sampler2DShadow shadowMap[1];
#endif
varying_frag vec4 shadowTexCoord[1];
#else
#error fuck
#endif
#endif

vec2 poissonDisk[16];

#if defined(PCSS)
// credits to nvidia for the pcss code

#define    BLOCKER_SEARCH_NUM_SAMPLES 16
#define    PCF_NUM_SAMPLES 16
#define    NEAR_PLANE 2.5
#define    LIGHT_WORLD_SIZE .05
#define    LIGHT_FRUSTUM_WIDTH 3.75
// Assuming that LIGHT_FRUSTUM_WIDTH == LIGHT_FRUSTUM_HEIGHT
#define LIGHT_SIZE_UV (LIGHT_WORLD_SIZE / LIGHT_FRUSTUM_WIDTH)

float unpackFloatFromVec4i(const vec4 value)
{
	const vec4 bitSh = vec4(1.0 / (256.0 * 256.0 * 256.0), 1.0 / (256.0 * 256.0), 1.0 / 256.0, 1.0);
	return(dot(value, bitSh));
}

float unpackFloatFromVec3i(const vec3 value)
{
	const vec3 bitSh = vec3(1.0 / (256.0 * 256.0), 1.0 / 256.0, 1.0);
	return(dot(value, bitSh));
}

float unpackFloatFromVec2i(const vec2 value)
{
	const vec2 unpack_constants = vec2(1.0/256.0, 1.0);
	return dot(unpack_constants,value);
}

float shadow_comparison(sampler2D tu, vec2 uv, float comparison)
{
	float lookupvalue = unpackFloatFromVec3i(texture2D(tu, uv).rgb);
	return lookupvalue > comparison ? 1.0 : 0.0;
}

float PenumbraSize(float zReceiver, float zBlocker) //Parallel plane estimation
{
	return (zReceiver - zBlocker) / zBlocker;
}

void FindBlocker(in vec2 poissonDisk[16], in sampler2D tu,
				 out float avgBlockerDepth,
				 out float numBlockers,
				 vec2 uv, float zReceiver )
{
	//This uses similar triangles to compute what
	//area of the shadow map we should search
	float searchWidth = LIGHT_SIZE_UV * (zReceiver - NEAR_PLANE) / zReceiver;
	//float searchWidth = 10.0/2048.0;
	//float searchWidth = LIGHT_SIZE_UV;
	float blockerSum = 0.0;
	numBlockers = 0.0;
	for( int i = 0; i < BLOCKER_SEARCH_NUM_SAMPLES; ++i )
	{
		//float shadowMapDepth = tDepthMap.SampleLevel(PointSampler,uv + poissonDisk[i] * searchWidth,0);
		float shadowMapDepth = unpackFloatFromVec3i(texture2D(tu, uv + poissonDisk[i] * searchWidth).rgb);
		if ( shadowMapDepth < zReceiver ) {
			blockerSum += shadowMapDepth;
			numBlockers++;
		}
	}
	avgBlockerDepth = blockerSum / numBlockers;
}

float PCF_Filter( in vec2 poissonDisk[16], in sampler2D tu, in vec2 uv, in float zReceiver, in float filterRadiusUV )
{
	float sum = 0.0;
	for ( int i = 0; i < PCF_NUM_SAMPLES; ++i )
	{
		vec2 offset = poissonDisk[i] * filterRadiusUV;
		sum += shadow_comparison(tu, uv + offset, zReceiver);
	}
	return sum / float(PCF_NUM_SAMPLES);
	//vec2 offset = vec2(1.0/2048.0,1.0/2048.0);
	//vec2 offset = vec2(0.0,0.0);
	//return unpackFloatFromVec4i(texture2D(tu, uv + offset)) >= zReceiver ? 1.0 : 0.0;
	//return unpackFloatFromVec3i(texture2D(tu, uv + offset).rgb) > zReceiver + 1.0/(256.0*256.0) ? 1.0 : 0.0;
	//return unpackFloatFromVec3i(texture2D(tu, uv + offset).rgb) > zReceiver + 1.0/(256.0*4.0) ? 1.0 : 0.0;
	//return unpackFloatFromVec2i(texture2D(tu, uv + offset).rg) >= zReceiver ? 1.0 : 0.0;
}

float PCSSlookup(vec4 coord, sampler2D sm)
{
	poissonDisk[1] = vec2( 0.94558609, -0.76890725 );
	poissonDisk[2] = vec2( -0.094184101, -0.92938870 );
	poissonDisk[3] = vec2( 0.34495938, 0.29387760 );
	poissonDisk[4] = vec2( -0.91588581, 0.45771432 );
	poissonDisk[5] = vec2( -0.81544232, -0.87912464 );
	poissonDisk[6] = vec2( -0.38277543, 0.27676845 );
	poissonDisk[7] = vec2( 0.97484398, 0.75648379 );
	poissonDisk[8] = vec2( 0.44323325, -0.97511554 );
	poissonDisk[9] = vec2( 0.53742981, -0.47373420 );
	poissonDisk[10] = vec2( -0.26496911, -0.41893023 );
	poissonDisk[11] = vec2( 0.79197514, 0.19090188 );
	poissonDisk[12] = vec2( -0.24188840, 0.99706507 );
	poissonDisk[13] = vec2( -0.81409955, 0.91437590 );
	poissonDisk[14] = vec2( 0.19984126, 0.78641367 );
	poissonDisk[15] = vec2( 0.14383161, -0.14100790 );

	vec2 uv = coord.xy / coord.w;

	if (uv.x > 1.0 || uv.y > 1.0 || uv.x < 0.0 || uv.y < 0.0)
        return 1.0;

	float zReceiver = coord.z / coord.w;
	// STEP 1: blocker search
	float avgBlockerDepth = 0.0;
	float numBlockers = 0.0;
	FindBlocker( poissonDisk, sm, avgBlockerDepth, numBlockers, uv, zReceiver );
	if( numBlockers < 1.0 ) //There are no occluders so early out (this saves filtering)
	return 1.0;

	// STEP 2: penumbra size
	float penumbraRatio = PenumbraSize(zReceiver, avgBlockerDepth);
	//float filterRadiusUV = penumbraRatio * LIGHT_SIZE_UV * NEAR_PLANE / zReceiver;
		float filterRadiusUV = clamp(penumbraRatio*0.05,0.0,20.0/2048.0);
	//	float filterRadiusUV = penumbraRatio*(256.0/2048.0);
	// STEP 3: filtering
	float bla = PCF_Filter( poissonDisk, sm, uv, zReceiver, filterRadiusUV );
	return bla;
}
#else

float lookup(vec2 xy)
{
#ifdef S_2
    float depth = 0.0;

	float v1 = shadow2DProj(shadowMap[0], shadowTexCoord[0] + vec4(xy.x, xy.y, 0, 0) * sm_pcss_factor.x).x;
    float v2 = shadow2DProj(shadowMap[1], shadowTexCoord[1] + vec4(xy.x, xy.y, 0, 0) * sm_pcss_factor.y).x;

    return min(v1,v2) * 0.5 + 0.5;
#else
	//	return (shadow2DProj(shadowMap[0], shadowTexCoord[0] + vec4(xy.x, xy.y, 0, 0) * 0.3).x != 1.0) ? 0.5 : 1.0;
//    vec2 uv = shadowTexCoord[0].xy / shadowTexCoord[0].w;
//
//	if (uv.x > 1.0 || uv.y > 1.0 || uv.x < 0.0 || uv.y < 0.0)
//        return 1.0;
#if __VERSION__ >= 140
	return textureProj(shadowMap[0], shadowTexCoord[0] + vec4(xy.x, xy.y, 0, 0) * sm_pcss_factor.x) * 0.5 + 0.5;
#else
	return shadow2DProj(shadowMap[0], shadowTexCoord[0] + vec4(xy.x, xy.y, 0, 0) * sm_pcss_factor.x).x * 0.5 + 0.5;
#endif
#endif
}
#endif

#endif

void main (void)
{
#ifdef LIGHT
	vec3 eyeDir 			= normalize(-position); // camera is at (0,0,0) in ModelView space

	float att1 = 1.0/(1.0 +  light1linearattenuation * distance(light1position, position));
    float att2 = 1.0/(1.0 +  light2linearattenuation * distance(light2position, position));
	vec3 lightDir1	= normalize(light1position - position);
	vec3 lightDir2	= normalize(light2position - position);


	vec4 IAmbient1	= light1product_ambient * att1;
	vec4 IAmbient2	= light2product_ambient * att2;
	vec4 IDiffuse1	= light1product_diffuse * max(dot(normalVector, lightDir1), 0.0) * att1;
	vec4 IDiffuse2	= light2product_diffuse * max(dot(normalVector, lightDir2), 0.0) * att2;

#ifdef ADDITIVE_LIGHT
	vec4 ourcolor = vec4(IAmbient1 + IAmbient2 + IDiffuse1 + IDiffuse2);
#else
    vec4 ourcolor = vec4(lightmodelproduct_scenecolor + IAmbient1 + IAmbient2 + IDiffuse1 + IDiffuse2);
#endif


#ifdef TEXTURING
#ifdef ADDITIVE_LIGHT
    ourcolor = texture2D(texUnit, texcoord) + ourcolor;
#else

	ourcolor *= texture2D(texUnit, texcoord);
#endif

#endif

#ifndef NO_SPECULAR
	vec3 Reflected1	= normalize(reflect( -lightDir1, normalVector));
	vec3 Reflected2	= normalize(reflect( -lightDir2, normalVector));
	ourcolor += (light1product_specular * pow(max(dot(Reflected1, eyeDir), 0.0), material_shininess)) * att1;
	ourcolor += (light2product_specular * pow(max(dot(Reflected2, eyeDir), 0.0), material_shininess)) * att2;
#endif

#else

    vec4 ourcolor		= color;

#ifdef TEXTURING
	ourcolor *= texture2D(texUnit, texcoord);
#endif

#endif


#ifdef SHADOW
#if	defined(PCF_4)
	float sum = 0.0;
	vec2 o = vec2(0.0, 0.0); //mod(floor(gl_FragCoord.xy), 2.0);
	sum += lookup(vec2(-1.5, 1.5) + o);
	sum += lookup(vec2( 0.5, 1.5) + o);
	sum += lookup(vec2(-1.5, -0.5) + o);
	sum += lookup(vec2( 0.5, -0.5) + o);
	fragColor = vec4(sum * 0.25 * ourcolor.rgb, ourcolor.a);

#elif defined (PCF_16)
	poissonDisk[1] = vec2( 0.94558609, -0.76890725 );
	poissonDisk[2] = vec2( -0.094184101, -0.92938870 );
	poissonDisk[3] = vec2( 0.34495938, 0.29387760 );
	poissonDisk[4] = vec2( -0.91588581, 0.45771432 );
	poissonDisk[5] = vec2( -0.81544232, -0.87912464 );
	poissonDisk[6] = vec2( -0.38277543, 0.27676845 );
	poissonDisk[7] = vec2( 0.97484398, 0.75648379 );
	poissonDisk[8] = vec2( 0.44323325, -0.97511554 );
	poissonDisk[9] = vec2( 0.53742981, -0.47373420 );
	poissonDisk[10] = vec2( -0.26496911, -0.41893023 );
	poissonDisk[11] = vec2( 0.79197514, 0.19090188 );
	poissonDisk[12] = vec2( -0.24188840, 0.99706507 );
	poissonDisk[13] = vec2( -0.81409955, 0.91437590 );
	poissonDisk[14] = vec2( 0.19984126, 0.78641367 );
	poissonDisk[15] = vec2( 0.14383161, -0.14100790 );

	//	float i, v, sum = 0.0;
	//	for (i = -1.5; i <= 1.5; i+=1.0)
	//		for (v = -1.5; v <= 1.5; v+=1.0)
	//			sum += lookup(vec2(i, v));
	//
	//	fragColor = vec4(sum * 0.0625 * ourcolor.rgb, ourcolor.a);
	float sum = 0.0;
	for (int i = 0; i < 16; i++)
        sum += lookup(poissonDisk[i] * 3.0);

	fragColor = vec4(sum * 0.0625 * ourcolor.rgb, ourcolor.a);
#elif defined(PCSS)

	float shadowValue = PCSSlookup(shadowTexCoord[0], shadowMap[0]);
	fragColor = vec4(shadowValue * ourcolor.rgb, ourcolor.a);

#else
	fragColor = vec4(lookup(vec2(0.0,0.0)) * ourcolor.rgb, ourcolor.a);
	//fragColor.xy = shadow2DProj(shadowMap[0], shadowTexCoord[0]).xy;
#endif


    vec2 uv = shadowTexCoord[0].xy / shadowTexCoord[0].w;

//    if (uv.x > 1.0 || uv.y > 1.0 || uv.x < 0.0 || uv.y < 0.0)
//         fragColor = fragColor + vec4(0.3, 0.3, 0.3, 1.0);
#else
	fragColor = ourcolor;
#endif
	//fragColor = (vec4(3.0, 3.0, 3.0, 3.0) + ourcolor) / 4.0;

#ifdef COREMODE
    float Z =  -position.z;
    vec4 core = vec4(   1.0 - Z / 300.0,
                        1.0 - Z / 400.0,
                        1.0 - Z / 300.0,
                        1.0)
                + ourcolor * 0.1;

#ifdef LIGHT
    core += vec4(1.0 - normalVector.y, 0.0, 0.0, 0.0);
#endif

    fragColor = core * coreIntensity + ourcolor * (1.0 - coreIntensity);
#endif

    #ifdef LIGHT
//	float att1_ = 1.0/(1.0 +  light1linearattenuation * distance(light1position, position));
  //  float att2_ = 1.0/(1.0 +  light2linearattenuation * distance(light2position, position));
//    fragColor.r = light1position.x;
//    fragColor.g = light2position.x;
//    fragColor.b = 0.0;
//    fragColor.r = att2_;
//
//    fragColor.g = light2linearattenuation / 100.0;
//
//    fragColor.b = 0.0;
   // fragColor.r = abs(light2position.x);
   //     fragColor.g = abs(light2position.y);
    //    fragColor.b = abs(light2position.z);
    //fragColor.rgb = -(light2position) / 100.0;
    #endif
}