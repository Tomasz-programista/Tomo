import QtQuick
import ".."

// A pearl-pink flip phone turned sideways for 1seg TV, with a strap charm.
FrameBase {
    id: f
    property string channelText: ""
    padL: 0.2
    padR: 0.2
    padT: 0.19
    padB: 0.09

    // strap charm dangling from the corner
    Item {
        x: f.bodyX + f.bodyW - f.sh * 0.1
        y: f.bodyY + f.sh * 0.1
        width: 1
        height: 1
        z: 5
        Item {
            id: charm
            rotation: 0
            SequentialAnimation on rotation {
                loops: Animation.Infinite
                NumberAnimation { from: -14; to: 14; duration: 1300; easing.type: Easing.InOutSine }
                NumberAnimation { from: 14; to: -14; duration: 1300; easing.type: Easing.InOutSine }
            }
            Rectangle {
                x: -1
                width: 2
                height: f.sh * 0.16
                color: Theme.ink
            }
            Image {
                x: -width / 2
                y: f.sh * 0.15
                source: Theme.asset("img/star_yellow.svg")
                sourceSize: Qt.size(64, 64)
                width: f.sh * 0.13
                height: width
            }
            Image {
                x: -width / 2 + f.sh * 0.02
                y: f.sh * 0.25
                source: Theme.asset("img/heart.svg")
                sourceSize: Qt.size(64, 64)
                width: f.sh * 0.07
                height: width
            }
        }
    }

    Rectangle {
        x: f.bodyX + 6
        y: f.bodyY + 8
        width: f.bodyW
        height: f.bodyH
        radius: f.sh * 0.2
        color: Theme.ink
        opacity: 0.35
    }
    Rectangle {
        x: f.bodyX
        y: f.bodyY
        width: f.bodyW
        height: f.bodyH
        radius: f.sh * 0.2
        border.width: 3
        border.color: Theme.ink
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#FFE4F2" }
            GradientStop { position: 0.55; color: "#FFAFD6" }
            GradientStop { position: 1.0; color: "#F08CC0" }
        }
        Rectangle {
            anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: f.sh * 0.025; leftMargin: f.sh * 0.2; rightMargin: f.sh * 0.2 }
            height: f.sh * 0.05
            radius: height / 2
            color: "white"
            opacity: 0.55
        }
    }

    // display glass: status bar + picture
    Rectangle {
        x: f.screenRect.x - f.sh * 0.03
        y: f.screenRect.y - f.sh * 0.13
        width: f.screenRect.width + f.sh * 0.06
        height: f.screenRect.height + f.sh * 0.16
        radius: f.sh * 0.04
        color: "#1B1830"
        border.width: 2
        border.color: Theme.ink

        Row {
            x: f.sh * 0.04
            y: f.sh * 0.025
            height: f.sh * 0.08
            spacing: f.sh * 0.02
            Row {
                spacing: 1
                anchors.bottom: parent.bottom
                Repeater {
                    model: 4
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: f.sh * 0.012
                        height: f.sh * (0.02 + index * 0.012)
                        color: "white"
                    }
                }
            }
            Text {
                text: "ワンセグ"
                font.family: Theme.pixel
                font.pixelSize: Math.max(8, f.sh * 0.05)
                color: "#9BE7FF"
            }
            Text {
                text: f.channelText
                font.family: Theme.pixel
                font.pixelSize: Math.max(8, f.sh * 0.05)
                color: "white"
            }
        }
        Row {
            anchors { right: parent.right; rightMargin: f.sh * 0.04 }
            y: f.sh * 0.025
            spacing: f.sh * 0.025
            Text {
                text: Theme.clock(backend.now)
                font.family: Theme.pixel
                font.pixelSize: Math.max(8, f.sh * 0.05)
                color: "white"
            }
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: f.sh * 0.085
                height: f.sh * 0.04
                radius: 2
                color: "transparent"
                border.width: 1
                border.color: "white"
                Row {
                    anchors.fill: parent
                    anchors.margins: 2
                    spacing: 1
                    Repeater {
                        model: 3
                        Rectangle { width: (parent.width - 2) / 3; height: parent.height; color: index < 2 ? "#7DFF8A" : "#555" }
                    }
                }
            }
        }
    }
    Rectangle {
        x: f.screenRect.x
        y: f.screenRect.y
        width: f.screenRect.width
        height: f.screenRect.height
        color: "black"
    }

    // earpiece and camera on the left end, a sticker on the right
    Rectangle {
        x: f.bodyX + f.sh * 0.06
        y: f.bodyY + f.bodyH / 2 - height / 2
        width: f.sh * 0.03
        height: f.sh * 0.26
        radius: width / 2
        color: "#7A4D68"
        border.width: 2
        border.color: Theme.ink
    }
    Rectangle {
        x: f.bodyX + f.bodyW - f.sh * 0.135
        y: f.bodyY + f.bodyH / 2 - height / 2
        width: f.sh * 0.07
        height: width
        radius: width / 2
        color: "#2B2350"
        border.width: 3
        border.color: "#E9E2F5"
        Rectangle { anchors.centerIn: parent; width: parent.width * 0.35; height: width; radius: width / 2; color: "#8FB6FF" }
    }
    Text {
        x: f.bodyX + f.bodyW - f.sh * 0.17
        y: f.bodyY + f.bodyH - f.sh * 0.17
        text: "1seg"
        font.family: Theme.pixel
        font.pixelSize: Math.max(7, f.sh * 0.04)
        color: "white"
        style: Text.Outline
        styleColor: Theme.ink
        rotation: -8
    }
}
