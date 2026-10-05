import QtQuick
import ".."

// Seek bar. In TV mode it also shows which parts were really watched and the 70% goal.
Item {
    id: root
    property real position: 0      // ms
    property real duration: 0      // ms
    property var segments: []      // [[startFraction, endFraction], ...]
    property real threshold: 0.7
    property bool tvMode: true
    property bool completed: false
    readonly property bool dragging: mouse.pressed
    property real dragFraction: 0
    signal seekRequested(real ms)

    implicitHeight: 34
    readonly property real playedFraction: duration > 0 ? Math.min(1, position / duration) : 0

    Rectangle {
        id: track
        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
        height: 14
        radius: 7
        color: "#2E2650"
        border.width: 2
        border.color: Theme.ink
        clip: true

        Rectangle {
            height: parent.height
            width: parent.width * (root.dragging ? root.dragFraction : root.playedFraction)
            color: "#5F55A0"
        }

        Repeater {
            model: root.tvMode ? root.segments : []
            Rectangle {
                x: modelData[0] * track.width
                width: Math.max(1, (modelData[1] - modelData[0]) * track.width)
                height: track.height
                color: root.completed ? Theme.yellow : Theme.pink
            }
        }
        Rectangle {
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 2 }
            height: 3
            radius: 2
            color: "white"
            opacity: 0.25
        }
    }

    // the 70% goal marker
    Item {
        visible: root.tvMode
        x: track.x + track.width * root.threshold
        anchors.verticalCenter: track.verticalCenter
        Rectangle {
            width: 3
            height: 22
            x: -1
            y: -11
            color: Theme.yellow
            border.width: 1
            border.color: Theme.ink
        }
    }

    Image {
        id: knob
        source: Theme.asset("img/star_yellow.svg")
        sourceSize: Qt.size(30, 30)
        width: 30
        height: 30
        x: track.x + track.width * (root.dragging ? root.dragFraction : root.playedFraction) - width / 2
        anchors.verticalCenter: track.verticalCenter
        rotation: root.playedFraction * 720
    }

    Rectangle {
        visible: mouse.containsMouse && root.duration > 0
        x: Math.max(0, Math.min(root.width - width, mouse.mouseX - width / 2))
        y: -height - 4
        width: hoverText.implicitWidth + 12
        height: hoverText.implicitHeight + 6
        color: "#FFFFE1"
        border.width: 1
        border.color: Theme.ink
        Text {
            id: hoverText
            anchors.centerIn: parent
            text: Theme.timecode(Math.max(0, Math.min(1, mouse.mouseX / root.width)) * root.duration)
            font.family: Theme.pixel
            font.pixelSize: 12
            color: Theme.ink
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        function frac(x) { return Math.max(0, Math.min(1, x / width)) }
        onPressed: (e) => root.dragFraction = frac(e.x)
        onPositionChanged: (e) => { if (pressed) root.dragFraction = frac(e.x) }
        onReleased: (e) => {
            if (root.duration > 0)
                root.seekRequested(frac(e.x) * root.duration)
        }
    }
}
