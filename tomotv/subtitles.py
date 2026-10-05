"""Subtitle parsing (SRT / WebVTT / ASS / SSA) and conversion to QML rich text."""

from __future__ import annotations

import bisect
import html
import re
from dataclasses import dataclass

MAX_LINES_ON_SCREEN = 4


@dataclass
class Cue:
    start: int  # ms
    end: int    # ms
    text: str   # rich text (QML StyledText subset)
    top: bool = False
    positioned: bool = False  # had \pos / \move, i.e. probably a sign or karaoke


# ------------------------------------------------------------ formatting

_TOKEN_RE = re.compile(r"(\{[^}]*\}|</?[ibuIBU]>|<font[^>]*>|</font>|<[^>]{1,40}>|\\N|\\n|\\h|\n)")


def format_text(raw: str) -> tuple[str, bool, bool]:
    """Turn raw subtitle text (ASS override tags and/or HTML-ish tags) into QML rich text.

    Returns (rich_text, top_aligned, positioned). Drawing commands return "".
    """
    out: list[str] = []
    state = {"i": False, "b": False, "u": False}
    top = False
    positioned = False
    drawing = False

    def set_style(tag: str, on: bool) -> None:
        if state[tag] != on:
            out.append(f"<{tag}>" if on else f"</{tag}>")
            state[tag] = on

    for token in _TOKEN_RE.split(raw):
        if not token:
            continue
        if token.startswith("{"):
            body = token[1:-1]
            if "\\" not in body:
                continue  # a comment
            for m in re.finditer(r"\\(i|b|u)(\d*)(?![a-z])", body):
                tag, val = m.group(1), m.group(2)
                set_style(tag, val not in ("0",) and val != "")
            m = re.search(r"\\p(\d+)", body)
            if m:
                drawing = int(m.group(1)) > 0
            if re.search(r"\\an[789]|\\a(?:[567])(?!\d)", body):
                top = True
            if re.search(r"\\(?:pos|move)\(", body):
                positioned = True
        elif token in ("\\N", "\n"):
            if not drawing:
                out.append("<br>")
        elif token == "\\n":
            if not drawing:
                out.append(" ")
        elif token == "\\h":
            if not drawing:
                out.append("&nbsp;")
        elif token.startswith("<"):
            m = re.fullmatch(r"<(/?)([ibuIBU])>", token)
            if m:
                set_style(m.group(2).lower(), m.group(1) == "")
            # other html-ish tags (<font>, <c.yellow>, <v Name>, <ruby>) are dropped
        elif not drawing:
            out.append(html.escape(token, quote=False))

    for tag in ("u", "b", "i"):
        set_style(tag, False)
    text = "".join(out)
    text = re.sub(r"(<br>)+$", "", re.sub(r"^(<br>)+", "", text))
    plain = re.sub(r"<[^>]+>|&nbsp;", "", text).strip()
    if not plain:
        return "", top, positioned
    return text.strip(), top, positioned


# ------------------------------------------------------------ decoding


def decode_bytes(data: bytes) -> str:
    if data.startswith(b"\xef\xbb\xbf"):
        return data[3:].decode("utf-8", errors="replace")
    if data.startswith((b"\xff\xfe", b"\xfe\xff")):
        return data.decode("utf-16", errors="replace")
    try:
        return data.decode("utf-8")
    except UnicodeDecodeError:
        pass
    for enc, probe in (("cp932", r"[\u3040-\u30ff]"), ("gb18030", r"[\u4e00-\u9fff]"), ("big5", r"[\u4e00-\u9fff]")):
        try:
            text = data.decode(enc)
        except UnicodeDecodeError:
            continue
        if re.search(probe, text):
            return text
    return data.decode("cp1252", errors="replace")


# ------------------------------------------------------------ parsers

_SRT_TIME = re.compile(r"(\d+):(\d{1,2}):(\d{1,2})[,.](\d{1,3})")
_VTT_TIME = re.compile(r"(?:(\d+):)?(\d{1,2}):(\d{1,2})[.,](\d{1,3})")


def _ms(h, m, s, frac) -> int:
    frac = (frac or "0").ljust(3, "0")[:3]
    return ((int(h or 0) * 60 + int(m)) * 60 + int(s)) * 1000 + int(frac)


def parse_srt(text: str) -> list[Cue]:
    cues = []
    for block in re.split(r"\n\s*\n", text.replace("\r\n", "\n").replace("\r", "\n")):
        lines = block.strip("\n").split("\n")
        for i, line in enumerate(lines[:3]):
            if "-->" in line:
                left, right = line.split("-->", 1)
                a, b = _SRT_TIME.search(left), _SRT_TIME.search(right)
                if not a or not b:
                    break
                rich, top, pos = format_text("\n".join(lines[i + 1:]))
                if rich:
                    cues.append(Cue(_ms(*a.groups()), _ms(*b.groups()), rich, top, pos))
                break
    return cues


def parse_vtt(text: str) -> list[Cue]:
    cues = []
    for block in re.split(r"\n\s*\n", text.replace("\r\n", "\n").replace("\r", "\n")):
        lines = block.strip("\n").split("\n")
        for i, line in enumerate(lines[:3]):
            if "-->" in line:
                left, right = line.split("-->", 1)
                a, b = _VTT_TIME.search(left), _VTT_TIME.search(right)
                if not a or not b:
                    break
                top = bool(re.search(r"line:\s*(?:[0-3]?\d%|[0-4](?!\d))", right))
                rich, top2, pos = format_text("\n".join(lines[i + 1:]))
                if rich:
                    cues.append(Cue(_ms(*a.groups()), _ms(*b.groups()), rich, top or top2, pos))
                break
    return cues


def _ass_time(value: str) -> int:
    m = re.match(r"\s*(\d+):(\d{1,2}):(\d{1,2})(?:[.:](\d{1,3}))?", value)
    if not m:
        return 0
    h, mi, s, cs = m.groups()
    cs = (cs or "0")
    frac = int(cs) * 10 if len(cs) <= 2 else int(cs[:3])
    return ((int(h) * 60 + int(mi)) * 60 + int(s)) * 1000 + frac


def parse_ass(text: str) -> list[Cue]:
    section = ""
    style_fields: list[str] = []
    event_fields: list[str] = []
    top_styles: set[str] = set()
    ssa = False
    cues = []
    for raw_line in text.replace("\r\n", "\n").replace("\r", "\n").split("\n"):
        line = raw_line.strip()
        if not line or line.startswith(";"):
            continue
        if line.startswith("[") and line.endswith("]"):
            section = line.lower()
            ssa = section == "[v4 styles]"
            continue
        key, _, value = line.partition(":")
        key = key.strip().lower()
        if section in ("[v4+ styles]", "[v4 styles]"):
            if key == "format":
                style_fields = [f.strip().lower() for f in value.split(",")]
            elif key == "style" and style_fields:
                parts = [p.strip() for p in value.split(",", len(style_fields) - 1)]
                info = dict(zip(style_fields, parts))
                try:
                    align = int(info.get("alignment", "2"))
                except ValueError:
                    align = 2
                if (ssa and align in (5, 6, 7)) or (not ssa and align in (7, 8, 9)):
                    top_styles.add(info.get("name", "").lower())
        elif section == "[events]":
            if key == "format":
                event_fields = [f.strip().lower() for f in value.split(",")]
            elif key == "dialogue":
                fields = event_fields or ["layer", "start", "end", "style", "name", "marginl", "marginr", "marginv", "effect", "text"]
                parts = value.split(",", len(fields) - 1)
                if len(parts) < len(fields):
                    continue
                info = dict(zip(fields, parts))
                rich, top, pos = format_text(info.get("text", ""))
                if not rich:
                    continue
                top = top or info.get("style", "").strip().lower() in top_styles
                cues.append(Cue(_ass_time(info.get("start", "")), _ass_time(info.get("end", "")), rich, top, pos))
    return cues


def parse_file(path: str) -> list[Cue]:
    with open(path, "rb") as f:
        text = decode_bytes(f.read())
    lower = path.lower()
    if lower.endswith((".ass", ".ssa")):
        cues = parse_ass(text)
    elif lower.endswith(".vtt") or text.lstrip().startswith("WEBVTT"):
        cues = parse_vtt(text)
    else:
        cues = parse_srt(text)
    return [c for c in cues if c.end > c.start]


# ------------------------------------------------------------ timeline


class CueTrack:
    """Fast "what is on screen at time t" lookups, with overlapping cues merged."""

    def __init__(self, cues: list[Cue]):
        events = []
        for idx, c in enumerate(cues):
            events.append((c.start, 1, idx))
            events.append((c.end, 0, idx))
        events.sort()
        active: dict[int, Cue] = {}
        self._starts: list[int] = []
        self._texts: list[tuple[str, str]] = []
        i = 0
        while i < len(events):
            t = events[i][0]
            while i < len(events) and events[i][0] == t:
                _, kind, idx = events[i]
                if kind:
                    active[idx] = cues[idx]
                else:
                    active.pop(idx, None)
                i += 1
            self._starts.append(t)
            self._texts.append(self._compose(list(active.values())))

    @staticmethod
    def _compose(cues: list[Cue]) -> tuple[str, str]:
        # Prefer normal dialogue over positioned signs / karaoke, drop duplicates.
        cues = sorted(cues, key=lambda c: (c.positioned, c.start))
        top, bottom, seen = [], [], set()
        for c in cues:
            if c.text in seen:
                continue
            seen.add(c.text)
            target = top if c.top else bottom
            if len(target) < MAX_LINES_ON_SCREEN:
                target.append(c.text)
        return "<br>".join(top), "<br>".join(bottom)

    def text_at(self, ms: int) -> tuple[str, str]:
        """(top_text, bottom_text) shown at `ms`."""
        i = bisect.bisect_right(self._starts, ms) - 1
        if i < 0:
            return "", ""
        return self._texts[i]
