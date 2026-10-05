"""Qt multimedia helpers: subtitle relay, media probing and thumbnail grabbing."""

from __future__ import annotations

import os

from PySide6.QtCore import Property, QObject, Qt, QTimer, QUrl, Signal, Slot
from PySide6.QtGui import QImage
from PySide6.QtMultimedia import QMediaMetaData, QMediaPlayer, QVideoFrame, QVideoSink

from . import subtitles
from .tracks import describe


class SubtitleRelay(QObject):
    """Sits between the media player and the VideoOutput.

    Every video frame passes through here: the subtitle text Qt attached to it
    (or the line from an external subtitle file at that time) is taken off the
    frame and exposed as `top` / `bottom` rich text, so QML can draw it in
    fansub style *inside* the emulated screen.
    """

    textChanged = Signal()
    targetChanged = Signal()
    modeChanged = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._sink = QVideoSink(self)
        self._target = None
        self._top = ""
        self._bottom = ""
        self._mode = "off"  # off | embedded | external
        self._track = None
        # Queued: frames are handled on the GUI thread, so Python never runs on Qt's video
        # thread (stopping playback while Python holds the GIL would otherwise deadlock).
        self._sink.videoFrameChanged.connect(self._on_frame, Qt.ConnectionType.QueuedConnection)

    @Property(QObject, constant=True)
    def sink(self):
        return self._sink

    def _get_target(self):
        return self._target

    def _set_target(self, target):
        if target is not self._target:
            self._target = target
            self.targetChanged.emit()

    target = Property(QObject, _get_target, _set_target, notify=targetChanged)

    @Property(str, notify=textChanged)
    def top(self):
        return self._top

    @Property(str, notify=textChanged)
    def bottom(self):
        return self._bottom

    @Property(str, notify=modeChanged)
    def mode(self):
        return self._mode

    @Slot(str)
    def setMode(self, mode: str) -> None:
        if mode not in ("off", "embedded", "external"):
            mode = "off"
        if mode != self._mode:
            self._mode = mode
            self.modeChanged.emit()
        if mode == "off":
            self._set_text("", "")

    @Slot(str, result=bool)
    def loadExternal(self, path: str) -> bool:
        try:
            self._track = subtitles.CueTrack(subtitles.parse_file(path))
            return True
        except (OSError, ValueError):
            self._track = None
            return False

    def _set_text(self, top: str, bottom: str) -> None:
        if top != self._top or bottom != self._bottom:
            self._top, self._bottom = top, bottom
            self.textChanged.emit()

    def _on_frame(self, frame: QVideoFrame) -> None:
        if frame.isValid():
            raw = frame.subtitleText()
            if self._mode == "embedded":
                rich, top, _ = subtitles.format_text(raw) if raw else ("", False, False)
                self._set_text(rich if top else "", "" if top else rich)
            elif self._mode == "external" and self._track is not None:
                self._set_text(*self._track.text_at(frame.startTime() // 1000))
            if raw:
                frame.setSubtitleText("")
        target = self._target
        if target is not None:
            target.setVideoFrame(frame)


def _meta(track, key) -> str:
    try:
        return track.stringValue(key) or ""
    except Exception:  # noqa: BLE001 - some keys can't be converted on some platforms
        return ""


class MediaProbe(QObject):
    """Opens a file once to list its audio/subtitle tracks and grab a thumbnail."""

    finished = Signal(dict)

    THUMB_POSITIONS = (0.3, 0.5, 0.15, 0.7)

    def __init__(self, path: str, thumb_path: str = "", parent=None):
        super().__init__(parent)
        self.path = path
        self.thumb_path = thumb_path
        self.result = {"ok": False, "path": path, "error": "", "duration": 0, "audio": [], "subs": [], "video": "", "thumb": ""}
        self._attempts = list(self.THUMB_POSITIONS)
        self._target_us = None
        self._loaded = False
        self._done = False
        self.player = QMediaPlayer(self)
        self.sink = QVideoSink(self)
        self.player.setVideoSink(self.sink)
        self.player.mediaStatusChanged.connect(self._on_status)
        self.player.errorOccurred.connect(self._on_error)
        self.sink.videoFrameChanged.connect(self._on_frame, Qt.ConnectionType.QueuedConnection)
        self.timer = QTimer(self)
        self.timer.setSingleShot(True)
        self.timer.timeout.connect(self._finish)

    def start(self) -> None:
        self.timer.start(15000)
        self.player.setSource(QUrl.fromLocalFile(self.path))

    def _on_error(self, _error, message: str) -> None:
        if not self._loaded:
            self.result["error"] = message or "This file could not be opened."
            self._finish()

    def _on_status(self, status) -> None:
        if status == QMediaPlayer.MediaStatus.InvalidMedia and not self._loaded:
            self.result["error"] = self.result["error"] or "This file could not be opened."
            self._finish()
        elif status == QMediaPlayer.MediaStatus.LoadedMedia and not self._loaded:
            self._loaded = True
            self._collect()
            if self.thumb_path and self.player.hasVideo() and self.player.duration() > 0:
                self._next_attempt()
            else:
                self._finish()

    def _collect(self) -> None:
        K = QMediaMetaData.Key
        audio = []
        for i, t in enumerate(self.player.audioTracks()):
            lang, title, codec = _meta(t, K.Language), _meta(t, K.Title), _meta(t, K.AudioCodec)
            audio.append({"index": i, "lang": lang, "title": title, "codec": codec, "label": describe(i, lang, title, codec)})
        subs = []
        for i, t in enumerate(self.player.subtitleTracks()):
            lang, title = _meta(t, K.Language), _meta(t, K.Title)
            subs.append({"index": i, "lang": lang, "title": title, "label": describe(i, lang, title)})
        video = ""
        tracks = self.player.videoTracks()
        if tracks:
            codec, res = _meta(tracks[0], K.VideoCodec), _meta(tracks[0], K.Resolution)
            video = " · ".join(x for x in (codec, res.replace(" ", "")) if x)
        self.result.update(ok=True, duration=self.player.duration(), audio=audio, subs=subs, video=video)

    def _next_attempt(self) -> None:
        if not self._attempts:
            self._finish()
            return
        pos = int(self.player.duration() * self._attempts.pop(0))
        self._target_us = pos * 1000
        self.player.setPosition(pos)
        self.player.play()

    def _on_frame(self, frame: QVideoFrame) -> None:
        if self._done or self._target_us is None or not frame.isValid():
            return
        if frame.startTime() < self._target_us - 5_000_000:
            return  # a frame from before the seek
        image = frame.toImage()
        if image.isNull():
            return
        self._target_us = None
        if _brightness(image) < 0.08 and self._attempts:
            self.player.pause()
            self._next_attempt()
            return
        image = image.scaled(480, 270, Qt.AspectRatioMode.KeepAspectRatio, Qt.TransformationMode.SmoothTransformation)
        os.makedirs(os.path.dirname(self.thumb_path), exist_ok=True)
        if image.save(self.thumb_path, "PNG"):
            self.result["thumb"] = self.thumb_path
        self._finish()

    def _finish(self) -> None:
        if self._done:
            return
        self._done = True
        self.timer.stop()
        self.player.stop()
        self.finished.emit(self.result)
        self.deleteLater()


def _brightness(image: QImage) -> float:
    small = image.scaled(32, 18)
    total = 0.0
    for y in range(small.height()):
        for x in range(small.width()):
            total += small.pixelColor(x, y).lightnessF()
    return total / max(1, small.width() * small.height())
