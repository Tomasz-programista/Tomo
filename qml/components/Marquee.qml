import QtQuick
import ".."

// <marquee> lives on.
Item {
    id: root
    property string text: ""
    property real speed: 70  // pixels per second
    property color color: Theme.yellow
    property int pixelSize: 15
    property bool running: true
    clip: true
    implicitHeight: label.implicitHeight

    Text {
        id: label
        anchors.verticalCenter: parent.verticalCenter
        text: root.text
        font.family: Theme.pixel
        font.pixelSize: root.pixelSize
        color: root.color
        x: root.width

        NumberAnimation on x {
            id: anim
            running: root.running && root.width > 0 && label.width > 0
            from: root.width
            to: -label.width
            duration: Math.max(1, (root.width + label.width) / root.speed * 1000)
            loops: Animation.Infinite
        }
    }
}
