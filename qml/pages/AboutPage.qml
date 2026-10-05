import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import ".."
import "../components"

// このサイトについて
Item {
    Panel {
        anchors.fill: parent
        title: "ABOUT"
        jp: "このサイトについて"
        accent: Theme.purple
        accent2: Theme.pink

        ScrollView {
            id: scroll
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: availableWidth

            ColumnLayout {
                width: scroll.availableWidth - 10
                spacing: 14

                RowLayout {
                    spacing: 24
                    Image {
                        source: Theme.asset("img/mascot.svg")
                        sourceSize: Qt.size(170, 187)
                        SequentialAnimation on y {
                            loops: Animation.Infinite
                            NumberAnimation { from: 0; to: -8; duration: 700; easing.type: Easing.OutQuad }
                            NumberAnimation { from: -8; to: 0; duration: 700; easing.type: Easing.InQuad }
                        }
                    }
                    ColumnLayout {
                        spacing: 6
                        WavyText {
                            text: "TOMO☆TV"
                            pixelSize: 46
                        }
                        Text {
                            text: "version " + backend.version + "  ～ 2004 edition ～"
                            font.family: Theme.pixel
                            font.pixelSize: 16
                            color: Theme.ink
                        }
                        Text {
                            Layout.preferredWidth: 480
                            wrapMode: Text.WordWrap
                            text: "Remember when you had to wait a whole week for the next episode? And talked about it at school "
                                  + "the next day? TOMO-TV brings that back. Pick a season, and it airs one episode a week, "
                                  + "on a CRT, a VHS tape, a flip phone, or whatever screen you like."
                            font.family: Theme.body
                            font.pixelSize: 14
                            color: Theme.inkSoft
                        }
                        Text {
                            text: "Hi, I'm Tomo-chan! Don't binge, okay? (｀・ω・´)ゞ"
                            font.family: Theme.pixel
                            font.pixelSize: 15
                            color: Theme.hotPink
                        }
                    }
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: 6
                    Badge88 { leftText: "TOMO"; rightText: "TV ★ 2004" }
                    Badge88 { leftText: "800"; rightText: "x600 BEST VIEWED"; leftColor: Theme.purple }
                    Badge88 { leftText: "OTAKU"; rightText: "4EVER ♥"; leftColor: "#3CCB6E" }
                    Badge88 { leftText: "WEB"; rightText: "1.0 FOREVER"; leftColor: "#3F8CFF"; rightColor: Theme.yellow }
                    Badge88 { leftText: "NO"; rightText: "BINGE ZONE"; leftColor: Theme.red }
                    Badge88 { leftText: "Qt"; rightText: "POWERED"; leftColor: "#41CD52" }
                }

                Text {
                    text: "Credits  クレジット"
                    font.family: Theme.pixel
                    font.pixelSize: 19
                    color: Theme.hotPink
                }
                Repeater {
                    model: [
                        "Made with ♥ in Claude Code.",
                        "Video playback: Qt 6 Multimedia with FFmpeg (LGPL), via PySide6.",
                        "Fonts: DotGothic16 (SIL OFL 1.1), M PLUS 1 (SIL OFL 1.1), Misaki Gothic by Num Kadoma (free license), DSEG by keshikan (SIL OFL 1.1). License texts are in assets/fonts/licenses.",
                        "Mascot, icons, sounds and screen shaders were made for TOMO-TV."
                    ]
                    Text {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        text: "☆ " + modelData
                        font.family: Theme.body
                        font.pixelSize: 13
                        color: Theme.ink
                    }
                }
            }
        }
    }
}
