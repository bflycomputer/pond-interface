#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
} ubuf;
layout(binding = 1) uniform sampler2D source;

void main() {
    vec4 color = texture(source, qt_TexCoord0) * ubuf.qt_Opacity;
    float noise = fract(52.9829189 * fract(dot(gl_FragCoord.xy, vec2(.06711056, .00583715)))) - .5;
    // Keep dithered RGB within the premultiplied-alpha range.
    fragColor = vec4(clamp(color.rgb + noise / 255., vec3(0.), vec3(color.a)), color.a);
}
