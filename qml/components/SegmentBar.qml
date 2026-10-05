import QtQuick
import ".."

// One little block per episode: watched / on air / waiting / not aired yet.
// Long shows get a single compact bar instead.
Item {
    id: root
    property var episodes: []
    property int blockHeight: 12
    property int maxWidth: 260
    property int spacing: 2
    readonly property bool compact: episodes.length > maxWidth / 6
    readonly property real blockWidth: episodes.length > 0
        ? Math.max(4, Math.min(22, (maxWidth - spacing * (episodes.length - 1)) / episodes.length)) : 0
    readonly property var counts: {
        var c = { watched: 0, aired: 0 }
        for (var i = 0; i < episodes.length; i++) {
            if (episodes[i].state === "watched")
                c.watched++
            if (episodes[i].state !== "upcoming")
                c.aired++
        }
        return c
    }

    implicitWidth: compact ? maxWidth : row.implicitWidth
    implicitHeight: blockHeight

    Row {
        id: row
        visible: !root.compact
        spacing: root.spacing
        Repeater {
            model: root.compact ? [] : root.episodes
            Rectangle {
                width: root.blockWidth
                height: root.blockHeight
                radius: 2
                border.width: 1
                border.color: Theme.ink
                color: modelData.state === "watched" ? Theme.pink
                     : modelData.state === "next" ? Theme.yellow
                     : modelData.state === "queued" ? "#FFE9A6"
                     : "#E4DFF2"
                SequentialAnimation on opacity {
                    running: modelData.state === "next"
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.35; duration: 500 }
                    NumberAnimation { to: 1.0; duration: 500 }
                }
            }
        }
    }

    Rectangle {
        visible: root.compact
        width: root.maxWidth
        height: root.blockHeight
        radius: 3
        color: "#E4DFF2"
        border.width: 1
        border.color: Theme.ink
        clip: true
        Rectangle {
            width: parent.width * root.counts.aired / Math.max(1, root.episodes.length)
            height: parent.height
            color: Theme.yellow
        }
        Rectangle {
            width: parent.width * root.counts.watched / Math.max(1, root.episodes.length)
            height: parent.height
            color: Theme.pink
        }
    }
}
