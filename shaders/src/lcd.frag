#include "common.glsl"
// A 2006 flip phone watching 1seg mobile TV: tiny low-bitrate picture on a small LCD.

void main() {
    vec2 uv = qt_TexCoord0;
    vec2 pix = uv * srcSize;
    vec2 cell = fract(pix);

    // Low bitrate: colour comes from 8x8 macroblocks, some blockiness in brightness too.
    vec2 blockUv = (floor(pix / 8.0) * 8.0 + 4.0) / srcSize;
    vec3 c = fetch(uv);
    vec3 b = fetch(blockUv);
    float y = mix(luma(c), luma(b), 0.22);
    vec3 chroma = mix(c - luma(c), b - luma(b), 0.6);
    vec3 col = y + chroma;
    col = floor(col * 31.0 + 0.5) / 31.0;   // 15-bit colour banding

    // Washed out, cool LCD with an uneven backlight.
    col = col * 0.86 + 0.06;
    col *= vec3(0.95, 1.0, 1.07);
    col *= 1.0 + 0.06 * smoothstep(0.6, 0.0, uv.y) - 0.05 * smoothstep(0.5, 1.0, length(uv - 0.5) * 1.4);

    // Pixel grid with faint RGB stripes, only when pixels are big enough to see.
    float cellPx = outSize.x / max(srcSize.x, 1.0);
    float grid = clamp((cellPx - 2.5) / 2.5, 0.0, 1.0) * strength;
    float gap = smoothstep(0.0, 0.14, cell.x) * smoothstep(1.0, 0.86, cell.x)
              * smoothstep(0.0, 0.14, cell.y) * smoothstep(1.0, 0.86, cell.y);
    vec3 stripes = cell.x < 0.333 ? vec3(1.12, 0.94, 0.94) : (cell.x < 0.666 ? vec3(0.94, 1.12, 0.94) : vec3(0.94, 0.94, 1.12));
    col *= mix(vec3(1.0), stripes * (0.55 + 0.5 * gap), grid);

    vec3 plain = fetch(uv);
    fragColor = vec4(clamp(mix(plain, col, strength), 0.0, 1.0), 1.0) * qt_Opacity;
}
