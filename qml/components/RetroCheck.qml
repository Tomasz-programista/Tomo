import QtQuick
import QtQuick.Controls.Basic
import ".."

CheckBox {
    id: control
    property string jp: ""
    spacing: 8
    font.family: Theme.body
    font.pixelSize: 14

    indicator: Rectangle {
        implicitWidth: 22
        implicitHeight: 22
        x: control.leftPadding
        y: parent.height / 2 - height / 2
        radius: 5
        color: control.checked ? Theme.babyPink : "white"
        border.width: 2
        border.color: Theme.ink
        Text {
            anchors.centerIn: parent
            visible: control.checked
            text: "★"
            font.family: Theme.pixel
            font.pixelSize: 16
            color: Theme.hotPink
        }
    }

    contentItem: Text {
        leftPadding: control.indicator.width + control.spacing
        text: control.text + (control.jp ? "  " + control.jp : "")
        font: control.font
        color: Theme.ink
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.WordWrap
    }

    onToggled: Sfx.click()
}
