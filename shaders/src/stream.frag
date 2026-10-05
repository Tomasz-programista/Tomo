#include "common.glsl"
// Streaming over a 56k modem in 2001: QCIF picture, mushy macroblocks, 12-bit colour.

void main() {
    vec2 uv = qt_TexCoord0;
    vec2 pix = uv * srcSize;
    vec2 blockUv = (floor(pix / 8.0) * 8.0 + 4.0) / srcSize;
    vec2 halfBlockUv = (floor(pix / 4.0) * 4.0 + 2.0) / srcSize;

    vec3 c = fetch(uv);
    vec3 b = fetch(blockUv);
    vec3 h = fetch(halfBlockUv);
    float y = mix(luma(c), mix(luma(h), luma(b), 0.5), 0.45);
    vec3 chroma = b - luma(b);
    vec3 col = y + chroma * 1.1;
    col = floor(clamp(col, 0.0, 1.0) * 15.0 + 0.5) / 15.0;

    // Ringing around block edges.
    vec2 edge = abs(fract(pix / 8.0) - 0.5);
    col += (max(edge.x, edge.y) > 0.45 ? 0.025 : 0.0) * (hash12(floor(pix / 8.0) + floor(time * 10.0)) - 0.3);

    vec3 plain = fetch(uv);
    fragColor = vec4(clamp(mix(plain, col, strength), 0.0, 1.0), 1.0) * qt_Opacity;
}
