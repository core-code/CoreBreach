

varying_frag vec2 texcoord;

uniform sampler1D palette;
uniform sampler2D pattern;
uniform float offset;

void main()
{
	vec4 color;
	color = texture2D(pattern, texcoord);
	color = texture1D(palette, (color.r+offset));
//	color.a = 1.0;
	color = clamp(color, 0.0, 1.0);

    float gr = dot(vec3(0.222, 0.707, 0.071),  color.rgb);
    color = vec4(gr, gr, gr, 1.0) * 0.8 + color * (1.0 - 0.8);

	fragColor = color;
}
