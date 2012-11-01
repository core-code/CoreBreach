

uniform vec3 light1position;
uniform vec4 light1product_ambient;
uniform vec4 light1product_diffuse;
uniform vec4 light1product_specular;
uniform vec4 lightmodelproduct_scenecolor;
uniform float material_shininess;


uniform sampler2D texUnit;
uniform vec4 replacementColor;

varying_frag vec3 normalVector;
varying_frag vec3 position;

varying_frag vec2 texcoord;


void main (void)
{
	vec3 eyeDir 	= normalize(-position); // camera is at (0,0,0) in ModelView space
	vec3 lightDir	= normalize(light1position - position);
	vec4 IAmbient	= light1product_ambient;
	vec4 IDiffuse	= light1product_diffuse * max(dot(normalVector, lightDir), 0.0);
    vec4 color      = vec4(lightmodelproduct_scenecolor + IAmbient + IDiffuse);
	vec3 Reflected	= normalize(reflect( -lightDir, normalVector));
    vec4 tex        = texture2D(texUnit, texcoord);
	color           += (light1product_specular * pow(max(dot(Reflected, eyeDir), 0.0), material_shininess));

    if (tex.r + tex.g + tex.b > 2.7)
        color       *= replacementColor;
    else
        color       *= tex;

	fragColor = color;
}

