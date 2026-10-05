"""Channels, settings and watch sessions. Pure Python so it can be unit tested."""

from __future__ import annotations

import os
import time
import uuid
from typing import Callable, Optional

from . import schedule
from .schedule import WATCH_THRESHOLD, WEEK
from .store import Store
from .watch import WatchTracker

DEFAULT_SETTINGS = {
    "screen": "crt",        # screen emulation mode id
    "signal": 0,            # emulated lines, 0 = mode default
    "aspect": "device",     # device | 4:3 | 16:9 | 16:10
    "fit": "letterbox",     # letterbox | stretch | zoom
    "frame": True,          # draw the TV / monitor / phone around the picture
    "volume": 0.8,
    "sparkles": True,       # glitter cursor trail
    "sounds": True,         # UI blips
    "marquee": True,
}

RESUME_MIN_MS = 5_000
RESUME_TAIL_MS = 30_000
SAVE_EVERY_S = 10.0


def _default_clock() -> float:
    offset_days = float(os.environ.get("TOMOTV_TIME_OFFSET_DAYS", "0") or 0)
    return time.time() + offset_days * schedule.DAY


class Station:
    def __init__(self, store: Store, clock: Callable[[], float] = _default_clock):
        self.store = store
        self.clock = clock
        data = store.load()
        self.data = {
            "version": 1,
            "last_seen": float(data.get("last_seen", 0) or 0),
            "settings": {**DEFAULT_SETTINGS, **data.get("settings", {})},
            "stats": {"completed": 0, **data.get("stats", {})},
            "channels": [c for c in data.get("channels", []) if isinstance(c, dict) and c.get("episodes")],
        }

    # ------------------------------------------------------------ basics

    def save(self) -> None:
        self.store.save(self.data)

    def now(self) -> float:
        """Current time, never earlier than a time we've already seen.

        Episodes that aired stay aired even if the computer clock jumps back.
        """
        t = self.clock()
        if t > self.data["last_seen"]:
            self.data["last_seen"] = t
        return self.data["last_seen"]

    @property
    def settings(self) -> dict:
        return self.data["settings"]

    def set_setting(self, key: str, value) -> None:
        if key in DEFAULT_SETTINGS and self.settings.get(key) != value:
            self.settings[key] = value
            self.save()

    @property
    def channels(self) -> list[dict]:
        return self.data["channels"]

    def get(self, channel_id: str) -> Optional[dict]:
        for ch in self.channels:
            if ch["id"] == channel_id:
                return ch
        return None

    def free_number(self) -> int:
        used = {ch.get("number") for ch in self.channels}
        n = 1
        while n in used:
            n += 1
        return n

    # ------------------------------------------------------------ channel management

    def add_channel(
        self,
        folder: str,
        title: str,
        episodes: list[dict],
        audio: Optional[dict] = None,
        subs: Optional[dict] = None,
        interval: float = WEEK,
        number: Optional[int] = None,
        cover: str = "",
        thumb: str = "",
    ) -> dict:
        if not episodes:
            raise ValueError("a channel needs at least one episode")
        now = self.now()
        ch = {
            "id": uuid.uuid4().hex[:12],
            "number": int(number) if number else self.free_number(),
            "title": title.strip() or os.path.basename(folder),
            "folder": folder,
            "premiere": now,
            "interval": max(60.0, float(interval or WEEK)),
            "cover": cover,
            "thumb": thumb,
            "audio": audio,
            "subs": subs or {"kind": "off"},
            "created": now,
            "episodes": [
                {
                    "file": e["file"],
                    "name": e.get("name", ""),
                    "number": e.get("number", ""),
                    "duration": 0,
                    "watched": [],
                    "done": False,
                    "done_at": None,
                    "position": 0,
                    "plays": 0,
                }
                for e in episodes
            ],
        }
        self.channels.append(ch)
        self.save()
        return ch

    def delete_channel(self, channel_id: str) -> None:
        self.data["channels"] = [c for c in self.channels if c["id"] != channel_id]
        self.save()

    def restart_channel(self, channel_id: str) -> None:
        ch = self.get(channel_id)
        if not ch:
            return
        ch["premiere"] = self.now()
        for ep in ch["episodes"]:
            ep.update(watched=[], done=False, done_at=None, position=0)
        self.save()

    def update_channel(self, channel_id: str, **fields) -> None:
        ch = self.get(channel_id)
        if not ch:
            return
        for key in ("title", "folder", "audio", "subs", "number", "cover", "thumb"):
            if key in fields:
                ch[key] = fields[key]
        self.save()

    # ------------------------------------------------------------ queries

    def episode_path(self, ch: dict, index: int) -> str:
        return os.path.join(ch["folder"], ch["episodes"][index]["file"])

    @staticmethod
    def completed(ch: dict) -> list[bool]:
        return [bool(e.get("done")) for e in ch["episodes"]]

    def can_play(self, ch: dict, index: int) -> bool:
        return schedule.can_play(self.completed(ch), ch["premiere"], ch["interval"], self.now(), index)

    @staticmethod
    def episode_label(ch: dict, index: int) -> str:
        number = ch["episodes"][index].get("number") or str(index + 1)
        return f"第{number}話"

    def view(self, ch: dict) -> dict:
        """Everything the UI shows about a channel."""
        now = self.now()
        completed = self.completed(ch)
        summary = schedule.summarize(completed, ch["premiere"], ch["interval"], now)
        states = schedule.episode_states(completed, ch["premiere"], ch["interval"], now)
        episodes = []
        for i, ep in enumerate(ch["episodes"]):
            tracker = WatchTracker(ep.get("watched"), ep.get("duration", 0))
            episodes.append({
                "index": i,
                "name": ep.get("name") or os.path.basename(ep["file"]),
                "label": self.episode_label(ch, i),
                "number": ep.get("number") or str(i + 1),
                "state": states[i],
                "airAt": schedule.air_time(ch["premiere"], i, ch["interval"]),
                "fraction": tracker.fraction(),
                "missing": not os.path.exists(self.episode_path(ch, i)),
            })
        next_index = summary.next_index if summary.next_index is not None else -1
        return {
            "id": ch["id"],
            "number": ch["number"],
            "title": ch["title"],
            "folder": ch["folder"],
            "cover": ch.get("cover") or "",
            "thumb": ch.get("thumb") or "",
            "premiere": ch["premiere"],
            "interval": ch["interval"],
            "total": summary.total,
            "watched": summary.watched,
            "aired": summary.aired,
            "backlog": summary.backlog,
            "canWatch": summary.can_watch,
            "finished": summary.finished,
            "nextIndex": next_index,
            "nextLabel": self.episode_label(ch, next_index) if next_index >= 0 else "",
            "nextAir": summary.next_air or 0,
            "nextEpisodeAir": schedule.air_time(ch["premiere"], next_index, ch["interval"]) if next_index >= 0 else 0,
            "isFinale": next_index == summary.total - 1,
            "audio": ch.get("audio"),
            "subs": ch.get("subs") or {"kind": "off"},
            "episodes": episodes,
        }

    def aired_signature(self) -> tuple:
        """Changes whenever an episode airs; used to know when to refresh the UI."""
        now = self.now()
        return tuple(
            schedule.aired_count(ch["premiere"], ch["interval"], len(ch["episodes"]), now) for ch in self.channels
        )

    # ------------------------------------------------------------ watching

    def start_session(self, channel_id: str, index: int) -> Optional["WatchSession"]:
        ch = self.get(channel_id)
        if not ch or not self.can_play(ch, index):
            return None
        return WatchSession(self, ch, index)


class WatchSession:
    """One viewing of one episode. Feed it the player position a few times per second."""

    def __init__(self, station: Station, channel: dict, index: int):
        self.station = station
        self.channel = channel
        self.index = index
        self.episode = channel["episodes"][index]
        self.tracker = WatchTracker(self.episode.get("watched"), self.episode.get("duration", 0))
        self.rerun = bool(self.episode.get("done"))
        self._last_save = time.monotonic()
        self.episode["plays"] = int(self.episode.get("plays", 0)) + 1

    def resume_position(self) -> int:
        pos = int(self.episode.get("position") or 0)
        dur = int(self.episode.get("duration") or 0)
        if pos < RESUME_MIN_MS or (dur and pos > dur - RESUME_TAIL_MS):
            return 0
        return pos

    def observe(self, pos_ms: int, dur_ms: int, playing: bool, wall_ms: Optional[float] = None) -> dict:
        if wall_ms is None:
            wall_ms = time.monotonic() * 1000
        if dur_ms > 0:
            self.tracker.duration_ms = int(dur_ms)
            self.episode["duration"] = int(dur_ms)
        self.tracker.observe(int(pos_ms), wall_ms, playing)
        self.episode["watched"] = self.tracker.segments
        self.episode["position"] = int(pos_ms)
        newly = False
        if not self.episode.get("done") and self.tracker.fraction() >= WATCH_THRESHOLD:
            self.episode["done"] = True
            self.episode["done_at"] = self.station.now()
            self.station.data["stats"]["completed"] = int(self.station.data["stats"].get("completed", 0)) + 1
            newly = True
        if newly or time.monotonic() - self._last_save > SAVE_EVERY_S:
            self._last_save = time.monotonic()
            self.station.save()
        return {
            "fraction": self.tracker.fraction(),
            "segments": self.tracker.normalized_segments(),
            "completed": bool(self.episode.get("done")),
            "newlyCompleted": newly,
        }

    def seeked(self) -> None:
        self.tracker.reset_anchor()

    def close(self, pos_ms: Optional[int] = None) -> None:
        if pos_ms is not None:
            self.episode["position"] = int(pos_ms)
        self.station.save()
