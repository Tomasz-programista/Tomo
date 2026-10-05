#include "common.glsl"
// A pea-green handheld game console LCD: 4 shades, visible pixel grid, pixel shadows.

vec3 shade(float i) {
    if (i < 0.5) return vec3(0.06, 0.22, 0.06);
    if (i < 1.5) return vec3(0.19, 0.38, 0.19);
    if (i < 2.5) return vec3(0.55, 0.67, 0.06);
    return vec3(0.61, 0.74, 0.06);
}

float level(vec2 pix) {
    float l = luma(fetch((pix + 0.5) / srcSize));
    l = clamp((l - 0.04) * 1.2, 0.0, 1.0);
    return clamp(floor(l * 3.0 + 0.5 + (bayer4(pix) - 0.5) * 0.7), 0.0, 3.0);
}

void main() {
    vec2 uv = qt_TexCoord0;
    vec2 pos = uv * srcSize;
    vec2 pix = floor(pos);
    vec2 cell = fract(pos);
    vec3 lcdBack = vec3(0.66, 0.75, 0.12);

    float cellPx = outSize.x / max(srcSize.x, 1.0);
    float grid = clamp((cellPx - 2.0) / 2.0, 0.0, 1.0);
    float gap = smoothstep(0.0, 0.1, cell.x) * smoothstep(1.0, 0.9, cell.x)
              * smoothstep(0.0, 0.1, cell.y) * smoothstep(1.0, 0.9, cell.y);

    // Dark pixels cast a soft shadow down-right onto the LCD back.
    float shadowLevel = level(floor(pos - vec2(0.25, 0.3)));
    vec3 back = lcdBack * mix(0.82, 1.0, shadowLevel / 3.0);
    vec3 col = mix(back, shade(level(pix)), mix(1.0, gap, grid));

    vec3 plain = fetch(uv);
    fragColor = vec4(mix(plain, col, strength), 1.0) * qt_Opacity;
}
