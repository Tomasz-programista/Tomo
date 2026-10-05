import QtQuick
import ".."

// A silver early-2000s CRT television with a sticker on it.
FrameBase {
    id: f
    padL: 0.075
    padR: 0.075
    padT: 0.075
    padB: 0.21

    Rectangle {
        x: f.bodyX + 6
        y: f.bodyY + 8
        width: f.bodyW
        height: f.bodyH
        radius: f.sh * 0.07
        color: Theme.ink
        opacity: 0.35
    }

    Rectangle {
        id: body
        x: f.bodyX
        y: f.bodyY
        width: f.bodyW
        height: f.bodyH
        radius: f.sh * 0.07
        border.width: 3
        border.color: Theme.ink
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#F7F7FC" }
            GradientStop { position: 0.5; color: "#D3D3E0" }
            GradientStop { position: 1.0; color: "#A9A9BE" }
        }
        Rectangle {
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 5 }
            height: f.sh * 0.05
            radius: height / 2
            color: "white"
            opacity: 0.6
        }
    }

    // recessed bezel around the tube
    Rectangle {
        x: f.screenRect.x - f.sh * 0.03
        y: f.screenRect.y - f.sh * 0.03
        width: f.screenRect.width + f.sh * 0.06
        height: f.screenRect.height + f.sh * 0.06
        radius: f.sh * 0.065
        color: "#3A3A4A"
        border.width: 2
        border.color: Theme.ink
    }
    Rectangle {
        x: f.screenRect.x
        y: f.screenRect.y
        width: f.screenRect.width
        height: f.screenRect.height
        radius: f.sh * 0.05
        color: "#050507"
    }

    // bottom panel
    Item {
        x: f.bodyX + f.padL * f.sh
        y: f.screenRect.y + f.screenRect.height + f.sh * 0.045
        width: f.screenRect.width
        height: f.bodyY + f.bodyH - y - f.sh * 0.04

        Grid {
            id: grilleL
            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
            rows: 3
            columns: 14
            spacing: f.sh * 0.012
            Repeater {
                model: 42
                Rectangle { width: f.sh * 0.012; height: width; radius: width / 2; color: "#55556A" }
            }
        }
        Column {
            anchors.centerIn: parent
            spacing: 0
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "TOMOVISION"
                font.family: Theme.pixel
                font.pixelSize: Math.max(9, f.sh * 0.055)
                font.letterSpacing: 2
                color: "#4A4A60"
                style: Text.Raised
                styleColor: "white"
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "トモビジョン ★ STEREO"
                font.family: Theme.pixel
                font.pixelSize: Math.max(7, f.sh * 0.026)
                color: "#6A6A80"
            }
        }
        Row {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            spacing: f.sh * 0.02
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: f.sh * 0.022
                height: width
                radius: width / 2
                color: f.playing ? "#5CFF6B" : "#FF5A5A"
                border.width: 1
                border.color: Theme.ink
                SequentialAnimation on opacity {
                    running: !f.playing
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.35; duration: 700 }
                    NumberAnimation { to: 1.0; duration: 700 }
                }
            }
            Repeater {
                model: ["CH▲", "CH▼", "VOL"]
                Column {
                    spacing: 2
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: f.sh * 0.04
                        height: width
                        radius: width / 2
                        border.width: 2
                        border.color: Theme.ink
                        gradient: Gradient {
                            GradientStop { position: 0; color: "#FFFFFF" }
                            GradientStop { position: 1; color: "#B4B4C6" }
                        }
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData
                        font.family: Theme.pixel
                        font.pixelSize: Math.max(6, f.sh * 0.02)
                        color: "#55556A"
                    }
                }
            }
        }
    }

    // the obligatory sticker
    Image {
        source: Theme.asset("img/heart.svg")
        sourceSize: Qt.size(64, 64)
        width: f.sh * 0.085
        height: width
        x: f.bodyX + f.bodyW - width - f.sh * 0.012
        y: f.bodyY + f.sh * 0.006
        rotation: 18
    }
    Image {
        source: Theme.asset("img/star_yellow.svg")
        sourceSize: Qt.size(64, 64)
        width: f.sh * 0.07
        height: width
        x: f.bodyX + f.sh * 0.004
        y: f.bodyY + f.bodyH - f.sh * 0.12
        rotation: -12
    }
}
