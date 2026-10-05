import QtQuick
import ".."

// Small toggle chip.
Rectangle {
    id: chip
    property string text: ""
    property bool selected: false
    signal clicked()
    implicitWidth: label.implicitWidth + 20
    implicitHeight: 30
    radius: 15
    color: selected ? Theme.hotPink : (mouse.containsMouse ? "#FFF0F8" : "white")
    border.width: 2
    border.color: Theme.ink
    Text {
        id: label
        anchors.centerIn: parent
        text: chip.text
        font.family: Theme.pixel
        font.pixelSize: 13
        color: chip.selected ? "white" : Theme.ink
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            Sfx.click()
            chip.clicked()
        }
    }
}
