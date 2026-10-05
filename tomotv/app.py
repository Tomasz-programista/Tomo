"""Starts TOMO-TV."""

from __future__ import annotations

import json
import logging
import os
import sys
import time
import traceback

# In the packaged .exe everything lives next to the bundled Python (sys._MEIPASS).
ROOT = getattr(sys, "_MEIPASS", os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
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


def _smoke_test(app, root, relay, video: str, warnings: list, report_path: str) -> None:
    """--smoke-test [video]: start, (play the video), check nothing is broken, quit.

    Used by the Windows build to make sure the packaged app really works.
    Exit code 0 = fine. Details go to smoke-test.txt in the data folder.
    """
    from PySide6.QtCore import QTimer, QUrl, qVersion
    from PySide6.QtQml import QQmlEngine, QQmlExpression

    context = QQmlEngine.contextForObject(root)
    state = {"loaded": False, "subtitle": "", "deadline": 0.0}

    def js(code):
        value = QQmlExpression(context, root, code).evaluate()
        return value[0] if isinstance(value, tuple) else value

    def finish():
        problems = list(warnings)
        if video and not state["loaded"]:
            problems.append("the video did not load")
        if video and not state["subtitle"]:
            problems.append("no subtitle text came through")
        lines = [f"Qt {qVersion()} on {sys.platform}", f"video loaded: {state['loaded']}",
                 f"subtitle: {state['subtitle']!r}"] + [f"PROBLEM: {p}" for p in problems]
        lines.append("RESULT: " + ("FAIL" if problems else "OK"))
        with open(report_path, "w", encoding="utf-8") as f:
            f.write("\n".join(lines) + "\n")
        app.exit(1 if problems else 0)

    def poll():
        state["loaded"] = bool(js("playerOpen && rootStack.currentItem.loaded"))
        state["subtitle"] = state["subtitle"] or relay.property("bottom")
        if (state["loaded"] and state["subtitle"]) or time.monotonic() > state["deadline"]:
            finish()
        else:
            QTimer.singleShot(250, poll)

    def start():
        js("backend.setSetting('screen', 'crt')")
        if not video:
            QTimer.singleShot(2000, finish)
            return
        js("freePlay(" + json.dumps(QUrl.fromLocalFile(os.path.abspath(video)).toString()) + ")")
        state["deadline"] = time.monotonic() + 20
        QTimer.singleShot(500, poll)

    QTimer.singleShot(1500, start)
    QTimer.singleShot(60000, lambda: app.exit(2))  # never hang a build machine


def main() -> int:
    os.environ.setdefault("QT_LOGGING_RULES", "qt.multimedia.ffmpeg=false;qt.multimedia.playbackengine.codec=false")
    args = sys.argv[1:]
    smoke = "--smoke-test" in args
    smoke_video = next((a for a in args if not a.startswith("--")), "") if smoke else ""

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
    app = QApplication(sys.argv[:1])
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

    qml_warnings: list = []

    def on_warnings(warnings):
        for w in warnings:
            logging.warning(w.toString())
            qml_warnings.append(w.toString())

    engine = QQmlApplicationEngine()
    engine.warnings.connect(on_warnings)
    ctx = engine.rootContext()
    ctx.setContextProperty("backend", backend)
    ctx.setContextProperty("subtitleRelay", relay)
    ctx.setContextProperty("appFonts", _load_fonts())
    ctx.setContextProperty("assetsUrl", QUrl.fromLocalFile(ASSETS + os.sep).toString())
    ctx.setContextProperty("shadersUrl", QUrl.fromLocalFile(SHADER_DIR + os.sep).toString())
    engine.load(QUrl.fromLocalFile(os.path.join(QML_DIR, "Main.qml")))
    if not engine.rootObjects():
        if smoke:
            with open(os.path.join(data_dir, "smoke-test.txt"), "w", encoding="utf-8") as f:
                f.write("\n".join(qml_warnings) + "\nRESULT: FAIL (interface did not load)\n")
        else:
            QMessageBox.critical(None, APP_NAME, "TOMO-TV could not start its interface.\nSee tomotv.log in:\n" + data_dir)
        return 1

    if smoke:
        _smoke_test(app, engine.rootObjects()[0], relay, smoke_video, qml_warnings,
                    os.path.join(data_dir, "smoke-test.txt"))

    code = app.exec()
    backend.shutdown()
    del engine
    return code
