#include "common.glsl"
// Monochrome phosphor terminal. variant: 0 = green, 1 = amber.

void main() {
    vec2 uv = warp(qt_TexCoord0, curvature);
    float inside = tubeMask(uv);
    if (inside <= 0.0) {
        fragColor = vec4(0.0, 0.0, 0.0, 1.0) * qt_Opacity;
        return;
    }
    vec2 px = 1.0 / srcSize;
    vec2 pix = floor(uv * srcSize);
    float l = luma(fetch(uv));
    float glow = (luma(fetch(uv + vec2(px.x * 2.0, 0.0))) + luma(fetch(uv - vec2(px.x * 2.0, 0.0)))
                + luma(fetch(uv + vec2(0.0, px.y * 2.0))) + luma(fetch(uv - vec2(0.0, px.y * 2.0)))) * 0.25;
    float q = floor(clamp(l * 1.15 + (bayer4(pix) - 0.5) * 0.22, 0.0, 1.0) * 5.0 + 0.5) / 5.0;

    vec3 tint = mix(vec3(0.25, 1.0, 0.45), vec3(1.0, 0.68, 0.18), clamp(variant, 0.0, 1.0));
    vec3 col = tint * (q * 0.95 + glow * 0.3) + tint * 0.025;
    float line = fract(uv.y * srcSize.y) - 0.5;
    col *= mix(1.0, 0.55 + 0.75 * exp(-(line * line) / 0.06), scanlinesVisible());
    col *= 0.97 + 0.03 * sin(time * 120.0 + uv.y * 3.0);
    col += (hash12(gl_FragCoord.xy + fract(time * 5.0) * 197.0) - 0.5) * 0.04 * tint;
    float vig = pow(max(16.0 * uv.x * uv.y * (1.0 - uv.x) * (1.0 - uv.y), 0.0), 0.25);
    col *= vig;

    vec3 plain = fetch(uv);
    fragColor = vec4(mix(plain, clamp(col, 0.0, 1.0), strength) * inside, 1.0) * qt_Opacity;
}
