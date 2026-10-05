import QtQuick
import ".."

// Seven-segment LCD readout with unlit "ghost" segments behind the digits.
Rectangle {
    id: root
    property string text: "00:00"
    property int pixelSize: 22
    property color litColor: "#9BFF5E"
    property color backColor: "#14261A"
    readonly property string ghost: text.replace(/[0-9]/g, "8")

    implicitWidth: lit.implicitWidth + 18
    implicitHeight: lit.implicitHeight + 10
    radius: 6
    color: backColor
    border.width: 2
    border.color: Theme.ink

    Text {
        anchors { right: parent.right; rightMargin: 9; verticalCenter: parent.verticalCenter }
        text: root.ghost
        font.family: Theme.lcd
        font.pixelSize: root.pixelSize
        color: root.litColor
        opacity: 0.12
    }
    Text {
        id: lit
        anchors { right: parent.right; rightMargin: 9; verticalCenter: parent.verticalCenter }
        text: root.text
        font.family: Theme.lcd
        font.pixelSize: root.pixelSize
        color: root.litColor
    }
}
