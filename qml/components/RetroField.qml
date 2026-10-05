import QtQuick
import QtQuick.Controls.Basic
import ".."

TextField {
    id: control
    font.family: Theme.body
    font.pixelSize: 16
    color: Theme.ink
    selectionColor: Theme.pink
    selectedTextColor: "white"
    placeholderTextColor: "#9A90C0"
    leftPadding: 10
    rightPadding: 10
    implicitHeight: 38

    background: Rectangle {
        radius: 7
        color: "white"
        border.width: control.activeFocus ? 3 : 2
        border.color: control.activeFocus ? Theme.hotPink : Theme.ink
        Rectangle {
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 3 }
            height: 3
            radius: 2
            color: "#EDE6FF"
        }
    }
}
