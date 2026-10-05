import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Dialogs
import "."
import "components"
import "pages"

ApplicationWindow {
    id: window
    width: Math.min(1280, Screen.desktopAvailableWidth - 40)
    height: Math.min(800, Screen.desktopAvailableHeight - 60)
    minimumWidth: 900
    minimumHeight: 600
    visible: true
    title: "TOMO☆TV ～友テレビ～"
    color: "#FFE8F4"

    property bool playerOpen: rootStack.depth > 1
    readonly property var settings: backend.settings

    onClosing: shutdownPlayer()

    // ~ navigation API (also used by the test tour) ~
    function showPage(name) {
        if (playerOpen)
            closePlayer()
        shell.showPage(name)
    }

    function watch(channelId, index) {
        shutdownPlayer()
        var info = backend.startEpisode(channelId, index)
        if (!info.ok) {
            Sfx.error()
            toasts.show("Can't watch that yet!", info.error, "info")
            closePlayer()
            return false
        }
        openPlayer(info)
        return true
    }

    function freePlay(url) {
        shutdownPlayer()
        var info = backend.freePlay(url)
        if (!info.ok) {
            Sfx.error()
            toasts.show("Oops!", info.error, "info")
            closePlayer()
            return false
        }
        openPlayer(info)
        return true
    }

    // Stop the open episode (saves progress) before anything else starts.
    function shutdownPlayer() {
        if (playerOpen && rootStack.currentItem && rootStack.currentItem.shutdown)
            rootStack.currentItem.shutdown()
    }

    function openPlayer(info) {
        if (playerOpen)
            rootStack.pop(null, StackView.Immediate)
        Sfx.tvOn()
        rootStack.push(playerPage, { info: info })
    }

    function closePlayer() {
        if (!playerOpen)
            return
        shutdownPlayer()
        if (window.visibility === Window.FullScreen)
            window.showNormal()
        rootStack.pop()
    }

    function toast(title, message, kind) {
        toasts.show(title, message, kind)
    }

    function pickFreePlayFile() {
        freePlayDialog.open()
    }

    Image {
        anchors.fill: parent
        source: Theme.asset("img/tile.svg")
        sourceSize: Qt.size(64, 64)
        fillMode: Image.Tile
        smooth: false
    }

    StackView {
        id: rootStack
        anchors.fill: parent
        initialItem: Shell { id: shell }
        pushEnter: Transition {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 220 }
            NumberAnimation { property: "scale"; from: 0.96; to: 1; duration: 220; easing.type: Easing.OutQuad }
        }
        pushExit: Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 180 } }
        popEnter: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 180 } }
        popExit: Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 160 } }
    }

    Component {
        id: playerPage
        PlayerPage {}
    }

    FileDialog {
        id: freePlayDialog
        title: "Pick a video to play"
        nameFilters: ["Videos (*.mkv *.mp4 *.m4v *.avi *.webm *.mov *.wmv *.flv *.ogm *.ts *.m2ts *.mpg *.mpeg *.rmvb)", "All files (*)"]
        onAccepted: window.freePlay(selectedFile)
    }

    DropArea {
        anchors.fill: parent
        enabled: !window.playerOpen
        onDropped: (drop) => {
            if (!drop.hasUrls || drop.urls.length === 0)
                return
            var url = drop.urls[0]
            if (backend.isFolder(url)) {
                window.showPage("newchannel")
                shell.currentPage.loadFolder(url)
            } else {
                window.freePlay(url)
            }
        }
    }

    Toasts {
        id: toasts
        anchors { right: parent.right; bottom: parent.bottom; rightMargin: 16; bottomMargin: window.playerOpen ? 132 : 48 }
        z: 50
    }

    CursorTrail {
        anchors.fill: parent
        z: 60
        active: window.settings.sparkles && !window.playerOpen
    }

    Connections {
        target: backend
        function onEpisodeAired(title, label) {
            Sfx.onAir()
            toasts.show("★ NOW ON AIR! ★", title + " " + label + " just started airing ☆", "onair")
        }
    }
}
