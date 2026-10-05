import QtQuick
import QtQuick.Controls.Basic
import ".."

Slider {
    id: control
    implicitWidth: 140
    implicitHeight: 26

    background: Rectangle {
        x: control.leftPadding
        y: control.topPadding + control.availableHeight / 2 - height / 2
        width: control.availableWidth
        height: 10
        radius: 5
        color: "#EDE6FF"
        border.width: 2
        border.color: Theme.ink
        Rectangle {
            width: control.visualPosition * parent.width
            height: parent.height
            radius: 5
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: Theme.cyan }
                GradientStop { position: 1; color: Theme.pink }
            }
            border.width: 2
            border.color: Theme.ink
        }
    }

    handle: Image {
        x: control.leftPadding + control.visualPosition * (control.availableWidth - width)
        y: control.topPadding + control.availableHeight / 2 - height / 2
        width: 24
        height: 24
        source: Theme.asset("img/heart.svg")
        sourceSize: Qt.size(24, 24)
        scale: control.pressed ? 1.2 : 1.0
    }
}
