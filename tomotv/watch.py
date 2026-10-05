"""Tracks how much of an episode was really watched.

Only natural playback counts: between two observations the position has to
move forward at roughly real-time speed. Seeking ahead adds nothing, so the
only way to reach the threshold is to actually watch the episode.
"""

from __future__ import annotations

from typing import Iterable, Optional

Segment = list  # [start_ms, end_ms]


def merge_segments(segments: Iterable[Segment], gap_ms: int = 50) -> list[Segment]:
    cleaned = sorted([int(s), int(e)] for s, e in segments if e > s)
    merged: list[Segment] = []
    for s, e in cleaned:
        if merged and s <= merged[-1][1] + gap_ms:
            merged[-1][1] = max(merged[-1][1], e)
        else:
            merged.append([s, e])
    return merged


class WatchTracker:
    MAX_STEP_MS = 5000   # a bigger jump between two observations is a seek
    SLACK_MS = 400       # timer jitter allowance
    SPEED_TOLERANCE = 1.5

    def __init__(self, segments: Optional[Iterable[Segment]] = None, duration_ms: int = 0):
        self.segments = merge_segments(segments or [])
        self.duration_ms = int(duration_ms or 0)
        self._anchor: Optional[tuple[int, float]] = None

    def observe(self, pos_ms: int, wall_ms: float, playing: bool) -> bool:
        """Feed the current playback position. Returns True if watched time grew."""
        if not playing:
            self._anchor = None
            return False
        if self._anchor is None:
            self._anchor = (pos_ms, wall_ms)
            return False
        last_pos, last_wall = self._anchor
        self._anchor = (pos_ms, wall_ms)
        dp = pos_ms - last_pos
        dt = wall_ms - last_wall
        if dp <= 0 or dt <= 0:
            return False
        if dp > self.MAX_STEP_MS or dp > dt * self.SPEED_TOLERANCE + self.SLACK_MS:
            return False  # seek / fast-forward
        before = self.watched_ms()
        self.segments = merge_segments(self.segments + [[last_pos, pos_ms]])
        return self.watched_ms() > before

    def reset_anchor(self) -> None:
        self._anchor = None

    def watched_ms(self) -> int:
        total = 0
        for s, e in self.segments:
            if self.duration_ms:
                s, e = max(0, s), min(e, self.duration_ms)
            total += max(0, e - s)
        return total

    def fraction(self) -> float:
        if self.duration_ms <= 0:
            return 0.0
        return min(1.0, self.watched_ms() / self.duration_ms)

    def normalized_segments(self) -> list[list[float]]:
        """Segments as fractions of the duration, for drawing the watch bar."""
        if self.duration_ms <= 0:
            return []
        d = float(self.duration_ms)
        return [[max(0.0, s / d), min(1.0, e / d)] for s, e in self.segments]
