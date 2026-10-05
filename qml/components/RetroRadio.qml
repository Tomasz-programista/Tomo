import QtQuick
import QtQuick.Controls.Basic
import ".."

RadioButton {
    id: control
    property string detail: ""
    spacing: 8
    font.family: Theme.body
    font.pixelSize: 14

    indicator: Rectangle {
        implicitWidth: 22
        implicitHeight: 22
        x: control.leftPadding
        y: control.topPadding + 2
        radius: 11
        color: "white"
        border.width: 2
        border.color: Theme.ink
        Rectangle {
            anchors.centerIn: parent
            width: 12
            height: 12
            radius: 6
            visible: control.checked
            gradient: Gradient {
                GradientStop { position: 0; color: "#FFB3DA" }
                GradientStop { position: 1; color: Theme.hotPink }
            }
        }
    }

    contentItem: Column {
        leftPadding: control.indicator.width + control.spacing
        spacing: 1
        Text {
            width: control.availableWidth - control.indicator.width - control.spacing
            text: control.text
            font: control.font
            color: Theme.ink
            wrapMode: Text.WordWrap
        }
        Text {
            visible: control.detail !== ""
            width: control.availableWidth - control.indicator.width - control.spacing
            text: control.detail
            font.family: Theme.body
            font.pixelSize: 12
            color: Theme.inkSoft
            wrapMode: Text.WordWrap
        }
    }

    onToggled: Sfx.click()
}
