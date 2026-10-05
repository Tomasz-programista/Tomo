#include "common.glsl"
// Consumer CRT television: curved tube, scanlines, aperture grille, bloom, glass glare.

void main() {
    vec2 uv = warp(qt_TexCoord0, curvature);
    float inside = tubeMask(uv);
    if (inside <= 0.0) {
        fragColor = vec4(0.0, 0.0, 0.0, 1.0) * qt_Opacity;
        return;
    }
    vec2 px = 1.0 / srcSize;

    // Slight convergence error between the three guns.
    vec3 col;
    col.r = fetch(uv + vec2(px.x * 0.4, 0.0)).r;
    col.g = fetch(uv).g;
    col.b = fetch(uv - vec2(px.x * 0.4, 0.0)).b;

    // Phosphor bloom.
    vec3 glow = fetch(uv + vec2(px.x * 1.6, 0.0)) + fetch(uv - vec2(px.x * 1.6, 0.0))
              + fetch(uv + vec2(0.0, px.y * 1.4)) + fetch(uv - vec2(0.0, px.y * 1.4));
    glow *= 0.25;
    col = mix(col, max(col, glow), 0.4 * strength);

    // Scanlines: bright lines get a wider beam.
    float l = fract(uv.y * srcSize.y) - 0.5;
    float beam = mix(0.22, 0.42, luma(col));
    float scan = exp(-(l * l) / (2.0 * beam * beam));
    col *= mix(1.0, scan * 1.4, scanlinesVisible() * strength);

    // Aperture grille.
    float m = mod(gl_FragCoord.x, 3.0);
    vec3 mask = m < 1.0 ? vec3(1.0, 0.72, 0.72) : (m < 2.0 ? vec3(0.72, 1.0, 0.72) : vec3(0.72, 0.72, 1.0));
    col *= mix(vec3(1.0), mask * 1.22, 0.5 * strength);

    // Flicker, a slow hum bar, vignette.
    col *= 0.985 + 0.015 * hash12(vec2(floor(time * 30.0), 7.0));
    col *= 1.0 - 0.03 * strength * (0.5 + 0.5 * sin((uv.y - time * 0.07) * 6.2831));
    float vig = pow(max(16.0 * uv.x * uv.y * (1.0 - uv.x) * (1.0 - uv.y), 0.0), 0.2);
    col *= mix(1.0, vig, strength);

    // Glass reflection and a bit of static.
    float glare = smoothstep(0.6, 0.0, length((qt_TexCoord0 - vec2(0.24, 0.16)) * vec2(1.0, 1.7)));
    col += vec3(0.07, 0.08, 0.1) * glare * strength;
    col += (hash12(gl_FragCoord.xy + fract(time * 7.0) * 311.0) - 0.5) * 0.03 * strength;

    fragColor = vec4(clamp(col, 0.0, 1.0) * inside, 1.0) * qt_Opacity;
}
