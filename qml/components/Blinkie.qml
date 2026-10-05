import QtQuick
import ".."

// A 150x20 "blinkie" badge.
Rectangle {
    id: root
    property string text: "BLINKIE"
    property var colors: [Theme.pink, Theme.purple, Theme.cyan]
    property int step: 0
    implicitWidth: 156
    implicitHeight: 22
    radius: 3
    border.width: 1
    border.color: Theme.ink
    color: colors[step % colors.length]

    Timer {
        interval: 520
        running: true
        repeat: true
        onTriggered: root.step++
    }

    Row {
        anchors.centerIn: parent
        spacing: 4
        Text {
            text: (root.step % 2) ? "☆" : "★"
            font.family: Theme.pixel
            font.pixelSize: 13
            color: Theme.yellow
            style: Text.Outline
            styleColor: Theme.ink
        }
        Text {
            text: root.text
            font.family: Theme.pixel
            font.pixelSize: 13
            color: "white"
            style: Text.Outline
            styleColor: Theme.ink
        }
        Text {
            text: (root.step % 2) ? "★" : "☆"
            font.family: Theme.pixel
            font.pixelSize: 13
            color: Theme.yellow
            style: Text.Outline
            styleColor: Theme.ink
        }
    }
}
