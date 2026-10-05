import QtQuick

// Works out where the screen goes inside a device frame.
// Bezel sizes are fractions of the screen height so frames scale with the window.
Item {
    id: base
    property real aspect: 4 / 3
    property bool playing: false
    property real padL: 0
    property real padR: 0
    property real padT: 0
    property real padB: 0

    readonly property real sh: Math.max(10, Math.min(width / (aspect + padL + padR), height / (1 + padT + padB)))
    readonly property real sw: sh * aspect
    readonly property real bodyW: sw + (padL + padR) * sh
    readonly property real bodyH: sh * (1 + padT + padB)
    readonly property real bodyX: (width - bodyW) / 2
    readonly property real bodyY: (height - bodyH) / 2
    readonly property rect screenRect: Qt.rect(bodyX + padL * sh, bodyY + padT * sh, sw, sh)
}
