import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import ".."

// Modal popup window with 2000s chrome.
Popup {
    id: root
    property string title: ""
    property string jp: ""
    property color accent: Theme.pink
    property color accent2: Theme.purple
    default property alias content: panel.content

    modal: true
    focus: true
    anchors.centerIn: Overlay.overlay
    padding: 0
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    implicitWidth: 520

    Overlay.modal: Rectangle {
        color: "#662B2350"
    }

    enter: Transition {
        NumberAnimation { property: "scale"; from: 0.85; to: 1.0; duration: 140; easing.type: Easing.OutBack }
        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 120 }
    }

    background: Item {}

    contentItem: Item {
        implicitWidth: root.implicitWidth
        implicitHeight: panel.implicitHeight

        Panel {
            id: panel
            anchors.fill: parent
            title: root.title
            jp: root.jp
            accent: root.accent
            accent2: root.accent2
        }

        // the decorative "×" in the title bar closes the window
        MouseArea {
            x: parent.width - 6 - 34
            y: 6
            width: 28
            height: 28
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                Sfx.back()
                root.close()
            }
        }
    }
}
