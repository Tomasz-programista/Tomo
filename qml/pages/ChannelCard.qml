import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Dialogs
import QtQuick.Layouts
import ".."
import "../components"

// One show in the TV guide.
Item {
    id: card
    property var channel: ({})
    signal watchRequested(int index)
    signal episodesRequested()

    readonly property bool onAir: channel.canWatch === true
    readonly property bool finished: channel.finished === true
    readonly property bool missing: {
        var eps = channel.episodes || []
        return channel.nextIndex >= 0 && eps.length > channel.nextIndex && eps[channel.nextIndex].missing
    }
    readonly property color stripe: finished ? Theme.yellow : (onAir ? Theme.onAir : Theme.purple)

    Rectangle {
        x: 5; y: 6
        width: parent.width - 5
        height: parent.height - 6
        radius: 14
        color: Theme.ink
        opacity: 0.22
    }

    Rectangle {
        id: bg
        width: parent.width - 5
        height: parent.height - 6
        radius: 14
        border.width: 3
        border.color: Theme.ink
        gradient: Gradient {
            GradientStop { position: 0.0; color: card.finished ? "#FFFBE6" : (card.onAir ? "#FFF0F6" : "#F6F2FF") }
            GradientStop { position: 1.0; color: "white" }
        }
        clip: true

        Rectangle {
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 3 }
            height: 8
            radius: 4
            color: card.stripe
        }

        // ~ mini TV with the thumbnail ~
        Rectangle {
            id: tv
            x: 14
            y: 22
            width: 168
            height: 132
            radius: 16
            border.width: 3
            border.color: Theme.ink
            gradient: Gradient {
                GradientStop { position: 0; color: "#F2F2FA" }
                GradientStop { position: 1; color: "#B9B9CC" }
            }
            Rectangle {
                id: tube
                anchors { fill: parent; margins: 10; bottomMargin: 22 }
                radius: 10
                color: "black"
                clip: true
                Row {
                    anchors.fill: parent
                    visible: thumb.status !== Image.Ready
                    Repeater {
                        model: ["#C0C0C0", "#C0C000", "#00C0C0", "#00C000", "#C000C0", "#C00000", "#0000C0"]
                        Rectangle { width: tube.width / 7; height: tube.height; color: modelData }
                    }
                }
                Text {
                    anchors.centerIn: parent
                    visible: thumb.status !== Image.Ready
                    text: "NO SIGNAL"
                    font.family: Theme.pixel
                    font.pixelSize: 14
                    color: "white"
                    style: Text.Outline
                    styleColor: "black"
                }
                Image {
                    id: thumb
                    anchors.fill: parent
                    source: card.channel.thumbUrl || card.channel.coverUrl || ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    opacity: card.finished ? 0.75 : 1
                }
                Repeater {
                    model: Math.ceil(tube.height / 3)
                    Rectangle { y: index * 3; width: tube.width; height: 1; color: "black"; opacity: 0.18 }
                }
                Text {
                    x: 6; y: 3
                    text: card.channel.number + "ch"
                    font.family: Theme.pixel
                    font.pixelSize: 17
                    color: Theme.osdGreen
                    style: Text.Outline
                    styleColor: "black"
                }
            }
            Row {
                anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 6 }
                spacing: 6
                Rectangle {
                    width: 7; height: 7; radius: 4
                    anchors.verticalCenter: parent.verticalCenter
                    color: card.onAir ? "#5CFF6B" : "#FF8A8A"
                    border.width: 1
                    border.color: Theme.ink
                }
                Text {
                    text: "TOMOVISION"
                    font.family: Theme.pixel
                    font.pixelSize: 9
                    color: "#555570"
                }
            }
        }

        // ON AIR sticker
        Rectangle {
            visible: card.onAir
            x: tv.x + tv.width - width + 10
            y: tv.y - 10
            width: onAirText.implicitWidth + 14
            height: 22
            radius: 4
            rotation: 8
            color: Theme.onAir
            border.width: 2
            border.color: Theme.ink
            Text {
                id: onAirText
                anchors.centerIn: parent
                text: "ON AIR"
                font.family: Theme.pixel
                font.pixelSize: 13
                color: "white"
            }
            SequentialAnimation on opacity {
                running: card.onAir
                loops: Animation.Infinite
                NumberAnimation { to: 0.55; duration: 600 }
                NumberAnimation { to: 1.0; duration: 600 }
            }
        }

        // ~ text side ~
        ColumnLayout {
            anchors { left: tv.right; leftMargin: 14; right: parent.right; rightMargin: 14; top: parent.top; topMargin: 20 }
            spacing: 4

            Text {
                Layout.fillWidth: true
                text: card.channel.title || ""
                font.family: Theme.body
                font.weight: Font.ExtraBold
                font.pixelSize: 18
                color: Theme.ink
                elide: Text.ElideRight
                maximumLineCount: 2
                wrapMode: Text.WordWrap
            }
            Text {
                Layout.fillWidth: true
                text: card.finished
                      ? "完 ~ all " + card.channel.total + " episodes watched!"
                      : "Episode " + Math.min(card.channel.watched + 1, card.channel.total) + " of " + card.channel.total
                        + "  ·  " + Theme.intervalName(card.channel.interval)
                font.family: Theme.pixel
                font.pixelSize: 13
                color: Theme.inkSoft
                elide: Text.ElideRight
            }

            // status
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 52
                Column {
                    visible: card.onAir && !card.missing
                    spacing: 2
                    Row {
                        spacing: 6
                        Rectangle {
                            width: 12; height: 12; radius: 6
                            anchors.verticalCenter: parent.verticalCenter
                            color: Theme.onAir
                            SequentialAnimation on opacity {
                                loops: Animation.Infinite
                                running: card.onAir
                                NumberAnimation { to: 0.2; duration: 500 }
                                NumberAnimation { to: 1.0; duration: 500 }
                            }
                        }
                        Text {
                            text: "ON AIR NOW · " + card.channel.nextLabel + (card.channel.isFinale ? " (FINALE!)" : "")
                            font.family: Theme.pixel
                            font.pixelSize: 16
                            color: Theme.onAir
                        }
                    }
                    Text {
                        text: card.channel.backlog > 1
                              ? "+" + (card.channel.backlog - 1) + " more aired · watch them in order!"
                              : "Your episode is ready ☆"
                        font.family: Theme.body
                        font.pixelSize: 13
                        color: Theme.inkSoft
                    }
                }
                Column {
                    visible: !card.onAir && !card.finished && !card.missing
                    spacing: 3
                    Text {
                        text: "NEXT: " + card.channel.nextLabel + " · " + Theme.airText(card.channel.nextEpisodeAir)
                        font.family: Theme.pixel
                        font.pixelSize: 14
                        color: Theme.ink
                    }
                    Row {
                        spacing: 8
                        LcdDisplay {
                            text: Theme.countdown(card.channel.nextEpisodeAir - backend.now)
                            pixelSize: 15
                            litColor: "#FF9BD2"
                            backColor: "#2A1630"
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "until it airs"
                            font.family: Theme.body
                            font.pixelSize: 12
                            color: Theme.inkSoft
                        }
                    }
                }
                Column {
                    visible: card.finished
                    spacing: 2
                    Text {
                        text: "★ THE END ★  おつかれさま!"
                        font.family: Theme.pixel
                        font.pixelSize: 16
                        color: "#C98A00"
                    }
                    Text {
                        text: "Reruns are always available ♪"
                        font.family: Theme.body
                        font.pixelSize: 13
                        color: Theme.inkSoft
                    }
                }
                Column {
                    visible: card.missing && !card.finished
                    spacing: 2
                    Text {
                        text: "! Can't find the video files"
                        font.family: Theme.pixel
                        font.pixelSize: 15
                        color: Theme.red
                    }
                    Text {
                        text: "Moved the folder? Use  ...  →  Change folder"
                        font.family: Theme.body
                        font.pixelSize: 12
                        color: Theme.inkSoft
                    }
                }
            }

            SegmentBar {
                episodes: card.channel.episodes || []
                maxWidth: bg.width - tv.width - 60
            }
        }

        // ~ buttons ~
        Row {
            anchors { left: parent.left; leftMargin: 14; bottom: parent.bottom; bottomMargin: 14 }
            spacing: 8
            GlossButton {
                small: true
                text: card.onAir ? "WATCH" : (card.finished ? "RERUN" : "WAITING...")
                iconName: card.onAir ? "play" : ""
                baseColor: card.onAir ? Theme.hotPink : Theme.purple
                enabled: (card.onAir || card.finished) && !card.missing
                blink: card.onAir
                onClicked: card.watchRequested(card.onAir ? card.channel.nextIndex : 0)
            }
            GlossButton {
                small: true
                text: "EPISODES"
                iconName: "list"
                baseColor: Theme.cyan
                onClicked: card.episodesRequested()
            }
            GlossButton {
                small: true
                text: "..."
                baseColor: "#B9B2D0"
                onClicked: menu.popup()
            }
        }
    }

    Menu {
        id: menu
        MenuItem { text: "Rename…"; onTriggered: renameDialog.open() }
        MenuItem { text: "Change folder…"; onTriggered: folderDialog.open() }
        MenuItem { text: "Open folder"; onTriggered: backend.openChannelFolder(card.channel.id) }
        MenuSeparator {}
        MenuItem { text: "Restart broadcast from episode 1"; onTriggered: restartDialog.open() }
        MenuItem { text: "Delete channel"; onTriggered: deleteDialog.open() }
        background: Rectangle {
            implicitWidth: 260
            color: "white"
            border.width: 3
            border.color: Theme.ink
            radius: 8
        }
        delegate: MenuItem {
            id: menuItem
            implicitHeight: 34
            contentItem: Text {
                leftPadding: 10
                text: menuItem.text
                font.family: Theme.pixel
                font.pixelSize: 14
                color: Theme.ink
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
                color: menuItem.highlighted ? Theme.babyPink : "transparent"
                radius: 5
            }
        }
    }

    RetroDialog {
        id: renameDialog
        title: "RENAME"
        jp: "名前変更"
        onOpened: { nameField.text = card.channel.title; nameField.forceActiveFocus(); nameField.selectAll() }
        RetroField {
            id: nameField
            Layout.fillWidth: true
            onAccepted: renameOk.activate()
        }
        RowLayout {
            Layout.alignment: Qt.AlignRight
            GlossButton { small: true; text: "CANCEL"; baseColor: "#B9B2D0"; onClicked: renameDialog.close() }
            GlossButton {
                id: renameOk
                small: true
                text: "SAVE"
                onClicked: {
                    backend.renameChannel(card.channel.id, nameField.text)
                    renameDialog.close()
                }
            }
        }
    }

    RetroDialog {
        id: restartDialog
        title: "RESTART?"
        jp: "再放送"
        accent: Theme.orange
        Text {
            Layout.fillWidth: true
            Layout.preferredWidth: 440
            wrapMode: Text.WordWrap
            text: "Start “" + card.channel.title + "” over from episode 1? Your progress resets and episode 1 airs again right now."
            font.family: Theme.body
            font.pixelSize: 15
            color: Theme.ink
        }
        RowLayout {
            Layout.alignment: Qt.AlignRight
            GlossButton { small: true; text: "NO"; baseColor: "#B9B2D0"; onClicked: restartDialog.close() }
            GlossButton {
                small: true
                text: "YES, RESTART"
                baseColor: Theme.orange
                onClicked: {
                    backend.restartChannel(card.channel.id)
                    restartDialog.close()
                }
            }
        }
    }

    RetroDialog {
        id: deleteDialog
        title: "DELETE?"
        jp: "削除"
        accent: Theme.red
        accent2: Theme.hotPink
        Text {
            Layout.fillWidth: true
            Layout.preferredWidth: 440
            wrapMode: Text.WordWrap
            text: "Delete the channel “" + card.channel.title + "”? Your video files are NOT touched, only the channel and its progress."
            font.family: Theme.body
            font.pixelSize: 15
            color: Theme.ink
        }
        RowLayout {
            Layout.alignment: Qt.AlignRight
            GlossButton { small: true; text: "KEEP IT"; baseColor: "#B9B2D0"; onClicked: deleteDialog.close() }
            GlossButton {
                small: true
                text: "DELETE"
                baseColor: Theme.red
                onClicked: {
                    deleteDialog.close()
                    backend.deleteChannel(card.channel.id)
                }
            }
        }
    }

    FolderDialog {
        id: folderDialog
        title: "Where is “" + card.channel.title + "” now?"
        onAccepted: {
            if (backend.relocateChannel(card.channel.id, selectedFolder))
                window.toast("Found it!", "The channel now uses the new folder ☆", "done")
            else {
                Sfx.error()
                window.toast("Hmm, no episodes there", "That folder doesn't contain this channel's video files.", "info")
            }
        }
    }
}
