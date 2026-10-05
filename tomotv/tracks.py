"""Choosing audio / subtitle tracks from a remembered preference."""

from __future__ import annotations

from typing import Optional

LANG_NAMES_JA = {
    "Japanese": "日本語",
    "English": "英語",
    "Spanish": "スペイン語",
    "French": "フランス語",
    "German": "ドイツ語",
    "Italian": "イタリア語",
    "Portuguese": "ポルトガル語",
    "Russian": "ロシア語",
    "Chinese": "中国語",
    "Korean": "韓国語",
    "Polish": "ポーランド語",
    "Arabic": "アラビア語",
}


def describe(index: int, lang: str, title: str, codec: str = "") -> str:
    lang = lang or "Unknown"
    label = f"{index + 1}. {lang}"
    if title and title.strip().lower() != lang.lower():
        label += f" — {title.strip()}"
    if codec:
        label += f" [{codec}]"
    return label


def pick_track(pref: Optional[dict], tracks: list[dict], fallback_first: bool = True) -> int:
    """Index of the track that best matches `pref` ({index, lang, title}); -1 if none."""
    if not tracks:
        return -1
    if not pref:
        return 0 if fallback_first else -1
    lang = (pref.get("lang") or "").lower()
    title = (pref.get("title") or "").lower()
    if lang or title:
        for i, t in enumerate(tracks):
            if (t.get("lang") or "").lower() == lang and (t.get("title") or "").lower() == title:
                return i
    if lang:
        for i, t in enumerate(tracks):
            if (t.get("lang") or "").lower() == lang:
                return i
    index = pref.get("index", -1)
    if isinstance(index, int) and 0 <= index < len(tracks):
        return index
    return 0 if fallback_first else -1
