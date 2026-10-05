import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import ".."

// A popup list of radio choices: [{text, detail, value}].
RetroDialog {
    id: root
    property var options: []
    property var current
    signal chosen(var value)
    implicitWidth: 460

    ButtonGroup { id: group }

    ScrollView {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(list.implicitHeight, 380)
        clip: true
        Column {
            id: list
            width: root.implicitWidth - 50
            spacing: 4
            Repeater {
                model: root.options
                RetroRadio {
                    width: list.width
                    text: modelData.text
                    detail: modelData.detail || ""
                    checked: JSON.stringify(modelData.value) === JSON.stringify(root.current)
                    ButtonGroup.group: group
                    onClicked: {
                        root.chosen(modelData.value)
                        root.close()
                    }
                }
            }
        }
    }
}
