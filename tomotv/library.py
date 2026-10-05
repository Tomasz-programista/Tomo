"""Finds episodes, extras, subtitle files and cover art in a season folder."""

from __future__ import annotations

import os
import re
from dataclasses import dataclass, field
from typing import Optional

VIDEO_EXTS = {
    ".mkv", ".mp4", ".m4v", ".avi", ".webm", ".mov", ".wmv", ".flv", ".ogm", ".ogv",
    ".ts", ".m2ts", ".mts", ".mpg", ".mpeg", ".rmvb", ".rm", ".3gp", ".divx", ".vob",
}
SUB_EXTS = {".ass", ".ssa", ".srt", ".vtt"}
IMAGE_EXTS = {".jpg", ".jpeg", ".png", ".webp", ".bmp"}
EXTRA_DIR_NAMES = {
    "extras", "extra", "bonus", "specials", "special", "sps", "sp", "nc", "ncop", "nced",
    "menu", "menus", "cds", "cd", "scans", "pv", "cm", "featurettes", "trailers", "creditless",
}
COVER_NAMES = ("cover", "folder", "poster", "front", "thumb", "thumbnail", "banner")

# Things that are not part of a show's name or episode number.
_TAG_RE = re.compile(r"\[[^\]]*\]|\([^)]*\)|\{[^}]*\}|【[^】]*】")
_JUNK_RE = re.compile(
    r"(?i)(?<![a-z0-9])(?:"
    r"\d{3,4}[pi]|\d{3,4}x\d{3,4}|4k|uhd|bd(?:rip|remux)?|blu-?ray|dvd(?:rip)?|web(?:-?dl|-?rip)|hdtv|"
    r"[xh][ .]?26[45]|hevc|avc|av1|vp9|10-?bit|8-?bit|hi10p?|aac(?:2\.0|5\.1)?|e?ac-?3|dts(?:-hd)?|flac|"
    r"opus|mp3|truehd|ddp?(?:\d\.\d)?|atmos|amzn|nf|dsnp|hidive|crunchyroll|dual[ ._-]?audio|multi[ ._-]?subs?|batch|repack|proper|remastered|uncensored|"
    r"[25]\.[01]|v\d"
    r")(?![a-z0-9])"
)
_EXTRA_RE = re.compile(
    r"(?i)(?:"
    r"(?<![a-z])nc[ ._-]?(?:op|ed)\d*(?![a-z])|creditless|clean[ ._-]?(?:op|ed|opening|ending)|"
    r"\s-\s(?:nc)?(?:op|ed|sp|ova|oad|ona|special|recap|pv|cm|preview|trailer|menu)[ ._-]?\d*(?![a-z])|"
    r"(?<![a-z])(?:pv|cm|trailer|teaser|menu)[ ._-]?\d*(?![a-z])"
    r")"
)


def natural_key(text: str):
    return [int(part) if part.isdigit() else part.lower() for part in re.split(r"(\d+)", text)]


def _mask(pattern: re.Pattern, text: str) -> str:
    """Blank out matches with spaces so string positions stay the same."""
    return pattern.sub(lambda m: " " * len(m.group()), text)


@dataclass
class EpisodeNumber:
    number: float
    season: Optional[int] = None
    span: tuple[int, int] = (0, 0)  # position of the number in the file name


def parse_episode(stem: str) -> Optional[EpisodeNumber]:
    """Guess the episode number from a file name (without extension)."""
    m = re.search(r"(?i)(?<![a-z0-9])s(\d{1,2})[ ._-]?e(\d{1,4}(?:\.\d(?!\d))?)", stem)
    if m:
        return EpisodeNumber(float(m.group(2)), int(m.group(1)), m.span(2))
    m = re.search(r"第\s*(\d{1,4})\s*[話回]", stem)
    if m:
        return EpisodeNumber(float(m.group(1)), None, m.span(1))

    untagged = _mask(_TAG_RE, stem)
    m = re.search(r"(?i)(?:^|[\s._-])(?:ep|episode|e)\.?[ _]?(\d{1,4}(?:\.\d(?!\d))?)(?:v\d)?(?=$|[\s._\-\[(])", untagged)
    if m:
        return EpisodeNumber(float(m.group(1)), None, m.span(1))
    m = re.search(r"\s-\s(\d{1,4}(?:\.\d(?!\d))?)(?:v\d)?(?=$|[\s._\[(])", untagged)
    if m:
        return EpisodeNumber(float(m.group(1)), None, m.span(1))
    m = re.search(r"\[(\d{1,4}(?:\.\d(?!\d))?)(?:v\d)?\]", stem)
    if m:
        return EpisodeNumber(float(m.group(1)), None, m.span(1))

    clean = _mask(_JUNK_RE, untagged)
    candidates = [
        m for m in re.finditer(r"(?<![a-zA-Z0-9.])(\d{1,4}(?:\.5)?)(?:v\d)?(?![a-zA-Z0-9])", clean)
        if not (len(m.group(1)) == 4 and 1950 <= int(float(m.group(1))) <= 2039)
    ]
    if candidates:
        m = candidates[-1]
        return EpisodeNumber(float(m.group(1)), None, m.span(1))
    return None


def is_extra(stem: str) -> bool:
    return bool(_EXTRA_RE.search(_mask(_TAG_RE, stem)) or _EXTRA_RE.search(stem))


def clean_name(name: str) -> str:
    """Make a file or folder name look like a title."""
    text = _TAG_RE.sub(" ", name).replace("_", " ")
    if " " not in text.strip():  # scene style: Show.Name.S01.1080p-GROUP
        text = re.sub(r"-[A-Za-z0-9]+$", "", text.strip())
        text = re.sub(r"\.(?!(?<=\d\.)\d(?!\d))", " ", text)  # dots become spaces, "5.1" stays
    text = _JUNK_RE.sub(" ", text)
    text = re.sub(r"\s+", " ", text).strip(" -_.~")
    return text or name


def guess_title(folder: str) -> str:
    name = os.path.basename(os.path.normpath(folder))
    title = clean_name(name)
    title = re.sub(r"(?i)[\s._-]+(?:complete|batch|bd|tv)$", "", title).strip()
    return title or name


def format_number(number: Optional[float]) -> str:
    if number is None:
        return ""
    return str(int(number)) if float(number).is_integer() else str(number)


@dataclass
class ScanItem:
    file: str                       # path relative to the season folder
    name: str                       # pretty name
    number: Optional[float]
    season: Optional[int]
    include: bool
    kind: str                       # "episode" | "extra" | "duplicate"
    note: str = ""

    def as_dict(self) -> dict:
        return {
            "file": self.file,
            "name": self.name,
            "number": format_number(self.number),
            "include": self.include,
            "kind": self.kind,
            "note": self.note,
        }


@dataclass
class ScanResult:
    folder: str
    title: str
    items: list[ScanItem] = field(default_factory=list)
    cover: str = ""
    warning: str = ""


def _walk_videos(folder: str, max_depth: int) -> list[str]:
    found = []
    base_depth = folder.rstrip(os.sep).count(os.sep)
    for root, dirs, files in os.walk(folder):
        dirs[:] = sorted(d for d in dirs if not d.startswith("."))
        if root.count(os.sep) - base_depth >= max_depth:
            dirs[:] = []
        for f in files:
            if os.path.splitext(f)[1].lower() in VIDEO_EXTS and not f.startswith("."):
                found.append(os.path.relpath(os.path.join(root, f), folder))
    return found


def find_cover(folder: str) -> str:
    try:
        images = [f for f in os.listdir(folder) if os.path.splitext(f)[1].lower() in IMAGE_EXTS]
    except OSError:
        return ""
    for wanted in COVER_NAMES:
        for f in images:
            if os.path.splitext(f)[0].lower() == wanted:
                return os.path.join(folder, f)
    if len(images) == 1:
        return os.path.join(folder, images[0])
    return ""


def scan_folder(folder: str) -> ScanResult:
    folder = os.path.abspath(folder)
    result = ScanResult(folder=folder, title=guess_title(folder), cover=find_cover(folder))
    files = _walk_videos(folder, max_depth=1)
    if not files:
        files = _walk_videos(folder, max_depth=3)
    if not files:
        result.warning = "No video files found in this folder."
        return result

    episodes: list[ScanItem] = []
    others: list[ScanItem] = []
    for rel in files:
        stem = os.path.splitext(os.path.basename(rel))[0]
        parts = [p.lower() for p in rel.split(os.sep)[:-1]]
        parsed = parse_episode(stem)
        item = ScanItem(
            file=rel,
            name=clean_name(stem),
            number=parsed.number if parsed else None,
            season=parsed.season if parsed else None,
            include=True,
            kind="episode",
        )
        if is_extra(stem) or any(p in EXTRA_DIR_NAMES for p in parts):
            item.include, item.kind, item.note = False, "extra", "extra / creditless / special?"
            others.append(item)
        else:
            episodes.append(item)

    numbered = [e for e in episodes if e.number is not None]
    unnumbered = [e for e in episodes if e.number is None]
    numbered.sort(key=lambda e: (e.season or 0, e.number, natural_key(e.file)))
    unnumbered.sort(key=lambda e: natural_key(e.file))

    # Two files with the same number (v1 + v2 releases): keep the last one.
    seen: dict[tuple, ScanItem] = {}
    for e in numbered:
        key = (e.season or 0, e.number)
        if key in seen:
            older = seen[key]
            older.include, older.kind, older.note = False, "duplicate", "same episode number as another file"
        seen[key] = e
    ordered = [e for e in numbered if e.include] + unnumbered
    ordered += [e for e in numbered if not e.include]
    others.sort(key=lambda e: natural_key(e.file))
    result.items = ordered + others
    if not any(i.include for i in result.items):
        for i in result.items:
            i.include = True
    return result


# ---------------------------------------------------------------- subtitles


def _subtitle_files(folder: str) -> list[str]:
    found = []
    base_depth = folder.rstrip(os.sep).count(os.sep)
    for root, dirs, files in os.walk(folder):
        depth = root.count(os.sep) - base_depth
        dirs[:] = [d for d in dirs if depth < 3 and not d.startswith(".")]
        for f in files:
            if os.path.splitext(f)[1].lower() in SUB_EXTS:
                found.append(os.path.relpath(os.path.join(root, f), folder))
    return found


def match_external_subtitles(folder: str, episode_files: list[str]) -> dict[str, dict[str, str]]:
    """Group external subtitle files into "tracks".

    Returns {label: {episode_file: subtitle_path}}. A label describes one
    subtitle set, e.g. ".en.srt" for files named like the episode plus ".en.srt".
    """
    subs = _subtitle_files(folder)
    parsed_subs = []
    for rel in subs:
        stem, ext = os.path.splitext(os.path.basename(rel))
        parsed_subs.append((rel, stem, ext.lower(), os.path.dirname(rel), parse_episode(stem)))

    groups: dict[str, dict[str, str]] = {}
    for ep in episode_files:
        ep_stem = os.path.splitext(os.path.basename(ep))[0]
        ep_dir = os.path.dirname(ep)
        ep_num = parse_episode(ep_stem)
        for rel, stem, ext, sdir, snum in parsed_subs:
            label = None
            where = "" if sdir in ("", ep_dir) else sdir.replace(os.sep, "/") + "/"
            if stem == ep_stem or (stem.startswith(ep_stem) and stem[len(ep_stem)] in "._ -"):
                label = where + "…" + stem[len(ep_stem):] + ext
            elif os.path.basename(sdir) == ep_stem:
                label = os.path.dirname(sdir).replace(os.sep, "/") + "/…/" + stem + ext
            elif ep_num and snum and snum.number == ep_num.number and (snum.season or 0) == (ep_num.season or 0):
                s, e = snum.span
                label = where + stem[:s] + "#" + stem[e:] + ext
            if label is not None:
                groups.setdefault(label, {}).setdefault(ep, os.path.join(folder, rel))
    return groups


def describe_sub_label(label: str) -> str:
    ext = os.path.splitext(label)[1].lstrip(".").upper()
    core = label[: -len(ext) - 1] if ext else label
    core = core.replace("…", "").strip(" ._-/")
    return f"{core} ({ext})" if core else f"Same name as episode ({ext})"
