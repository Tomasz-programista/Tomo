import QtQuick
import ".."

// A glossy Web 2.0 pill button.
Item {
    id: root
    property string text: ""
    property string jp: ""
    property string iconName: ""
    property color baseColor: Theme.pink
    property color textColor: "white"
    property int fontSize: 16
    property bool small: false
    property bool silent: false
    property bool blink: false
    signal clicked()

    implicitWidth: Math.max(row.implicitWidth + (small ? 22 : 34), small ? 56 : 92)
    implicitHeight: small ? 30 : 42
    opacity: enabled ? 1.0 : 0.45
    activeFocusOnTab: true

    function activate() {
        if (!root.enabled)
            return
        if (!root.silent)
            Sfx.click()
        root.clicked()
    }

    Keys.onReturnPressed: activate()
    Keys.onSpacePressed: activate()

    Rectangle {
        x: 3; y: 4
        width: body.width; height: body.height
        radius: body.radius
        color: Theme.ink
        opacity: 0.3
    }

    Rectangle {
        id: body
        width: parent.width
        height: parent.height
        radius: height / 2
        border.width: 2
        border.color: root.activeFocus ? Theme.hotPink : Theme.ink
        scale: mouse.pressed ? 0.94 : (mouse.containsMouse ? 1.04 : 1.0)
        Behavior on scale { NumberAnimation { duration: 90 } }
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.lighter(root.baseColor, 1.45) }
            GradientStop { position: 0.48; color: root.baseColor }
            GradientStop { position: 1.0; color: Qt.darker(root.baseColor, 1.18) }
        }

        Rectangle {
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 3 }
            height: parent.height * 0.45
            radius: height / 2
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#E8FFFFFF" }
                GradientStop { position: 1.0; color: "#20FFFFFF" }
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "white"
            visible: root.blink
            opacity: 0
            SequentialAnimation on opacity {
                running: root.blink
                loops: Animation.Infinite
                NumberAnimation { from: 0; to: 0.4; duration: 450 }
                NumberAnimation { from: 0.4; to: 0; duration: 450 }
            }
        }

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 6
            Image {
                visible: root.iconName !== ""
                source: root.iconName ? Theme.icon(root.iconName) : ""
                sourceSize: Qt.size(root.small ? 16 : 20, root.small ? 16 : 20)
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                visible: root.text !== ""
                text: root.text
                font.family: Theme.pixel
                font.pixelSize: root.small ? Math.min(root.fontSize, 13) : root.fontSize
                color: root.textColor
                style: Text.Outline
                styleColor: Theme.ink
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                visible: root.jp !== ""
                text: root.jp
                font.family: Theme.pixel
                font.pixelSize: root.small ? 11 : 12
                color: Theme.ink
                opacity: 0.8
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activate()
    }
}
