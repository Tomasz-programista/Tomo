import QtQuick
import ".."

// Fansub style subtitle text: thick outline drawn by stamping the text around itself.
Item {
    id: root
    property string text: ""
    property int pixelSize: 28
    property color color: "white"
    property color outlineColor: "#101018"
    property string family: Theme.body
    property int weight: Font.ExtraBold
    property real outline: Math.max(2, pixelSize * 0.09)
    readonly property var offsets: [[-1, -1], [0, -1], [1, -1], [-1, 0], [1, 0], [-1, 1], [0, 1], [1, 1], [1.4, 1.8]]

    implicitWidth: main.implicitWidth
    implicitHeight: main.implicitHeight
    visible: text !== ""

    Repeater {
        model: root.offsets
        Text {
            x: modelData[0] * root.outline
            y: modelData[1] * root.outline
            width: root.width
            text: root.text
            textFormat: Text.StyledText
            font: main.font
            color: root.outlineColor
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
        }
    }

    Text {
        id: main
        width: root.width
        text: root.text
        textFormat: Text.StyledText
        font.family: root.family
        font.pixelSize: root.pixelSize
        font.weight: root.weight
        color: root.color
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
    }
}
