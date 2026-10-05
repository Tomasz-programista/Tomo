import QtQuick
import ".."

// Round glossy button with an icon, for the player controls.
Item {
    id: root
    property string iconName: "play"
    property color baseColor: Theme.cyan
    property int size: 40
    property string tip: ""
    property bool checked: false
    signal clicked()

    width: size
    height: size
    opacity: enabled ? 1.0 : 0.4

    Rectangle {
        x: 2; y: 3
        width: parent.width; height: parent.height
        radius: width / 2
        color: Theme.ink
        opacity: 0.3
    }

    Rectangle {
        id: body
        anchors.fill: parent
        radius: width / 2
        border.width: 2
        border.color: Theme.ink
        scale: mouse.pressed ? 0.9 : (mouse.containsMouse ? 1.07 : 1.0)
        Behavior on scale { NumberAnimation { duration: 80 } }
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.lighter(root.checked ? Theme.yellow : root.baseColor, 1.4) }
            GradientStop { position: 0.5; color: root.checked ? Theme.yellow : root.baseColor }
            GradientStop { position: 1.0; color: Qt.darker(root.checked ? Theme.yellow : root.baseColor, 1.2) }
        }
        Rectangle {
            anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 2 }
            width: parent.width * 0.7
            height: parent.height * 0.42
            radius: height / 2
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#D0FFFFFF" }
                GradientStop { position: 1.0; color: "#10FFFFFF" }
            }
        }
        Image {
            anchors.centerIn: parent
            source: Theme.icon(root.iconName)
            sourceSize: Qt.size(root.size * 0.55, root.size * 0.55)
        }
    }

    Rectangle {
        visible: mouse.containsMouse && root.tip !== ""
        anchors { bottom: parent.top; bottomMargin: 8; horizontalCenter: parent.horizontalCenter }
        width: tipText.implicitWidth + 14
        height: tipText.implicitHeight + 8
        color: "#FFFFE1"
        border.color: Theme.ink
        border.width: 1
        z: 100
        Text {
            id: tipText
            anchors.centerIn: parent
            text: root.tip
            font.family: Theme.pixel
            font.pixelSize: 12
            color: Theme.ink
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            Sfx.click()
            root.clicked()
        }
    }
}
