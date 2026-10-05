#version 440
// Shared by every screen shader (pasted in by tools/build_shaders.py).

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;       // seconds
    float curvature;  // 0 = flat glass
    float strength;   // 0..1 how strong the effect is
    float variant;    // per-shader option (e.g. phosphor colour)
    vec2 srcSize;     // emulated signal resolution in pixels
    vec2 outSize;     // size of the screen on the monitor, in device pixels
};

layout(binding = 1) uniform sampler2D source;   // the (downscaled) picture
layout(binding = 2) uniform sampler2D overlay;  // subtitles + on-screen display, premultiplied

float hash12(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

float luma(vec3 c) {
    return dot(c, vec3(0.299, 0.587, 0.114));
}

// Picture with subtitles / OSD composited on top.
vec3 fetch(vec2 uv) {
    vec3 v = texture(source, uv).rgb;
    vec4 o = texture(overlay, uv);
    return v * (1.0 - o.a) + o.rgb;
}

// Barrel distortion of a curved CRT tube.
vec2 warp(vec2 uv, float amount) {
    vec2 c = uv * 2.0 - 1.0;
    vec2 offset = abs(c.yx);
    c = c + c * offset * offset * amount;
    return c * 0.5 + 0.5;
}

// 1 inside the (slightly rounded) tube face, 0 outside.
float tubeMask(vec2 uv) {
    vec2 c = abs(uv * 2.0 - 1.0);
    float shape = pow(c.x, 16.0) + pow(c.y, 16.0);
    float aa = 24.0 / max(outSize.x, 1.0);
    return 1.0 - smoothstep(1.0 - aa, 1.0, shape);
}

float bayer4(vec2 p) {
    int x = int(mod(p.x, 4.0));
    int y = int(mod(p.y, 4.0));
    int i = y * 4 + x;
    float m = 0.0;
    if (i == 0) m = 0.0;   else if (i == 1) m = 8.0;   else if (i == 2) m = 2.0;   else if (i == 3) m = 10.0;
    else if (i == 4) m = 12.0; else if (i == 5) m = 4.0;  else if (i == 6) m = 14.0; else if (i == 7) m = 6.0;
    else if (i == 8) m = 3.0;  else if (i == 9) m = 11.0; else if (i == 10) m = 1.0; else if (i == 11) m = 9.0;
    else if (i == 12) m = 15.0; else if (i == 13) m = 7.0; else if (i == 14) m = 13.0; else m = 5.0;
    return (m + 0.5) / 16.0;
}

// Scanline visibility fades out when the window is too small to show them without moire.
float scanlinesVisible() {
    return clamp((outSize.y / max(srcSize.y, 1.0) - 1.6) / 1.4, 0.0, 1.0);
}
