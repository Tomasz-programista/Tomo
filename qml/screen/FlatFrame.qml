import QtQuick
import ".."

// A glossy black 2005 flat-screen.
FrameBase {
    id: f
    padL: 0.035
    padR: 0.035
    padT: 0.035
    padB: 0.085

    Rectangle {
        x: f.bodyX + 6
        y: f.bodyY + 8
        width: f.bodyW
        height: f.bodyH
        radius: f.sh * 0.025
        color: Theme.ink
        opacity: 0.35
    }
    Rectangle {
        x: f.bodyX
        y: f.bodyY
        width: f.bodyW
        height: f.bodyH
        radius: f.sh * 0.025
        border.width: 3
        border.color: Theme.ink
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#4A4A5C" }
            GradientStop { position: 0.12; color: "#20202A" }
            GradientStop { position: 1.0; color: "#0B0B10" }
        }
    }
    Rectangle {
        x: f.screenRect.x
        y: f.screenRect.y
        width: f.screenRect.width
        height: f.screenRect.height
        color: "black"
    }
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        y: f.screenRect.y + f.screenRect.height + (f.padB * f.sh - height) / 2
        text: "T O M O"
        font.family: Theme.pixel
        font.pixelSize: Math.max(8, f.sh * 0.04)
        color: "#D8D8E6"
        style: Text.Raised
        styleColor: "#000"
    }
    Rectangle {
        x: f.screenRect.x + f.screenRect.width - width - f.sh * 0.02
        y: f.screenRect.y + f.screenRect.height + (f.padB * f.sh - height) / 2
        width: f.sh * 0.014
        height: width
        radius: width / 2
        color: f.playing ? "#4FC3FF" : "#FF9F43"
    }
}
