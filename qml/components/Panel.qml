import QtQuick
import QtQuick.Layouts
import ".."

// A 2000s desktop-gadget style window: gradient title bar, chunky border, hard shadow.
Item {
    id: root
    property string title: ""
    property string jp: ""
    property color accent: Theme.pink
    property color accent2: Theme.purple
    property color fill: Theme.paper
    property bool showButtons: true
    property int padding: 14
    property int spacing: 10
    default property alias content: column.data
    readonly property alias body: column

    implicitWidth: column.implicitWidth + padding * 2 + 6
    implicitHeight: bar.height + column.implicitHeight + padding * 2 + 6

    Rectangle {
        x: 6; y: 6
        width: frame.width; height: frame.height
        radius: frame.radius
        color: Theme.ink
        opacity: 0.22
    }

    Rectangle {
        id: frame
        width: parent.width - 6
        height: parent.height - 6
        radius: 12
        color: root.fill
        border.width: 3
        border.color: Theme.ink
        clip: true

        Rectangle {
            id: bar
            visible: root.title !== ""
            height: visible ? 34 : 0
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 3 }
            radius: 9
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: root.accent }
                GradientStop { position: 1.0; color: root.accent2 }
            }
            Rectangle {
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 2 }
                height: parent.height * 0.45
                radius: 7
                color: "white"
                opacity: 0.35
            }
            Row {
                anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                spacing: 8
                Text {
                    text: "★"
                    font.family: Theme.pixel
                    font.pixelSize: 16
                    color: Theme.yellow
                    style: Text.Outline
                    styleColor: Theme.ink
                }
                Text {
                    text: root.title
                    font.family: Theme.pixel
                    font.pixelSize: 17
                    color: "white"
                    style: Text.Outline
                    styleColor: Theme.ink
                }
                Text {
                    visible: root.jp !== ""
                    text: "～ " + root.jp + " ～"
                    font.family: Theme.pixel
                    font.pixelSize: 14
                    color: "white"
                    opacity: 0.95
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            Row {
                visible: root.showButtons
                anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                spacing: 4
                Repeater {
                    model: ["_", "□", "×"]
                    Rectangle {
                        width: 20; height: 18
                        radius: 4
                        color: index === 2 ? "#FF7A9C" : "#F3EEFF"
                        border.color: Theme.ink
                        border.width: 2
                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            font.family: Theme.pixel
                            font.pixelSize: 11
                            color: Theme.ink
                        }
                    }
                }
            }
        }

        ColumnLayout {
            id: column
            anchors {
                left: parent.left; right: parent.right; top: bar.bottom; bottom: parent.bottom
                margins: root.padding
            }
            spacing: root.spacing
        }
    }
}
