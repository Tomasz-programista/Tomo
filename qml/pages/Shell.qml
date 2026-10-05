import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import ".."
import "../components"

// Header + menu + page area + news ticker. Looks like a 2003 anime fan site.
Item {
    id: shell
    property string page: "guide"
    readonly property Item currentPage: content.currentItem

    function showPage(name) {
        if (name === page)
            return
        page = name
        Sfx.open()
        var comp = { guide: guideComp, newchannel: newChannelComp, settings: settingsComp, about: aboutComp }[name]
        content.replace(null, comp)
    }

    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ header
    Rectangle {
        id: header
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: 118
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "#FFB7DD" }
            GradientStop { position: 0.5; color: "#D9C6FF" }
            GradientStop { position: 1.0; color: "#AEE8FF" }
        }
        Rectangle {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: 4
            color: Theme.ink
        }
        Rectangle {
            anchors { left: parent.left; right: parent.right; top: parent.top }
            height: parent.height * 0.42
            color: "white"
            opacity: 0.35
        }
        Sparkles {
            anchors.fill: parent
            count: 16
            maxSize: 20
        }

        Image {
            id: mascot
            x: 22
            y: 10 + bounce
            property real bounce: 0
            source: Theme.asset("img/mascot.svg")
            sourceSize: Qt.size(90, 99)
            width: 90
            height: 99
            SequentialAnimation on bounce {
                loops: Animation.Infinite
                NumberAnimation { from: 0; to: -6; duration: 600; easing.type: Easing.OutQuad }
                NumberAnimation { from: -6; to: 0; duration: 600; easing.type: Easing.InQuad }
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    Sfx.complete()
                    spin.start()
                }
            }
            RotationAnimation on rotation {
                id: spin
                running: false
                from: 0; to: 360
                duration: 600
            }
        }

        Column {
            anchors { left: mascot.right; leftMargin: 16; verticalCenter: parent.verticalCenter; verticalCenterOffset: -2 }
            spacing: 2
            WavyText {
                text: "TOMO☆TV"
                pixelSize: 54
                amplitude: 4
            }
            Text {
                text: "友テレビ ～ one episode a week, just like the good old days ～"
                font.family: Theme.pixel
                font.pixelSize: 15
                color: Theme.ink
            }
        }

        // TV station clock
        Rectangle {
            anchors { right: parent.right; rightMargin: 22; verticalCenter: parent.verticalCenter }
            width: clockCol.implicitWidth + 28
            height: 84
            radius: 12
            color: "#FFFFFF"
            border.width: 3
            border.color: Theme.ink
            Column {
                id: clockCol
                anchors.centerIn: parent
                spacing: 4
                LcdDisplay {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: {
                        var d = new Date(backend.now * 1000)
                        return Theme.pad(d.getHours()) + (d.getSeconds() % 2 ? " " : ":") + Theme.pad(d.getMinutes())
                    }
                    pixelSize: 26
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Theme.dateJa(backend.now) + "  " + Theme.dateEn(backend.now)
                    font.family: Theme.pixel
                    font.pixelSize: 13
                    color: Theme.ink
                }
            }
        }
    }

    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ footer ticker
    Rectangle {
        id: footer
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: 34
        color: Theme.ink
        Rectangle {
            id: newsLabel
            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
            width: 112
            color: Theme.hotPink
            Text {
                anchors.centerIn: parent
                text: "★ NEWS ★"
                font.family: Theme.pixel
                font.pixelSize: 16
                color: "white"
            }
        }
        Marquee {
            anchors { left: newsLabel.right; right: parent.right; top: parent.top; bottom: parent.bottom; leftMargin: 8 }
            running: backend.settings.marquee
            text: backend.channels.length === 0
                  ? "★ Welcome to TOMO-TV!! ★ Make your first channel with  NEW CHANNEL  in the menu ★ Episodes air once a week ~ no binge watching (｀・ω・´) ★ This site is best viewed at 800×600 ★ Sign my guestbook!! ★"
                  : "★ Welcome back to TOMO-TV!! ★ New episodes air once a week ~ no binge watching allowed (｀・ω・´) ★ Watch at least 70% of an episode for it to count ★ Missed a week? Episodes pile up, but you still watch them in order ★ Remember to drink water and sleep before 2AM ★ 今週もよろしくお願いします！ ★ This site is best viewed at 800×600 ★"
        }
    }

    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ menu
    Item {
        id: side
        anchors { left: parent.left; top: header.bottom; bottom: footer.top; margins: 14 }
        width: 232

        Panel {
            id: menu
            width: parent.width
            title: "MENU"
            accent: Theme.purple
            accent2: Theme.cyan
            showButtons: false
            spacing: 8

            Repeater {
                model: [
                    { page: "guide", jp: "番組表", en: "TV Guide", color: Theme.pink },
                    { page: "newchannel", jp: "新番組", en: "New Channel", color: Theme.orange },
                    { page: "freeplay", jp: "自由再生", en: "Free Play", color: Theme.cyan },
                    { page: "settings", jp: "設定", en: "Settings", color: Theme.mint },
                    { page: "about", jp: "このサイトについて", en: "About", color: Theme.purple }
                ]
                Rectangle {
                    id: nav
                    Layout.fillWidth: true
                    height: 44
                    radius: 10
                    property bool current: shell.page === modelData.page
                    color: current ? modelData.color : (hover.containsMouse ? "#FFF0F8" : "white")
                    border.width: 2
                    border.color: Theme.ink
                    Rectangle {
                        anchors { left: parent.left; top: parent.top; bottom: parent.bottom; margins: 4 }
                        width: 8
                        radius: 4
                        color: modelData.color
                        visible: !nav.current
                    }
                    Column {
                        anchors { left: parent.left; leftMargin: 20; verticalCenter: parent.verticalCenter }
                        Text {
                            text: modelData.jp
                            font.family: Theme.pixel
                            font.pixelSize: 16
                            color: nav.current ? "white" : Theme.ink
                            style: nav.current ? Text.Outline : Text.Normal
                            styleColor: Theme.ink
                        }
                        Text {
                            text: modelData.en
                            font.family: Theme.pixel
                            font.pixelSize: 11
                            color: nav.current ? "white" : Theme.inkSoft
                        }
                    }
                    Text {
                        anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                        text: nav.current ? "★" : "☆"
                        font.family: Theme.pixel
                        font.pixelSize: 16
                        color: nav.current ? Theme.yellow : Theme.inkSoft
                        style: Text.Outline
                        styleColor: Theme.ink
                    }
                    MouseArea {
                        id: hover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (modelData.page === "freeplay") {
                                Sfx.click()
                                window.pickFreePlayFile()
                            } else {
                                shell.showPage(modelData.page)
                            }
                        }
                    }
                }
            }
        }

        // visitor counter... of episodes
        Rectangle {
            id: counter
            anchors { top: menu.bottom; topMargin: 12; horizontalCenter: parent.horizontalCenter }
            width: parent.width - 6
            height: 62
            radius: 8
            color: "#14102A"
            border.width: 3
            border.color: Theme.ink
            Column {
                anchors.centerIn: parent
                spacing: 3
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "EPISODES WATCHED"
                    font.family: Theme.pixel
                    font.pixelSize: 12
                    color: Theme.yellow
                }
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 2
                    Repeater {
                        model: ("000000" + backend.watchedCount).slice(-6).split("")
                        Rectangle {
                            width: 20
                            height: 26
                            radius: 3
                            color: index % 2 ? "#2A2050" : "#3A2C6A"
                            border.width: 1
                            border.color: "#6A5AA8"
                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                font.family: Theme.lcd
                                font.pixelSize: 16
                                color: "#FFFFFF"
                            }
                        }
                    }
                }
            }
        }

        Flow {
            anchors { top: counter.bottom; topMargin: 12; left: parent.left; right: parent.right; bottom: parent.bottom }
            spacing: 6
            clip: true
            Blinkie { text: "NO BINGE ZONE"; width: parent.width - 4 }
            Blinkie { text: "WEEKLY ONLY"; width: parent.width - 4; colors: [Theme.cyan, Theme.mint, Theme.purple] }
            Blinkie { text: "I LOVE ANIME"; width: parent.width - 4; colors: [Theme.orange, Theme.pink, Theme.yellow] }
            Badge88 { leftText: "TOMO"; rightText: "TV ★ 2004" }
            Badge88 { leftText: "800"; rightText: "x600 BEST VIEWED"; leftColor: Theme.purple }
            Badge88 { leftText: "OTAKU"; rightText: "4EVER ♥"; leftColor: "#3CCB6E" }
            Badge88 { leftText: "WEB"; rightText: "1.0 FOREVER"; leftColor: "#3F8CFF"; rightColor: Theme.yellow }
        }
    }

    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ pages
    StackView {
        id: content
        anchors { left: side.right; right: parent.right; top: header.bottom; bottom: footer.top; margins: 14; leftMargin: 10 }
        initialItem: guideComp
        replaceEnter: Transition {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 160 }
            NumberAnimation { property: "x"; from: 24; to: 0; duration: 180; easing.type: Easing.OutQuad }
        }
        replaceExit: Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 120 } }
    }

    Component { id: guideComp; GuidePage {} }
    Component { id: newChannelComp; NewChannelPage {} }
    Component { id: settingsComp; SettingsPage {} }
    Component { id: aboutComp; AboutPage {} }
}
