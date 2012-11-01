

uniform mat4 modelViewProjectionMatrix;

attribute vec4 vertex;
attribute vec2 texcoord0;

varying_vert vec2 texcoord;


uniform vec4 qdPosition;
varying_vert vec4 qdAffected;



void main(void)
{
    gl_Position = modelViewProjectionMatrix * vertex;
    texcoord    = texcoord0.xy;
    


    float distanceToCenter = distance(vec3(vertex), vec3(qdPosition));
    float verticalAddition = 30.0 - distanceToCenter;
    float blueAddition = 1.0 - (distanceToCenter / 40.0);
    float step = step(-25.0, -distanceToCenter);
    
    gl_Position.y += verticalAddition * step;
    qdAffected = vec4(0.0, 0.0, 0.0 + (blueAddition * step), 0.0);
}
