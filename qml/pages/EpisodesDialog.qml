import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import ".."
import "../components"

// Episode list of one channel: what aired, what's watched, what's coming.
RetroDialog {
    id: dialog
    property string channelId: ""
    readonly property var channel: {
        var list = backend.channels
        for (var i = 0; i < list.length; i++)
            if (list[i].id === channelId)
                return list[i]
        return null
    }
    title: channel ? channel.title : ""
    jp: "エピソード"
    accent: Theme.cyan
    accent2: Theme.purple
    implicitWidth: 640

    Text {
        Layout.fillWidth: true
        visible: dialog.channel !== null
        text: dialog.channel ? (Theme.intervalName(dialog.channel.interval) + " · premiered " + Theme.airText(dialog.channel.premiere)) : ""
        font.family: Theme.pixel
        font.pixelSize: 13
        color: Theme.inkSoft
    }

    ListView {
        id: list
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(contentHeight, 430)
        clip: true
        spacing: 4
        model: dialog.channel ? dialog.channel.episodes : []
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar {}
        delegate: Rectangle {
            width: list.width - 12
            height: 46
            radius: 8
            border.width: 2
            border.color: Theme.ink
            color: modelData.state === "next" ? "#FFF7C9" : (modelData.state === "watched" ? "#FFEAF5" : "white")
            opacity: modelData.state === "upcoming" ? 0.7 : 1

            Text {
                id: label
                anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                width: 74
                text: modelData.label
                font.family: Theme.pixel
                font.pixelSize: 15
                color: Theme.ink
            }
            Column {
                anchors { left: label.right; right: action.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
                Text {
                    width: parent.width
                    text: modelData.name
                    font.family: Theme.body
                    font.pixelSize: 13
                    color: Theme.ink
                    elide: Text.ElideRight
                }
                Text {
                    width: parent.width
                    text: modelData.missing ? "file missing!"
                        : modelData.state === "watched" ? "watched ★ " + Math.round(modelData.fraction * 100) + "%"
                        : modelData.state === "next" ? "ON AIR · ready to watch" + (modelData.fraction > 0 ? " (" + Math.round(modelData.fraction * 100) + "% so far)" : "")
                        : modelData.state === "queued" ? "aired " + Theme.airText(modelData.airAt) + " · watch the earlier ones first"
                        : "airs " + Theme.airText(modelData.airAt)
                    font.family: Theme.pixel
                    font.pixelSize: 12
                    color: modelData.missing ? Theme.red : (modelData.state === "next" ? Theme.onAir : Theme.inkSoft)
                    elide: Text.ElideRight
                }
            }
            Item {
                id: action
                anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                width: 92
                height: 30
                GlossButton {
                    anchors.right: parent.right
                    visible: (modelData.state === "next" || modelData.state === "watched") && !modelData.missing
                    small: true
                    text: modelData.state === "next" ? "WATCH" : "RERUN"
                    baseColor: modelData.state === "next" ? Theme.hotPink : Theme.purple
                    onClicked: {
                        dialog.close()
                        window.watch(dialog.channelId, modelData.index)
                    }
                }
                Image {
                    anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
                    visible: modelData.state === "upcoming" || modelData.state === "queued"
                    source: Theme.icon("lock")
                    sourceSize: Qt.size(24, 24)
                }
            }
        }
    }

    GlossButton {
        Layout.alignment: Qt.AlignRight
        small: true
        text: "CLOSE"
        baseColor: "#B9B2D0"
        onClicked: dialog.close()
    }
}
