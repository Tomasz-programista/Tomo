"""The bridge between the QML interface and the TV station logic."""

from __future__ import annotations

import hashlib
import os

from PySide6.QtCore import Property, QObject, QTimer, QUrl, Signal, Slot
from PySide6.QtGui import QDesktopServices
from PySide6.QtQml import QJSValue

from . import __version__, library
from .media import MediaProbe
from .schedule import WEEK, aired_count
from .station import Station
from .tracks import pick_track


def to_local(url_or_path: str) -> str:
    if not url_or_path:
        return ""
    url = QUrl(url_or_path)
    if url.isLocalFile():
        return os.path.normpath(url.toLocalFile())
    return os.path.normpath(url_or_path)


def file_url(path: str) -> str:
    return QUrl.fromLocalFile(path).toString() if path else ""


def plain(value):
    """Turn values coming from QML (QJSValue, nested maps/lists) into plain Python."""
    if isinstance(value, QJSValue):
        value = value.toVariant()
    if isinstance(value, dict):
        return {str(k): plain(v) for k, v in value.items()}
    if isinstance(value, (list, tuple)):
        return [plain(v) for v in value]
    return value


class Backend(QObject):
    channelsChanged = Signal()
    nowChanged = Signal()
    settingsChanged = Signal()
    statsChanged = Signal()
    probeDone = Signal("QVariant")
    episodeAired = Signal(str, str)  # channel title, episode label

    def __init__(self, station: Station, data_dir: str, parent=None):
        super().__init__(parent)
        self.station = station
        self.data_dir = data_dir
        self._channels: list = []
        self._session = None
        self._probes: set = set()
        self._aired = self._aired_counts()
        self._refresh()
        self._timer = QTimer(self)
        self._timer.timeout.connect(self._tick)
        self._timer.start(1000)

    # ------------------------------------------------------------ properties

    @Property(list, notify=channelsChanged)
    def channels(self):
        return self._channels

    @Property(float, notify=nowChanged)
    def now(self):
        return self.station.now()

    @Property("QVariant", notify=settingsChanged)
    def settings(self):
        return dict(self.station.settings)

    @Property(int, notify=statsChanged)
    def watchedCount(self):
        return int(self.station.data["stats"].get("completed", 0))

    @Property(str, constant=True)
    def dataDir(self):
        return self.data_dir

    @Property(str, constant=True)
    def version(self):
        return __version__

    @Property(int, constant=True)
    def week(self):
        return WEEK

    # ------------------------------------------------------------ internals

    def _aired_counts(self) -> dict:
        now = self.station.now()
        return {
            ch["id"]: aired_count(ch["premiere"], ch["interval"], len(ch["episodes"]), now)
            for ch in self.station.channels
        }

    def _view(self, ch: dict) -> dict:
        v = self.station.view(ch)
        v["coverUrl"] = file_url(v["cover"]) if v["cover"] and os.path.exists(v["cover"]) else ""
        v["thumbUrl"] = file_url(v["thumb"]) if v["thumb"] and os.path.exists(v["thumb"]) else ""
        return v

    def _refresh(self) -> None:
        channels = sorted(self.station.channels, key=lambda c: (c.get("number", 0), c.get("created", 0)))
        self._channels = [self._view(ch) for ch in channels]
        self.channelsChanged.emit()

    def _tick(self) -> None:
        self.nowChanged.emit()
        aired = self._aired_counts()
        if aired != self._aired:
            for ch in self.station.channels:
                old, new = self._aired.get(ch["id"], 0), aired.get(ch["id"], 0)
                if new > old:
                    self.episodeAired.emit(ch["title"], self.station.episode_label(ch, new - 1))
            self._aired = aired
            self._refresh()

    def _close_session(self, pos_ms=None) -> None:
        if self._session is not None:
            self._session.close(pos_ms)
            self._session = None
            self._refresh()

    # ------------------------------------------------------------ new channel wizard

    @Slot(str, result="QVariant")
    def scanFolder(self, url: str):
        folder = to_local(url)
        if not os.path.isdir(folder):
            return {"ok": False, "warning": "That folder doesn't exist."}
        result = library.scan_folder(folder)
        groups = library.match_external_subtitles(folder, [i.file for i in result.items])
        sub_groups = [
            {"label": label, "description": library.describe_sub_label(label), "count": len(matches)}
            for label, matches in sorted(groups.items(), key=lambda kv: (-len(kv[1]), kv[0]))
        ]
        return {
            "ok": bool(result.items),
            "folder": result.folder,
            "title": result.title,
            "items": [i.as_dict() for i in result.items],
            "cover": result.cover,
            "coverUrl": file_url(result.cover),
            "warning": result.warning,
            "subtitleGroups": sub_groups,
            "number": self.station.free_number(),
        }

    @Slot(str, str)
    def probe(self, folder: str, rel_file: str) -> None:
        path = os.path.join(to_local(folder), rel_file)
        digest = hashlib.sha1(path.encode("utf-8", "replace")).hexdigest()[:16]
        thumb = os.path.join(self.data_dir, "thumbs", digest + ".png")
        probe = MediaProbe(path, thumb, self)
        self._probes.add(probe)

        def done(result, probe=probe):
            self._probes.discard(probe)
            result = dict(result)
            result["thumbUrl"] = file_url(result.get("thumb", ""))
            self.probeDone.emit(result)

        probe.finished.connect(done)
        probe.start()

    @Slot("QVariant", result=str)
    def createChannel(self, cfg) -> str:
        cfg = plain(cfg) or {}
        episodes = [dict(e) for e in cfg.get("episodes") or []]
        if not episodes:
            return ""
        ch = self.station.add_channel(
            folder=to_local(cfg.get("folder", "")),
            title=str(cfg.get("title", "")),
            episodes=episodes,
            audio=cfg.get("audio") or None,
            subs=cfg.get("subs") or {"kind": "off"},
            interval=float(cfg.get("interval") or WEEK),
            number=int(cfg.get("number") or 0) or None,
            cover=to_local(cfg.get("cover", "")),
            thumb=to_local(cfg.get("thumb", "")),
        )
        self._aired = self._aired_counts()
        self._refresh()
        return ch["id"]

    # ------------------------------------------------------------ channel management

    @Slot(str, result="QVariant")
    def channel(self, channel_id: str):
        ch = self.station.get(channel_id)
        return self._view(ch) if ch else {}

    @Slot(str)
    def deleteChannel(self, channel_id: str) -> None:
        if self._session and self._session.channel["id"] == channel_id:
            self._close_session()
        self.station.delete_channel(channel_id)
        self._aired = self._aired_counts()
        self._refresh()

    @Slot(str)
    def restartChannel(self, channel_id: str) -> None:
        self.station.restart_channel(channel_id)
        self._aired = self._aired_counts()
        self._refresh()

    @Slot(str, str)
    def renameChannel(self, channel_id: str, title: str) -> None:
        if title.strip():
            self.station.update_channel(channel_id, title=title.strip())
            self._refresh()

    @Slot(str, str, result=bool)
    def relocateChannel(self, channel_id: str, url: str) -> bool:
        """Point a channel at a moved folder (e.g. an external drive got a new letter)."""
        ch = self.station.get(channel_id)
        folder = to_local(url)
        if not ch or not os.path.isdir(folder):
            return False
        found = sum(os.path.exists(os.path.join(folder, e["file"])) for e in ch["episodes"])
        if not found:
            return False
        self.station.update_channel(channel_id, folder=folder)
        self._refresh()
        return True

    @Slot(str)
    def openChannelFolder(self, channel_id: str) -> None:
        ch = self.station.get(channel_id)
        if ch:
            QDesktopServices.openUrl(QUrl.fromLocalFile(ch["folder"]))

    # ------------------------------------------------------------ watching

    def _external_options(self, folder: str, rel_file: str) -> list:
        groups = library.match_external_subtitles(folder, [rel_file])
        return [
            {"label": label, "description": library.describe_sub_label(label), "path": matches[rel_file]}
            for label, matches in sorted(groups.items())
            if rel_file in matches
        ]

    @Slot(str, int, result="QVariant")
    def startEpisode(self, channel_id: str, index: int):
        self._close_session()
        ch = self.station.get(channel_id)
        if not ch:
            return {"ok": False, "error": "This channel doesn't exist anymore."}
        path = self.station.episode_path(ch, index) if 0 <= index < len(ch["episodes"]) else ""
        if not path or not os.path.exists(path):
            return {"ok": False, "error": "Can't find the video file:\n" + (path or "?") + "\n\nDid the folder move? Use 'Change folder…' on the channel."}
        session = self.station.start_session(channel_id, index)
        if session is None:
            return {"ok": False, "error": "This episode hasn't aired yet! Episodes air once a week and must be watched in order ☆"}
        self._session = session
        ep = ch["episodes"][index]
        view = self._view(ch)
        return {
            "ok": True,
            "mode": "tv",
            "url": file_url(path),
            "channelId": ch["id"],
            "channelNumber": ch["number"],
            "channelTitle": ch["title"],
            "index": index,
            "label": self.station.episode_label(ch, index),
            "name": ep.get("name") or os.path.basename(ep["file"]),
            "total": len(ch["episodes"]),
            "isFinale": index == len(ch["episodes"]) - 1,
            "isRerun": session.rerun,
            "resume": session.resume_position(),
            "audio": ch.get("audio"),
            "subs": ch.get("subs") or {"kind": "off"},
            "externalOptions": self._external_options(ch["folder"], ep["file"]),
            "fraction": session.tracker.fraction(),
            "segments": session.tracker.normalized_segments(),
            "thumbUrl": view["thumbUrl"] or view["coverUrl"],
        }

    @Slot(str, result="QVariant")
    def freePlay(self, url: str):
        self._close_session()
        path = to_local(url)
        if not os.path.isfile(path):
            return {"ok": False, "error": "Can't open that file."}
        folder, name = os.path.split(path)
        return {
            "ok": True,
            "mode": "free",
            "url": file_url(path),
            "channelId": "",
            "channelNumber": 0,
            "channelTitle": "Free Play",
            "index": -1,
            "label": "",
            "name": library.clean_name(os.path.splitext(name)[0]),
            "total": 0,
            "isFinale": False,
            "isRerun": False,
            "resume": 0,
            "audio": None,
            "subs": {"kind": "auto"},
            "externalOptions": self._external_options(folder, name),
            "fraction": 0,
            "segments": [],
            "thumbUrl": "",
        }

    @Slot(int, int, bool, result="QVariant")
    def reportProgress(self, pos_ms: int, dur_ms: int, playing: bool):
        if self._session is None:
            return {}
        result = self._session.observe(pos_ms, dur_ms, playing)
        if result["newlyCompleted"]:
            self._refresh()
            self.statsChanged.emit()
        return result

    @Slot()
    def notifySeek(self) -> None:
        if self._session is not None:
            self._session.seeked()

    @Slot(result="QVariant")
    def currentChannel(self):
        """The channel being watched, freshly computed (for the end-of-episode card)."""
        if self._session is None:
            return {}
        view = self._view(self._session.channel)
        view["episodeDone"] = bool(self._session.episode.get("done"))
        view["episodeFraction"] = self._session.tracker.fraction()
        return view

    @Slot(int)
    def closeEpisode(self, pos_ms: int) -> None:
        self._close_session(pos_ms)

    @Slot("QVariant", "QVariant", result=int)
    def pickAudio(self, pref, tracks) -> int:
        return pick_track(plain(pref) or None, plain(tracks) or [])

    @Slot("QVariant", "QVariant", result=int)
    def pickSubtitle(self, pref, tracks) -> int:
        return pick_track(plain(pref) or None, plain(tracks) or [])

    @Slot(str, "QVariant", "QVariant")
    def rememberTracks(self, channel_id: str, audio, subs) -> None:
        if channel_id and self.station.get(channel_id):
            self.station.update_channel(channel_id, audio=plain(audio) or None, subs=plain(subs) or {"kind": "off"})

    # ------------------------------------------------------------ settings & misc

    @Slot(str, "QVariant")
    def setSetting(self, key: str, value) -> None:
        self.station.set_setting(key, plain(value))
        self.settingsChanged.emit()

    @Slot()
    def openDataFolder(self) -> None:
        os.makedirs(self.data_dir, exist_ok=True)
        QDesktopServices.openUrl(QUrl.fromLocalFile(self.data_dir))

    @Slot(str, result=bool)
    def isFolder(self, url: str) -> bool:
        return os.path.isdir(to_local(url))

    @Slot(str, result=str)
    def localPath(self, url: str) -> str:
        return to_local(url)

    @Slot(str, result=str)
    def fileUrl(self, path: str) -> str:
        return file_url(path)

    def shutdown(self) -> None:
        self._close_session()
        self.station.save()
