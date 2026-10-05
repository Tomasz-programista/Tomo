#!/usr/bin/env python3
"""Regenerate the PNG icons and the chiptune UI sounds in assets/.

python tools/make_assets.py   (needs PySide6 for the PNG rendering)
"""

import math
import os
import random
import struct
import sys
import wave

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
IMG = os.path.join(ROOT, "assets", "img")
SND = os.path.join(ROOT, "assets", "sounds")


# ------------------------------------------------------------------ images


def render_svg(svg_name: str, png_name: str, size: int) -> None:
    from PySide6.QtCore import QRectF, Qt
    from PySide6.QtGui import QImage, QPainter
    from PySide6.QtSvg import QSvgRenderer

    renderer = QSvgRenderer(os.path.join(IMG, svg_name))
    view = renderer.viewBoxF()
    image = QImage(size, size, QImage.Format.Format_ARGB32_Premultiplied)
    image.fill(Qt.GlobalColor.transparent)
    painter = QPainter(image)
    painter.setRenderHint(QPainter.RenderHint.Antialiasing)
    scale = size / max(view.width(), view.height())
    w, h = view.width() * scale, view.height() * scale
    renderer.render(painter, QRectF((size - w) / 2, (size - h) / 2, w, h))
    painter.end()
    image.save(os.path.join(IMG, png_name))
    print("wrote", png_name)


def images() -> None:
    from PySide6.QtGui import QGuiApplication

    app = QGuiApplication.instance() or QGuiApplication(sys.argv[:1])  # noqa: F841
    render_svg("mascot.svg", "icon.png", 256)
    try:  # Windows icon with several sizes (needs Pillow, only used for the .exe build)
        from PIL import Image

        Image.open(os.path.join(IMG, "icon.png")).save(
            os.path.join(ROOT, "packaging", "tomotv.ico"), sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)]
        )
        print("wrote tomotv.ico")
    except ImportError:
        print("Pillow not installed, skipped packaging/tomotv.ico")
    render_svg("star.svg", "star.png", 32)
    render_svg("heart.svg", "heart.png", 32)


# ------------------------------------------------------------------ sounds


def square(phase: float, duty: float = 0.5) -> float:
    return 1.0 if (phase % 1.0) < duty else -1.0


def triangle(phase: float) -> float:
    p = phase % 1.0
    return 4 * p - 1 if p < 0.5 else 3 - 4 * p


def write_wav(name: str, samples: list, rate: int) -> None:
    peak = max(1e-6, max(abs(s) for s in samples))
    gain = 0.8 / peak
    with wave.open(os.path.join(SND, name), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(rate)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, s * gain)) * 32767)) for s in samples))
    print("wrote", name)


def tone(freq, dur, rate, wave_fn, vol=1.0, attack=0.004, decay=None, vibrato=0.0):
    out = []
    n = int(dur * rate)
    phase = 0.0
    for i in range(n):
        t = i / rate
        f = freq * (1 + vibrato * math.sin(2 * math.pi * 6 * t))
        phase += f / rate
        env = min(1.0, t / attack) if attack else 1.0
        if decay:
            env *= math.exp(-t / decay)
        else:
            env *= min(1.0, (dur - t) / 0.01)
        out.append(wave_fn(phase) * env * vol)
    return out


def sounds() -> None:
    os.makedirs(SND, exist_ok=True)
    r = 22050
    write_wav("click.wav", tone(1320, 0.03, r, lambda p: square(p, 0.25), 0.5) + tone(1760, 0.04, r, lambda p: square(p, 0.25), 0.5), r)
    write_wav("open.wav", sum((tone(f, 0.055, r, lambda p: square(p, 0.25), 0.5) for f in (1047, 1319, 1568, 2093)), []), r)
    write_wav("back.wav", sum((tone(f, 0.06, r, lambda p: square(p, 0.25), 0.5) for f in (1568, 1047)), []), r)
    bell = lambda p: math.sin(2 * math.pi * p) + 0.3 * math.sin(4 * math.pi * p) + 0.12 * math.sin(6 * math.pi * p)
    write_wav("onair.wav", tone(659, 0.45, r, bell, decay=0.25) + tone(523, 0.7, r, bell, decay=0.35), r)
    fanfare = []
    for f in (523, 659, 784):
        fanfare += tone(f, 0.09, r, lambda p: 0.6 * square(p, 0.5) + 0.4 * triangle(p), 0.6)
    fanfare += tone(1047, 0.55, r, lambda p: 0.6 * square(p, 0.5) + 0.4 * triangle(p), 0.6, vibrato=0.01)
    write_wav("complete.wav", fanfare, r)
    write_wav("error.wav", tone(110, 0.14, r, square, 0.6) + [0.0] * int(0.05 * r) + tone(98, 0.2, r, square, 0.6), r)

    # CRT power-on: a thump, a burst of static and the faint flyback whine.
    r2 = 44100
    rnd = random.Random(3)
    tv = []
    for i in range(int(0.5 * r2)):
        t = i / r2
        thump = math.sin(2 * math.pi * 55 * t) * math.exp(-t / 0.05) * 0.9
        static = (rnd.random() * 2 - 1) * 0.35 * math.exp(-t / 0.12) * min(1, t / 0.01)
        whine = math.sin(2 * math.pi * 15734 * t) * 0.025 * min(1, t / 0.05) * min(1, (0.5 - t) / 0.1)
        tv.append(thump + static + whine)
    write_wav("tvon.wav", tv, r2)


if __name__ == "__main__":
    images()
    sounds()
