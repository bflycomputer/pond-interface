#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 backgroundRect;
};
layout(binding = 1) uniform sampler2D inkTexture;
layout(binding = 2) uniform sampler2D backgroundTexture;
// W3C soft-light with a white source: D(Cb), composited by glyph coverage.
void main() {
    float coverage = texture(inkTexture, qt_TexCoord0).a;
    vec4 bg = texture(backgroundTexture, backgroundRect.xy + qt_TexCoord0 * backgroundRect.zw);
    vec3 b = bg.rgb / max(bg.a, 0.00001);
    vec3 low = ((16.0 * b - 12.0) * b + 4.0) * b;
    vec3 light = mix(low, sqrt(max(b, vec3(0.0))), step(vec3(0.25), b));
    float a = coverage * qt_Opacity;
    fragColor = vec4(light * a, a);
}
