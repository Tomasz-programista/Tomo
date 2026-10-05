#include "common.glsl"
// A worn VHS tape played on a CRT: chroma smear, wobble, tracking noise, head switching.

vec3 rgb2yiq(vec3 c) {
    return vec3(dot(c, vec3(0.299, 0.587, 0.114)),
                dot(c, vec3(0.596, -0.274, -0.322)),
                dot(c, vec3(0.211, -0.523, 0.312)));
}

vec3 yiq2rgb(vec3 c) {
    return vec3(c.x + 0.956 * c.y + 0.621 * c.z,
                c.x - 0.272 * c.y - 0.647 * c.z,
                c.x - 1.106 * c.y + 1.703 * c.z);
}

void main() {
    vec2 uv = warp(qt_TexCoord0, curvature);
    float inside = tubeMask(uv);
    if (inside <= 0.0) {
        fragColor = vec4(0.0, 0.0, 0.0, 1.0) * qt_Opacity;
        return;
    }
    float frame = floor(time * 29.97);
    float line = floor(uv.y * srcSize.y);

    float wobble = (hash12(vec2(line, frame)) - 0.5) * 0.0016;
    float bandPos = fract(time * 0.043);
    float band = smoothstep(0.03, 0.0, abs(uv.y - bandPos));
    float bandShift = band * (hash12(vec2(line, frame + 3.0)) - 0.3) * 0.02;
    float head = smoothstep(0.972, 1.0, uv.y);
    float headShift = head * (0.012 + 0.012 * hash12(vec2(line, frame)));
    vec2 tuv = uv + vec2((wobble + bandShift + headShift) * strength, 0.0);

    vec2 px = vec2(1.0 / srcSize.x, 0.0);
    float y = rgb2yiq(fetch(tuv - px)).x * 0.25 + rgb2yiq(fetch(tuv)).x * 0.5 + rgb2yiq(fetch(tuv + px)).x * 0.25;
    vec2 iq = vec2(0.0);
    for (int i = 0; i < 6; i++) {
        iq += rgb2yiq(fetch(tuv - px * (float(i) * 1.5 + 1.5))).yz;
    }
    iq /= 6.0;
    vec3 clean = fetch(uv);
    vec3 col = yiq2rgb(vec3(y, iq * 1.12));
    col = col * 0.9 + vec3(0.04, 0.032, 0.045);

    float n = hash12(vec2(gl_FragCoord.x * 0.5, line + frame * 37.0));
    col += (n - 0.5) * 0.08;
    float drop = step(0.9986, hash12(vec2(floor(uv.x * 30.0), line + frame * 13.0)));
    col = mix(col, vec3(0.92), drop);
    col += band * n * 0.28;
    col = mix(col, vec3(n * 0.8), head * 0.45);
    col = mix(clean, col, strength);

    float l = fract(uv.y * srcSize.y) - 0.5;
    col *= mix(1.0, 0.78 + 0.45 * exp(-(l * l) / 0.08), scanlinesVisible() * 0.6 * strength);
    float vig = pow(max(16.0 * uv.x * uv.y * (1.0 - uv.x) * (1.0 - uv.y), 0.0), 0.22);
    col *= mix(1.0, vig, strength);

    fragColor = vec4(clamp(col, 0.0, 1.0) * inside, 1.0) * qt_Opacity;
}
