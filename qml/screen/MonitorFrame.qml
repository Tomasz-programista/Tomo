import QtQuick
import ".."

// A beige home-computer monitor.
FrameBase {
    id: f
    padL: 0.07
    padR: 0.07
    padT: 0.07
    padB: 0.15

    Rectangle {
        x: f.bodyX + 6
        y: f.bodyY + 8
        width: f.bodyW
        height: f.bodyH
        radius: f.sh * 0.04
        color: Theme.ink
        opacity: 0.35
    }
    Rectangle {
        x: f.bodyX
        y: f.bodyY
        width: f.bodyW
        height: f.bodyH
        radius: f.sh * 0.04
        border.width: 3
        border.color: Theme.ink
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#F5EFDF" }
            GradientStop { position: 1.0; color: "#D5CAB0" }
        }
    }
    Rectangle {
        x: f.screenRect.x - f.sh * 0.035
        y: f.screenRect.y - f.sh * 0.035
        width: f.screenRect.width + f.sh * 0.07
        height: f.screenRect.height + f.sh * 0.07
        radius: f.sh * 0.035
        color: "#BDB196"
        border.width: 2
        border.color: Theme.ink
    }
    Rectangle {
        x: f.screenRect.x
        y: f.screenRect.y
        width: f.screenRect.width
        height: f.screenRect.height
        radius: f.sh * 0.02
        color: "#060806"
    }

    Item {
        x: f.screenRect.x
        y: f.screenRect.y + f.screenRect.height + f.sh * 0.045
        width: f.screenRect.width
        height: f.bodyY + f.bodyH - y - f.sh * 0.03

        Row {
            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
            spacing: f.sh * 0.015
            Text {
                text: "TOMO-98"
                font.family: Theme.pixel
                font.pixelSize: Math.max(9, f.sh * 0.05)
                font.bold: true
                color: "#6B6250"
                style: Text.Raised
                styleColor: "#FFFDF5"
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                Repeater {
                    model: ["#3FB8FF", "#FF5FA8", "#FFD23F"]
                    Rectangle { width: f.sh * 0.08; height: f.sh * 0.008; color: modelData }
                }
            }
        }
        Row {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            spacing: f.sh * 0.025
            Repeater {
                model: 2
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: f.sh * 0.032
                    height: width
                    radius: width / 2
                    color: "#CFC4A8"
                    border.width: 2
                    border.color: Theme.ink
                }
            }
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: f.sh * 0.018
                height: width
                radius: width / 2
                color: f.playing ? "#5CFF6B" : "#FFB13B"
                border.width: 1
                border.color: Theme.ink
            }
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: f.sh * 0.07
                height: f.sh * 0.04
                radius: 3
                color: "#E8DFC8"
                border.width: 2
                border.color: Theme.ink
            }
        }
    }
}
