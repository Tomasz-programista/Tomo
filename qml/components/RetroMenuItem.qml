import QtQuick
import QtQuick.Controls.Basic
import ".."

MenuItem {
    id: item
    property bool danger: false
    implicitHeight: 34
    implicitWidth: 270
    contentItem: Text {
        leftPadding: 10
        text: item.text
        font.family: Theme.pixel
        font.pixelSize: 14
        color: item.danger ? Theme.red : Theme.ink
        verticalAlignment: Text.AlignVCenter
    }
    background: Rectangle {
        color: item.highlighted ? Theme.babyPink : "transparent"
        radius: 5
    }
}
