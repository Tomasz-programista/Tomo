import QtQuick
import ".."

// Pop-up notification bubbles in the corner.
Column {
    id: root
    spacing: 8
    width: 340

    function show(title, message, kind) {
        toastModel.append({ title: title, message: message || "", kind: kind || "info" })
        if (toastModel.count > 4)
            toastModel.remove(0)
    }

    ListModel { id: toastModel }

    Repeater {
        model: toastModel
        Rectangle {
            id: toast
            width: root.width
            height: col.implicitHeight + 18
            radius: 10
            color: kind === "onair" ? "#FFF0F4" : (kind === "done" ? "#FFFBE0" : "#F3FCFF")
            border.width: 3
            border.color: Theme.ink
            opacity: 0
            Component.onCompleted: opacity = 1
            Behavior on opacity { NumberAnimation { duration: 200 } }

            Rectangle {
                width: 10
                anchors { left: parent.left; top: parent.top; bottom: parent.bottom; margins: 3 }
                radius: 5
                color: kind === "onair" ? Theme.onAir : (kind === "done" ? Theme.yellow : Theme.cyan)
            }
            Column {
                id: col
                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 22; rightMargin: 10 }
                spacing: 2
                Text {
                    width: parent.width
                    text: title
                    font.family: Theme.pixel
                    font.pixelSize: 16
                    color: Theme.ink
                    wrapMode: Text.WordWrap
                }
                Text {
                    width: parent.width
                    visible: message !== ""
                    text: message
                    font.family: Theme.body
                    font.pixelSize: 13
                    color: Theme.inkSoft
                    wrapMode: Text.WordWrap
                }
            }
            Timer {
                interval: 5200
                running: true
                onTriggered: toastModel.remove(index)
            }
            MouseArea {
                anchors.fill: parent
                onClicked: toastModel.remove(index)
            }
        }
    }
}
