import QtQuick
import ".."

// An 88x31 web button.
Rectangle {
    id: root
    property string leftText: "TOMO"
    property string rightText: "TV"
    property color leftColor: Theme.hotPink
    property color rightColor: Theme.paper
    property color rightInk: Theme.ink
    width: 88
    height: 31
    color: Theme.ink
    border.width: 1
    border.color: "#FFFFFF"

    Row {
        anchors.fill: parent
        anchors.margins: 2
        Rectangle {
            width: parent.width * 0.42
            height: parent.height
            color: root.leftColor
            Text {
                anchors.centerIn: parent
                text: root.leftText
                font.family: Theme.tiny
                font.pixelSize: 8
                color: "white"
            }
        }
        Rectangle {
            width: parent.width * 0.58
            height: parent.height
            color: root.rightColor
            Text {
                anchors.centerIn: parent
                width: parent.width - 2
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: root.rightText
                font.family: Theme.tiny
                font.pixelSize: 8
                color: root.rightInk
            }
        }
    }
}
