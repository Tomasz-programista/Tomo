# PyInstaller recipe for a self-contained TOMO-TV build:
#     pyinstaller packaging/tomotv.spec
# Produces dist/TomoTV/ with TomoTV(.exe) inside. Used by .github/workflows/build-windows.yml.
import glob
import os
import re

ROOT = os.path.abspath(os.path.join(SPECPATH, ".."))

datas = [
    (os.path.join(ROOT, "qml"), "qml"),
    (os.path.join(ROOT, "assets"), "assets"),
]
datas += [(path, "shaders") for path in glob.glob(os.path.join(ROOT, "shaders", "*.qsb"))]

a = Analysis(
    [os.path.join(ROOT, "tomotv.py")],
    pathex=[ROOT],
    datas=datas,
    hiddenimports=["PySide6.QtSvg"],
    excludes=["tkinter", "unittest", "pydoc", "PySide6.QtWebEngineCore", "PySide6.QtWebEngineWidgets",
              "PySide6.QtWebEngineQuick", "PySide6.Qt3DCore", "PySide6.QtQuick3D", "PySide6.QtCharts",
              "PySide6.QtDataVisualization", "PySide6.QtGraphs", "PySide6.QtPdf", "PySide6.QtLocation"],
)

# PyInstaller collects every QML module Qt ships. TOMO-TV only needs QtQuick (+Controls Basic,
# Layouts, Particles, Dialogs), QtMultimedia and QtCore, so drop the big ones we never load.
UNUSED = re.compile(
    r"(?i)(webengine|webview|webchannel|websockets|qt6?3d|quick3d|qt6?charts|datavisualization|qt6?graphs|"
    r"qt6?location|qt6?positioning|qt6?pdf|virtualkeyboard|qt6?sensors|remoteobjects|scxml|statemachine|"
    r"texttospeech|bluetooth|qt6?nfc|spatialaudio|designer|qt6?help|quicktest|qt6?test|lottie|"
    r"quicktimeline|vectorimage|qt6?sql|localstorage|xmllistmodel|wavefrontmesh|"
    r"labs(animation|sharedimage|stylekit|synchronizer|settings|platform)|labs[/\\](animation|sharedimage|"
    r"stylekit|synchronizer|settings|platform|wavefrontmesh|assetdownloader)|"
    r"controls2(material|universal|imagine|fusion|fluentwinui3)|"
    r"controls[/\\](material|universal|imagine|fusion|fluentwinui3|windows|macos|ios)|nativestyle|"
    r"qt5compat|opcua|mqtt|coap|serialbus|httpserver|grpc|protobuf|scene[23]d)"
)


def keep(entry):
    dest, src = entry[0], entry[1]
    return not (UNUSED.search(dest) or UNUSED.search(src))


a.binaries = [e for e in a.binaries if keep(e)]
a.datas = [e for e in a.datas if keep(e)]

pyz = PYZ(a.pure)

exe = EXE(
    pyz,
    a.scripts,
    [],
    exclude_binaries=True,
    name="TomoTV",
    icon=os.path.join(ROOT, "packaging", "tomotv.ico"),
    console=False,
    upx=False,
)

coll = COLLECT(exe, a.binaries, a.datas, name="TomoTV", upx=False)
