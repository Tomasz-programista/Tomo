import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import ".."
import "../components"

// 番組表: every channel, what's on air and when the next episode airs.
Item {
    id: page

    readonly property var channels: backend.channels
    readonly property int onAirCount: {
        var n = 0
        for (var i = 0; i < channels.length; i++)
            if (channels[i].canWatch)
                n++
        return n
    }

    Panel {
        anchors.fill: parent
        title: "TV GUIDE"
        jp: "番組表"

        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            Column {
                Layout.fillWidth: true
                Text {
                    text: "Today is " + Theme.dateEn(backend.now) + "  ·  " + page.channels.length
                          + (page.channels.length === 1 ? " channel" : " channels")
                    font.family: Theme.pixel
                    font.pixelSize: 16
                    color: Theme.ink
                }
                Text {
                    text: page.onAirCount > 0
                          ? page.onAirCount + (page.onAirCount === 1 ? " show has" : " shows have") + " a new episode waiting for you!"
                          : (page.channels.length > 0 ? "Nothing new right now. Come back when the next episode airs ☆" : "")
                    font.family: Theme.body
                    font.pixelSize: 13
                    color: Theme.inkSoft
                }
            }
            Blinkie {
                visible: page.onAirCount > 0
                text: "NOW ON AIR"
                colors: [Theme.onAir, "#FF7A9C"]
            }
            GlossButton {
                text: "+ NEW CHANNEL"
                baseColor: Theme.orange
                onClicked: shell.showPage("newchannel")
            }
        }

        // empty state
        Item {
            visible: page.channels.length === 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            Column {
                anchors.centerIn: parent
                spacing: 14
                Image {
                    anchors.horizontalCenter: parent.horizontalCenter
                    source: Theme.asset("img/mascot.svg")
                    sourceSize: Qt.size(150, 165)
                    SequentialAnimation on rotation {
                        loops: Animation.Infinite
                        NumberAnimation { from: -5; to: 5; duration: 900; easing.type: Easing.InOutSine }
                        NumberAnimation { from: 5; to: -5; duration: 900; easing.type: Easing.InOutSine }
                    }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "No channels yet! Tomo-chan is bored... (´・ω・`)"
                    font.family: Theme.pixel
                    font.pixelSize: 20
                    color: Theme.ink
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 520
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: "Make a channel from a folder with one season of a show. Episode 1 airs right away, "
                          + "then one new episode airs every week, just like real TV. Watch at least 70% of each "
                          + "episode, in order, to keep the show going!"
                    font.family: Theme.body
                    font.pixelSize: 14
                    color: Theme.inkSoft
                }
                GlossButton {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "MAKE MY FIRST CHANNEL"
                    baseColor: Theme.orange
                    blink: true
                    onClicked: shell.showPage("newchannel")
                }
            }
        }

        GridView {
            id: grid
            visible: page.channels.length > 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            readonly property int columns: Math.max(1, Math.floor(width / 470))
            cellWidth: Math.floor(width / columns)
            cellHeight: 236
            model: page.channels
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
            delegate: Item {
                width: grid.cellWidth
                height: grid.cellHeight
                ChannelCard {
                    anchors.fill: parent
                    anchors.margins: 6
                    channel: modelData
                    onWatchRequested: (index) => window.watch(modelData.id, index)
                    onEpisodesRequested: {
                        episodesDialog.channelId = modelData.id
                        episodesDialog.open()
                    }
                }
            }
        }
    }

    EpisodesDialog {
        id: episodesDialog
    }
}
