import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import ".."
import "../components"
import "../Modes.js" as Modes

// 画面設定: pick the screen emulation, resolution, shape and fit.
RetroDialog {
    id: dialog
    title: "SCREEN"
    jp: "画面設定"
    accent: Theme.cyan
    accent2: Theme.pink
    implicitWidth: 700

    readonly property var s: backend.settings
    readonly property var current: Modes.find(s.screen)

    GridLayout {
        Layout.fillWidth: true
        columns: 3
        columnSpacing: 8
        rowSpacing: 8
        Repeater {
            model: Modes.modes
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 58
                radius: 10
                border.width: 2
                border.color: Theme.ink
                color: dialog.s.screen === modelData.id ? Theme.babyPink : (tileMouse.containsMouse ? "#F6F2FF" : "white")
                Rectangle {
                    visible: dialog.s.screen === modelData.id
                    anchors { right: parent.right; top: parent.top; margins: 6 }
                    width: 18; height: 18; radius: 9
                    color: Theme.hotPink
                    Text { anchors.centerIn: parent; text: "★"; color: "white"; font.family: Theme.pixel; font.pixelSize: 12 }
                }
                Column {
                    anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                    Text {
                        text: modelData.name
                        font.family: Theme.pixel
                        font.pixelSize: 15
                        color: Theme.ink
                    }
                    Text {
                        text: modelData.jp
                        font.family: Theme.pixel
                        font.pixelSize: 12
                        color: Theme.inkSoft
                    }
                }
                MouseArea {
                    id: tileMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Sfx.click()
                        backend.setSetting("screen", modelData.id)
                    }
                }
            }
        }
    }

    Text {
        Layout.fillWidth: true
        text: "☆ " + dialog.current.desc
        font.family: Theme.body
        font.pixelSize: 13
        color: Theme.inkSoft
        wrapMode: Text.WordWrap
    }

    Text { text: "Signal resolution  解像度"; font.family: Theme.pixel; font.pixelSize: 15; color: Theme.ink }
    Flow {
        Layout.fillWidth: true
        spacing: 6
        Repeater {
            model: Modes.signals
            Chip {
                text: modelData === 0 ? "Mode default (" + (dialog.current.lines || "full") + ")" : modelData + "p"
                selected: dialog.s.signal === modelData
                onClicked: backend.setSetting("signal", modelData)
            }
        }
    }

    Text { text: "Screen shape  画面比"; font.family: Theme.pixel; font.pixelSize: 15; color: Theme.ink }
    Flow {
        Layout.fillWidth: true
        spacing: 6
        Repeater {
            model: Modes.aspects
            Chip {
                text: Modes.aspectName(modelData)
                selected: dialog.s.aspect === modelData
                onClicked: backend.setSetting("aspect", modelData)
            }
        }
    }

    Text { text: "Picture fit  表示"; font.family: Theme.pixel; font.pixelSize: 15; color: Theme.ink }
    Flow {
        Layout.fillWidth: true
        spacing: 6
        Repeater {
            model: Modes.fits
            Chip {
                text: Modes.fitName(modelData)
                selected: dialog.s.fit === modelData
                onClicked: backend.setSetting("fit", modelData)
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        RetroCheck {
            text: "Show the TV / monitor / phone around the picture"
            checked: dialog.s.frame
            onToggled: backend.setSetting("frame", checked)
        }
        Item { Layout.fillWidth: true }
        GlossButton {
            small: true
            text: "DONE"
            onClicked: dialog.close()
        }
    }
}
