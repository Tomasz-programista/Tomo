"""Broadcast rules for TV mode.

Episodes air on a fixed timetable that starts at the channel's premiere:
episode 1 airs right away, episode 2 one interval (a week) later, and so on.
If you skip a week the aired episodes stack up, but they still have to be
watched in order: an episode only becomes watchable once every episode before
it has been completed (at least WATCH_THRESHOLD of it actually watched).
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Optional, Sequence

DAY = 24 * 60 * 60
WEEK = 7 * DAY
WATCH_THRESHOLD = 0.70

# Episode states
WATCHED = "watched"    # completed, can be re-run any time
NEXT = "next"          # aired and next in line: watchable now
QUEUED = "queued"      # aired, but an earlier episode has to be watched first
UPCOMING = "upcoming"  # has not aired yet


def air_time(premiere: float, index: int, interval: float = WEEK) -> float:
    """Unix time at which episode `index` (0-based) airs."""
    return premiere + index * interval


def aired_count(premiere: float, interval: float, total: int, now: float) -> int:
    """How many episodes have aired by `now`."""
    if total <= 0 or now < premiere:
        return 0
    return min(total, int((now - premiere) // interval) + 1)


def first_unwatched(completed: Sequence[bool]) -> Optional[int]:
    for i, done in enumerate(completed):
        if not done:
            return i
    return None


def episode_states(completed: Sequence[bool], premiere: float, interval: float, now: float) -> list[str]:
    aired = aired_count(premiere, interval, len(completed), now)
    nxt = first_unwatched(completed)
    states = []
    for i, done in enumerate(completed):
        if done:
            states.append(WATCHED)
        elif i == nxt:
            states.append(NEXT if i < aired else UPCOMING)
        else:
            states.append(QUEUED if i < aired else UPCOMING)
    return states


def can_play(completed: Sequence[bool], premiere: float, interval: float, now: float, index: int) -> bool:
    if not 0 <= index < len(completed):
        return False
    return episode_states(completed, premiere, interval, now)[index] in (WATCHED, NEXT)


@dataclass
class Summary:
    total: int
    watched: int
    aired: int
    next_index: Optional[int]  # first episode that still needs watching
    can_watch: bool            # next_index has aired, so it's on air right now
    backlog: int               # aired episodes that still need watching
    next_air: Optional[float]  # when the next not-yet-aired episode airs
    finished: bool


def summarize(completed: Sequence[bool], premiere: float, interval: float, now: float) -> Summary:
    total = len(completed)
    aired = aired_count(premiere, interval, total, now)
    nxt = first_unwatched(completed)
    watched = sum(1 for c in completed if c)
    backlog = sum(1 for i in range(aired) if not completed[i])
    next_air = air_time(premiere, aired, interval) if aired < total else None
    return Summary(
        total=total,
        watched=watched,
        aired=aired,
        next_index=nxt,
        can_watch=nxt is not None and nxt < aired,
        backlog=backlog,
        next_air=next_air,
        finished=nxt is None and total > 0,
    )
