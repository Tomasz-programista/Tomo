"""Starts TOMO-TV."""

from __future__ import annotations

import logging
import os
import sys
import traceback

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSETS = os.path.join(ROOT, "assets")
QML_DIR = os.path.join(ROOT, "qml")
SHADER_DIR = os.path.join(ROOT, "shaders")

FONT_FILES = {
    "pixel": "DotGothic16-Regular.ttf",
    "body": "Mplus1-Medium.otf",
    "bodyBold": "Mplus1-ExtraBold.otf",
    "tiny": "misaki_gothic.ttf",
    "lcd": "DSEG7Classic-Bold.ttf",
}


def _data_dir() -> str:
    from PySide6.QtCore import QStandardPaths

    custom = os.environ.get("TOMOTV_DATA_DIR")
    if custom:
        return os.path.abspath(custom)
    return QStandardPaths.writableLocation(QStandardPaths.StandardLocation.AppDataLocation)


def _load_fonts() -> dict:
    from PySide6.QtGui import QFontDatabase

    families = {}
    for key, name in FONT_FILES.items():
        font_id = QFontDatabase.addApplicationFont(os.path.join(ASSETS, "fonts", name))
        found = QFontDatabase.applicationFontFamilies(font_id) if font_id >= 0 else []
        families[key] = found[0] if found else "sans-serif"
    families["bodyBold"] = families["body"]  # same family, picked by weight
    return families


def main() -> int:
    os.environ.setdefault("QT_LOGGING_RULES", "qt.multimedia.ffmpeg=false;qt.multimedia.playbackengine.codec=false")

    from PySide6.QtCore import QUrl, Qt
    from PySide6.QtGui import QIcon
    from PySide6.QtQml import QQmlApplicationEngine
    from PySide6.QtQuick import QQuickWindow  # noqa: F401  (registers the window type for PySide)
    from PySide6.QtQuickControls2 import QQuickStyle
    from PySide6.QtWidgets import QApplication, QMessageBox

    from . import APP_NAME, __version__
    from .backend import Backend
    from .media import SubtitleRelay
    from .station import Station
    from .store import Store

    if sys.platform == "win32":
        # Show TOMO-TV's own icon in the taskbar instead of Python's.
        try:
            import ctypes

            ctypes.windll.shell32.SetCurrentProcessExplicitAppUserModelID("TomoTV.TomoTV")
        except (AttributeError, OSError):
            pass

    QQuickStyle.setStyle("Basic")
    QApplication.setHighDpiScaleFactorRoundingPolicy(Qt.HighDpiScaleFactorRoundingPolicy.PassThrough)
    app = QApplication(sys.argv)
    app.setApplicationName(APP_NAME)
    app.setOrganizationName("TomoTV")
    app.setApplicationVersion(__version__)
    app.setWindowIcon(QIcon(os.path.join(ASSETS, "img", "icon.png")))

    data_dir = _data_dir()
    os.makedirs(data_dir, exist_ok=True)
    logging.basicConfig(
        filename=os.path.join(data_dir, "tomotv.log"),
        level=logging.INFO,
        format="%(asctime)s %(levelname)s %(message)s",
    )

    def excepthook(kind, value, tb):
        text = "".join(traceback.format_exception(kind, value, tb))
        logging.error(text)
        sys.__stderr__ and sys.__stderr__.write(text)

    sys.excepthook = excepthook

    station = Station(Store(os.path.join(data_dir, "state.json")))
    backend = Backend(station, data_dir)
    relay = SubtitleRelay()

    engine = QQmlApplicationEngine()
    engine.warnings.connect(lambda warnings: [logging.warning(w.toString()) for w in warnings])
    ctx = engine.rootContext()
    ctx.setContextProperty("backend", backend)
    ctx.setContextProperty("subtitleRelay", relay)
    ctx.setContextProperty("appFonts", _load_fonts())
    ctx.setContextProperty("assetsUrl", QUrl.fromLocalFile(ASSETS + os.sep).toString())
    ctx.setContextProperty("shadersUrl", QUrl.fromLocalFile(SHADER_DIR + os.sep).toString())
    engine.load(QUrl.fromLocalFile(os.path.join(QML_DIR, "Main.qml")))
    if not engine.rootObjects():
        QMessageBox.critical(None, APP_NAME, "TOMO-TV could not start its interface.\nSee tomotv.log in:\n" + data_dir)
        return 1

    code = app.exec()
    backend.shutdown()
    del engine
    return code
