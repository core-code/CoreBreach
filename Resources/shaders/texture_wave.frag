

varying_frag vec2 texcoord;

uniform sampler2D texUnit;

varying_frag vec4 qdAffected;

void main (void)
{
    if (length(qdAffected) > 0.0)
        fragColor = texture2D(texUnit, texcoord) + qdAffected;
    else
        discard;
}