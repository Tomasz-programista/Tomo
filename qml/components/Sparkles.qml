import QtQuick
import ".."

// Twinkling stars scattered over an area.
Item {
    id: root
    property int count: 10
    property var flavors: ["star.svg", "star_yellow.svg", "star_pink.svg", "star_blue.svg"]
    property int maxSize: 22
    property bool running: true

    Repeater {
        model: root.count
        Image {
            id: star
            property real seedX: Math.random()
            property real seedY: Math.random()
            source: Theme.asset("img/" + root.flavors[index % root.flavors.length])
            sourceSize: Qt.size(root.maxSize, root.maxSize)
            width: root.maxSize * (0.45 + 0.55 * Math.random())
            height: width
            x: seedX * Math.max(0, root.width - width)
            y: seedY * Math.max(0, root.height - height)
            scale: 0
            rotation: Math.random() * 90
            opacity: 0.95

            SequentialAnimation on scale {
                running: root.running
                loops: Animation.Infinite
                PauseAnimation { duration: Math.random() * 2600 }
                NumberAnimation { to: 1; duration: 380; easing.type: Easing.OutBack }
                NumberAnimation { to: 0; duration: 520; easing.type: Easing.InQuad }
                PauseAnimation { duration: 400 + Math.random() * 1400 }
            }
            RotationAnimation on rotation {
                running: root.running
                from: 0; to: 360
                duration: 3000 + Math.random() * 3000
                loops: Animation.Infinite
            }
        }
    }
}
