#include "common.glsl"
// A 16-colour Japanese home computer from the late 80s / 90s: ordered dither to a fixed palette.

vec3 palette(int i) {
    if (i == 0) return vec3(0.00, 0.00, 0.00);
    if (i == 1) return vec3(1.00, 1.00, 1.00);
    if (i == 2) return vec3(0.33, 0.33, 0.47);
    if (i == 3) return vec3(0.67, 0.67, 0.80);
    if (i == 4) return vec3(1.00, 0.87, 0.73);
    if (i == 5) return vec3(0.87, 0.60, 0.47);
    if (i == 6) return vec3(0.67, 0.20, 0.20);
    if (i == 7) return vec3(1.00, 0.33, 0.47);
    if (i == 8) return vec3(1.00, 0.60, 0.80);
    if (i == 9) return vec3(0.20, 0.33, 0.67);
    if (i == 10) return vec3(0.47, 0.73, 1.00);
    if (i == 11) return vec3(0.33, 0.20, 0.60);
    if (i == 12) return vec3(0.20, 0.67, 0.33);
    if (i == 13) return vec3(0.67, 0.87, 0.40);
    if (i == 14) return vec3(1.00, 0.87, 0.27);
    return vec3(0.53, 0.33, 0.20);
}

void main() {
    vec2 uv = warp(qt_TexCoord0, curvature);
    float inside = tubeMask(uv);
    if (inside <= 0.0) {
        fragColor = vec4(0.0, 0.0, 0.0, 1.0) * qt_Opacity;
        return;
    }
    vec2 pix = floor(uv * srcSize);
    vec3 c = fetch((pix + 0.5) / srcSize);
    vec3 d = c + (bayer4(pix) - 0.5) * 0.2;

    vec3 best = palette(0);
    float bestDist = 1e9;
    for (int i = 0; i < 16; i++) {
        vec3 p = palette(i);
        vec3 diff = d - p;
        float dist = dot(diff * diff, vec3(0.299, 0.587, 0.114));
        if (dist < bestDist) {
            bestDist = dist;
            best = p;
        }
    }
    vec3 col = mix(c, best, strength);

    // Fine scanline gaps of a 24 kHz monitor.
    float l = fract(uv.y * srcSize.y);
    col *= mix(1.0, 0.82 + 0.18 * smoothstep(0.0, 0.25, l) * smoothstep(1.0, 0.75, l), scanlinesVisible() * strength);
    float vig = pow(max(16.0 * uv.x * uv.y * (1.0 - uv.x) * (1.0 - uv.y), 0.0), 0.12);
    col *= mix(1.0, vig, strength);
    fragColor = vec4(col * inside, 1.0) * qt_Opacity;
}
