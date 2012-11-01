

varying_frag vec2 texcoord;

uniform sampler2D colorTexture;
//uniform sampler2D depthTexture;


uniform vec2 pixelSize;

uniform int grayEnabled;
uniform float grayIntensity;

uniform int radialblurEnabled;
const int radialblurSamples = 10;
uniform float radialBlur;
uniform float radialBright;


uniform int thermalEnabled;
uniform float thermalIntensity;

uniform int glassEnabled;
uniform float glassIntensity;

const float rnd_scale = 5.1;
const vec2 v1 = vec2(92.,80.);
const vec2 v2 = vec2(41.,62.);

float rand(vec2 co)
{
    return fract(sin(dot(co.xy ,v1)) + cos(dot(co.xy ,v2)) * rnd_scale);
}

void main()
{
    vec4 color;

    if (glassEnabled > 0)
    {
        // credits to Agnius Vasiliauskas
        vec2 rnd = vec2(rand(texcoord), rand(texcoord.yx));
        color = texture2D(colorTexture, texcoord + rnd * glassIntensity * 0.05);
        color *= vec4(1.0 + glassIntensity, 1.0 - glassIntensity, 1.0 - glassIntensity, 1.0);
    }
    else if (radialblurEnabled > 0)
    {
        // credits to markus@delphigl
        vec4 SumColor = vec4(0.0, 0.0, 0.0, 0.0);
        vec2 tc = texcoord + (pixelSize * 0.5 - vec2(0.5, 0.5));

        for (int i = 0; i < radialblurSamples; i++)
        {
            float scale = 1.0 - radialBlur * (float(i) / (float(radialblurSamples) - 1.0));
            SumColor += texture2D(colorTexture, tc * scale + vec2(0.5, 0.5));
        }


        color = SumColor / float(radialblurSamples) * radialBright;
    }
    else
        color = texture2D(colorTexture, texcoord);



    if (thermalEnabled > 0)
    {
        // credits to Agnius Vasiliauskas
        vec3 colors[3];
        colors[0] = vec3(0.,0.,1.);
        colors[1] = vec3(1.,1.,0.);
        colors[2] = vec3(1.,0.,0.);
        float lum = (color.r+color.g+color.b)/3.;
        vec3 tc;
        if (lum < 0.5)
            tc = mix(colors[0],colors[1],(lum-float(0)*0.5)/0.5);
        else
            tc = mix(colors[1],colors[2],(lum-float(1)*0.5)/0.5);
        color = vec4(tc, 1.0) * thermalIntensity + color * (1.0 - thermalIntensity);
    }

    if (grayEnabled > 0)
    {
        float gr = dot(vec3(0.222, 0.707, 0.071),  color.rgb);
        color = vec4(gr, gr, gr, 1.0) * grayIntensity + color * (1.0 - grayIntensity);
    }


    fragColor = color;
//    gl_FragDepth = texture2D(depthTexture, texcoord).x;
}