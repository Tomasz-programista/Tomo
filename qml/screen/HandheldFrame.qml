import QtQuick
import ".."

// A pocket game console: D-pad, A/B buttons, green LCD.
FrameBase {
    id: f
    padL: 0.62
    padR: 0.62
    padT: 0.2
    padB: 0.26

    Rectangle {
        x: f.bodyX + 6
        y: f.bodyY + 8
        width: f.bodyW
        height: f.bodyH
        radius: f.sh * 0.3
        color: Theme.ink
        opacity: 0.35
    }
    Rectangle {
        x: f.bodyX
        y: f.bodyY
        width: f.bodyW
        height: f.bodyH
        radius: f.sh * 0.3
        border.width: 3
        border.color: Theme.ink
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#EEEAF7" }
            GradientStop { position: 1.0; color: "#B9B2D0" }
        }
    }

    // screen bezel
    Rectangle {
        x: f.screenRect.x - f.sh * 0.12
        y: f.screenRect.y - f.sh * 0.12
        width: f.screenRect.width + f.sh * 0.24
        height: f.screenRect.height + f.sh * 0.22
        radius: f.sh * 0.06
        color: "#55516A"
        border.width: 2
        border.color: Theme.ink
        Text {
            anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: f.sh * 0.025 }
            text: "★ DOT MATRIX LCD ★"
            font.family: Theme.pixel
            font.pixelSize: Math.max(7, f.sh * 0.05)
            color: "#C9C4DD"
        }
        Column {
            x: f.sh * 0.025
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: f.sh * 0.04
                height: width
                radius: width / 2
                color: f.playing ? "#FF4466" : "#7A3344"
                border.width: 1
                border.color: Theme.ink
            }
            Text {
                text: "POWER"
                font.family: Theme.pixel
                font.pixelSize: Math.max(6, f.sh * 0.03)
                color: "#C9C4DD"
            }
        }
    }
    Rectangle {
        x: f.screenRect.x
        y: f.screenRect.y
        width: f.screenRect.width
        height: f.screenRect.height
        color: "#A6BF1F"
    }

    // D-pad
    Item {
        x: f.bodyX + f.sh * 0.31 - width / 2
        y: f.screenRect.y + f.screenRect.height / 2 - height / 2
        width: f.sh * 0.36
        height: width
        Rectangle { anchors.centerIn: parent; width: parent.width; height: parent.width * 0.34; radius: 4; color: "#2E2A40"; border.width: 2; border.color: Theme.ink }
        Rectangle { anchors.centerIn: parent; width: parent.width * 0.34; height: parent.width; radius: 4; color: "#2E2A40"; border.width: 2; border.color: Theme.ink }
        Rectangle { anchors.centerIn: parent; width: parent.width * 0.3; height: width; color: "#2E2A40" }
    }

    // A / B
    Repeater {
        model: [{ label: "B", dx: 0.08, dy: 0.08 }, { label: "A", dx: 0.3, dy: -0.06 }]
        Rectangle {
            x: f.screenRect.x + f.screenRect.width + f.sh * modelData.dx + f.sh * 0.03
            y: f.screenRect.y + f.screenRect.height / 2 - height / 2 + f.sh * modelData.dy
            width: f.sh * 0.17
            height: width
            radius: width / 2
            border.width: 2
            border.color: Theme.ink
            gradient: Gradient {
                GradientStop { position: 0; color: "#FF9BCF" }
                GradientStop { position: 1; color: "#D2387F" }
            }
            Text {
                anchors.centerIn: parent
                text: modelData.label
                font.family: Theme.pixel
                font.pixelSize: Math.max(8, f.sh * 0.07)
                color: "white"
                style: Text.Outline
                styleColor: Theme.ink
            }
        }
    }

    // SELECT / START
    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        y: f.screenRect.y + f.screenRect.height + f.sh * 0.13
        spacing: f.sh * 0.12
        Repeater {
            model: ["SELECT", "START"]
            Column {
                spacing: 2
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: f.sh * 0.14
                    height: f.sh * 0.04
                    radius: height / 2
                    color: "#6D6888"
                    border.width: 2
                    border.color: Theme.ink
                    rotation: -20
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: modelData
                    font.family: Theme.pixel
                    font.pixelSize: Math.max(6, f.sh * 0.035)
                    color: "#55516A"
                }
            }
        }
    }
    Text {
        x: f.bodyX + f.sh * 0.18
        y: f.bodyY + f.bodyH - f.sh * 0.17
        text: "TOMO BOY"
        font.family: Theme.pixel
        font.pixelSize: Math.max(8, f.sh * 0.06)
        font.italic: true
        color: "#3B3170"
    }
}
