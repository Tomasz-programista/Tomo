.pragma library

// Screen emulation modes.
//   device:    which frame is drawn around the picture
//   shader:    fragment shader in shaders/ ("" = clean picture)
//   lines:     emulated vertical resolution (0 = full resolution)
//   aspect:    shape of the screen ("source" = follow the video)
//   hFactor:   horizontal resolution relative to square pixels (VHS is blurry sideways)
//   fps:       picture update rate (0 = every frame)
var modes = [
    { id: "digital", name: "Digital HD", jp: "デジタル放送", device: "flat", shader: "", lines: 0, aspect: "source",
      hFactor: 1.0, fps: 0, smooth: true, curvature: 0.0, variant: 0,
      desc: "A shiny 2005 flat-screen. Clean picture." },
    { id: "crt", name: "CRT Television", jp: "ブラウン管", device: "tv", shader: "crt", lines: 480, aspect: "4:3",
      hFactor: 1.0, fps: 0, smooth: true, curvature: 0.045, variant: 0,
      desc: "Grandma's living room TV. Scanlines, glow, curved glass." },
    { id: "vhs", name: "VHS Fansub Tape", jp: "ビデオテープ", device: "tv", shader: "vhs", lines: 480, aspect: "4:3",
      hFactor: 0.52, fps: 0, smooth: true, curvature: 0.045, variant: 0,
      desc: "A 5th generation copy from the anime club. Wobbly and smeary." },
    { id: "pc98", name: "PC-98 16 Colors", jp: "16色パソコン", device: "monitor", shader: "pc98", lines: 400, aspect: "4:3",
      hFactor: 1.2, fps: 0, smooth: false, curvature: 0.015, variant: 0,
      desc: "640×400, sixteen colors, dithered like a visual novel." },
    { id: "phosphor", name: "Green Terminal", jp: "緑の端末", device: "monitor", shader: "phosphor", lines: 240, aspect: "4:3",
      hFactor: 1.0, fps: 0, smooth: true, curvature: 0.05, variant: 0,
      desc: "Watching anime on the school computer lab terminal." },
    { id: "amber", name: "Amber Terminal", jp: "琥珀の端末", device: "monitor", shader: "phosphor", lines: 240, aspect: "4:3",
      hFactor: 1.0, fps: 0, smooth: true, curvature: 0.05, variant: 1,
      desc: "Same, but in warm amber." },
    { id: "oneseg", name: "1seg Flip Phone", jp: "ワンセグ携帯", device: "phone", shader: "lcd", lines: 180, aspect: "16:9",
      hFactor: 1.0, fps: 15, smooth: true, curvature: 0.0, variant: 0,
      desc: "Mobile TV on a 2006 flip phone, under the desk at school." },
    { id: "pocket", name: "Pocket LCD", jp: "携帯ゲーム機", device: "handheld", shader: "pocket", lines: 144, aspect: "10:9",
      hFactor: 1.0, fps: 0, smooth: false, curvature: 0.0, variant: 0,
      desc: "Four shades of pea soup green. Why would you. Why not!" },
    { id: "stream", name: "56k Stream", jp: "ナローバンド", device: "window", shader: "stream", lines: 144, aspect: "11:9",
      hFactor: 1.0, fps: 10, smooth: true, curvature: 0.0, variant: 0,
      desc: "Buffering... streaming over dial-up in 2001." }
]

var signals = [0, 1080, 720, 576, 480, 360, 240, 144]
var aspects = ["device", "4:3", "16:9", "16:10", "source"]
var fits = ["letterbox", "stretch", "zoom"]

function find(id) {
    for (var i = 0; i < modes.length; i++)
        if (modes[i].id === id)
            return modes[i]
    return modes[1]
}

function indexOf(id) {
    for (var i = 0; i < modes.length; i++)
        if (modes[i].id === id)
            return i
    return 1
}

function ratio(aspect, sourceRatio) {
    if (aspect === "4:3") return 4 / 3
    if (aspect === "16:9") return 16 / 9
    if (aspect === "16:10") return 16 / 10
    if (aspect === "10:9") return 10 / 9
    if (aspect === "11:9") return 11 / 9
    return sourceRatio > 0 ? sourceRatio : 16 / 9
}

function signalName(lines) {
    if (lines === 0) return "Mode default"
    if (lines === 1080) return "1080 lines (Full HD)"
    if (lines === 720) return "720 lines (HD)"
    if (lines === 576) return "576 lines (PAL)"
    if (lines === 480) return "480 lines (NTSC / DVD)"
    if (lines === 360) return "360 lines (early YouTube)"
    if (lines === 240) return "240 lines (VCD / game console)"
    return lines + " lines (potato)"
}

function aspectName(a) {
    return { "device": "Device default", "4:3": "4:3 (old TV)", "16:9": "16:9 (widescreen)",
             "16:10": "16:10 (PC monitor)", "source": "Same as the video" }[a] || a
}

function fitName(f) {
    return { "letterbox": "Letterbox (black bars)", "stretch": "Stretch (squish!)", "zoom": "Zoom (pan & scan)" }[f] || f
}
