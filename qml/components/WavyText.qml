import QtQuick
import ".."

// Rainbow letters bouncing in a wave, straight off a 2003 fan site.
Row {
    id: root
    property string text: "TOMO TV"
    property int pixelSize: 40
    property real amplitude: 5
    property bool running: true
    property real phase: 0
    property string family: Theme.pixel
    spacing: 1

    NumberAnimation on phase {
        running: root.running
        from: 0
        to: Math.PI * 2
        duration: 1600
        loops: Animation.Infinite
    }

    Repeater {
        model: root.text.length
        Text {
            text: root.text.charAt(index)
            font.family: root.family
            font.pixelSize: root.pixelSize
            color: Theme.rainbow[index % Theme.rainbow.length]
            style: Text.Outline
            styleColor: Theme.ink
            transform: Translate { y: Math.sin(root.phase + index * 0.6) * root.amplitude }
        }
    }
}
