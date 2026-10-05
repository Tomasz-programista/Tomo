import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import ".."
import "../components"
import "../Modes.js" as Modes

// 設定
Item {
    id: page
    readonly property var s: backend.settings

    Panel {
        anchors.fill: parent
        title: "SETTINGS"
        jp: "設定"
        accent: Theme.mint
        accent2: Theme.cyan

        ScrollView {
            id: scroll
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: availableWidth

            ColumnLayout {
                width: scroll.availableWidth - 10
                spacing: 16

                Heading { text: "Screen  画面" }
                RowLayout {
                    spacing: 12
                    Rectangle {
                        Layout.preferredWidth: modeCol.implicitWidth + 24
                        Layout.preferredHeight: modeCol.implicitHeight + 16
                        radius: 10
                        color: Theme.babyPink
                        border.width: 2
                        border.color: Theme.ink
                        Column {
                            id: modeCol
                            anchors.centerIn: parent
                            Text {
                                text: Modes.find(page.s.screen).name + "  " + Modes.find(page.s.screen).jp
                                font.family: Theme.pixel
                                font.pixelSize: 17
                                color: Theme.ink
                            }
                            Text {
                                text: (page.s.signal ? page.s.signal + "p" : "mode resolution") + " · " + Modes.aspectName(page.s.aspect)
                                      + " · " + Modes.fitName(page.s.fit) + (page.s.frame ? " · with frame" : "")
                                font.family: Theme.body
                                font.pixelSize: 12
                                color: Theme.inkSoft
                            }
                        }
                    }
                    GlossButton {
                        text: "CHANGE SCREEN..."
                        iconName: "tv"
                        baseColor: Theme.cyan
                        onClicked: screenDialog.open()
                    }
                }
                Text {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: "You can also switch while watching: press V (or the TV button) to flip through CRT, VHS, PC-98, flip phone and the rest."
                    font.family: Theme.body
                    font.pixelSize: 13
                    color: Theme.inkSoft
                }

                Heading { text: "Fun stuff  おまけ" }
                RetroCheck {
                    text: "Glitter cursor trail"
                    checked: page.s.sparkles
                    onToggled: backend.setSetting("sparkles", checked)
                }
                RetroCheck {
                    text: "Chiptune button sounds"
                    checked: page.s.sounds
                    onToggled: backend.setSetting("sounds", checked)
                }
                RetroCheck {
                    text: "Scrolling news ticker"
                    checked: page.s.marquee
                    onToggled: backend.setSetting("marquee", checked)
                }

                Heading { text: "How TV mode works  ルール" }
                Repeater {
                    model: [
                        "Every channel is one season folder. Episode 1 airs the moment you start broadcasting.",
                        "After that, one new episode airs every week at the same time (or every 3 days / daily if you chose that).",
                        "Episodes must be watched in order. Missed a few weeks? They pile up, but you still go one by one.",
                        "An episode counts once you've really watched 70% of it. Skipping ahead doesn't count, but skipping the opening is fine.",
                        "Watched episodes can be re-run any time from the EPISODES list."
                    ]
                    Text {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        text: "☆ " + modelData
                        font.family: Theme.body
                        font.pixelSize: 14
                        color: Theme.ink
                    }
                }

                Heading { text: "Player keys  キー操作" }
                GridLayout {
                    columns: 2
                    columnSpacing: 18
                    rowSpacing: 4
                    Repeater {
                        model: [
                            ["Space", "play / pause"], ["← →", "back / forward 10 seconds"], ["↑ ↓", "volume"],
                            ["M", "mute"], ["F", "fullscreen"], ["A", "switch audio track (主音声 / 副音声)"],
                            ["S", "switch subtitles"], ["V", "next screen mode (Shift+V: previous)"],
                            ["I", "show channel info"], ["Esc", "leave fullscreen / back to the guide"]
                        ]
                        Row {
                            Layout.columnSpan: 1
                            spacing: 10
                            Rectangle {
                                width: 64
                                height: 26
                                radius: 5
                                color: "white"
                                border.width: 2
                                border.color: Theme.ink
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData[0]
                                    font.family: Theme.pixel
                                    font.pixelSize: 13
                                    color: Theme.ink
                                }
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData[1]
                                font.family: Theme.body
                                font.pixelSize: 13
                                color: Theme.ink
                            }
                        }
                    }
                }

                Heading { text: "Your data  データ" }
                Text {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: "Channels and progress are saved here (your videos are never changed or moved):\n" + backend.dataDir
                    font.family: Theme.body
                    font.pixelSize: 13
                    color: Theme.ink
                }
                GlossButton {
                    small: true
                    text: "OPEN DATA FOLDER"
                    baseColor: Theme.purple
                    onClicked: backend.openDataFolder()
                }
                Item { Layout.preferredHeight: 10 }
            }
        }
    }

    ScreenDialog { id: screenDialog }

    component Heading: Text {
        Layout.topMargin: 4
        font.family: Theme.pixel
        font.pixelSize: 19
        color: Theme.hotPink
        style: Text.Outline
        styleColor: "white"
    }
}
