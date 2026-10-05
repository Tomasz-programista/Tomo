import QtQuick
import ".."

// A 2001 desktop media player window, streaming over dial-up.
FrameBase {
    id: f
    property string fileName: "anime_ep01.rm"
    padL: 0.03
    padR: 0.03
    padT: 0.21
    padB: 0.17

    property real kbps: 34.4
    Timer {
        interval: 1200
        running: true
        repeat: true
        onTriggered: f.kbps = 28 + Math.random() * 16
    }

    Rectangle {
        x: f.bodyX + 6
        y: f.bodyY + 8
        width: f.bodyW
        height: f.bodyH
        radius: 8
        color: Theme.ink
        opacity: 0.35
    }
    Rectangle {
        x: f.bodyX
        y: f.bodyY
        width: f.bodyW
        height: f.bodyH
        radius: 8
        color: "#ECE9D8"
        border.width: 3
        border.color: "#0A246A"

        Rectangle {
            id: title
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 3 }
            height: f.sh * 0.1
            radius: 6
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#3D95FF" }
                GradientStop { position: 0.15; color: "#0A5FD8" }
                GradientStop { position: 1.0; color: "#0846B0" }
            }
            Image {
                x: 6
                anchors.verticalCenter: parent.verticalCenter
                source: Theme.asset("img/icon.png")
                width: parent.height * 0.75
                height: width
            }
            Text {
                x: parent.height * 0.9
                anchors.verticalCenter: parent.verticalCenter
                text: "TomoPlayer 8 - " + f.fileName
                font.family: Theme.body
                font.bold: true
                font.pixelSize: Math.max(8, f.sh * 0.045)
                color: "white"
                style: Text.Raised
                styleColor: "#05308F"
                elide: Text.ElideRight
                width: parent.width - parent.height * 4.2
            }
            Row {
                anchors { right: parent.right; rightMargin: 4; verticalCenter: parent.verticalCenter }
                spacing: 3
                Repeater {
                    model: ["_", "□", "×"]
                    Rectangle {
                        width: title.height * 0.78
                        height: width
                        radius: 3
                        color: index === 2 ? "#E0502F" : "#2D7BF0"
                        border.width: 1
                        border.color: "white"
                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            font.family: Theme.pixel
                            font.pixelSize: Math.max(7, parent.height * 0.6)
                            color: "white"
                        }
                    }
                }
            }
        }
        Row {
            anchors { left: parent.left; top: title.bottom; leftMargin: 8; topMargin: 2 }
            spacing: f.sh * 0.04
            Repeater {
                model: ["File", "View", "Play", "Favorites", "Help"]
                Text {
                    text: modelData
                    font.family: Theme.body
                    font.pixelSize: Math.max(7, f.sh * 0.04)
                    color: "#222"
                }
            }
        }
    }
    Rectangle {
        x: f.screenRect.x - 2
        y: f.screenRect.y - 2
        width: f.screenRect.width + 4
        height: f.screenRect.height + 4
        color: "black"
        border.width: 2
        border.color: "#7F9DB9"
    }

    // status bar
    Rectangle {
        x: f.screenRect.x
        y: f.screenRect.y + f.screenRect.height + f.sh * 0.04
        width: f.screenRect.width
        height: f.sh * 0.09
        color: "#D6D2C2"
        border.width: 1
        border.color: "#8E8B7C"
        Text {
            anchors { left: parent.left; leftMargin: 6; verticalCenter: parent.verticalCenter }
            text: (f.playing ? "Playing" : "Paused") + "   ·   " + f.kbps.toFixed(1) + " Kbps   ·   Stereo"
            font.family: Theme.pixel
            font.pixelSize: Math.max(7, f.sh * 0.045)
            color: "#222"
        }
        Row {
            anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
            spacing: 2
            Repeater {
                model: 10
                Rectangle {
                    width: f.sh * 0.018
                    height: f.sh * 0.05
                    color: index < Math.round(f.kbps / 5) ? "#2EB82E" : "#A8A699"
                }
            }
        }
    }
}
