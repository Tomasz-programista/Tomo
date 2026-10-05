import QtCore
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Dialogs
import QtQuick.Layouts
import ".."
import "../components"

// 新番組: turn a season folder into a weekly TV channel.
Item {
    id: page

    property var scan: null
    property var probe: null
    property bool probing: false
    property int audioChoice: 0
    property var subChoice: ({ kind: "off" })
    property real interval: backend.week
    property int channelNumber: 1
    property string title: ""
    readonly property int includedCount: {
        var n = 0
        for (var i = 0; i < itemsModel.count; i++)
            if (itemsModel.get(i).include)
                n++
        return n + revision * 0
    }
    property int revision: 0   // bumped whenever the episode list changes

    function loadFolder(url) {
        var result = backend.scanFolder(url)
        scan = result
        probe = null
        itemsModel.clear()
        if (!result.ok) {
            Sfx.error()
            window.toast("No episodes found", result.warning || "Pick the folder that has the video files in it.", "info")
            return
        }
        title = result.title
        channelNumber = result.number
        for (var i = 0; i < result.items.length; i++)
            itemsModel.append(result.items[i])
        revision++
        startProbe()
    }

    function firstIncluded() {
        for (var i = 0; i < itemsModel.count; i++)
            if (itemsModel.get(i).include)
                return itemsModel.get(i).file
        return itemsModel.count > 0 ? itemsModel.get(0).file : ""
    }

    function startProbe() {
        var file = firstIncluded()
        if (!scan || !file)
            return
        probing = true
        backend.probe(scan.folder, file)
    }

    function defaultTracks() {
        audioChoice = 0
        if (probe && probe.audio) {
            for (var i = 0; i < probe.audio.length; i++)
                if (probe.audio[i].lang === "Japanese") {
                    audioChoice = i
                    break
                }
        }
        subChoice = { kind: "off" }
        if (probe && probe.subs && probe.subs.length > 0) {
            var pick = 0
            for (var j = 0; j < probe.subs.length; j++)
                if (probe.subs[j].lang === "English") {
                    pick = j
                    break
                }
            subChoice = { kind: "embedded", index: pick, lang: probe.subs[pick].lang, title: probe.subs[pick].title }
        } else if (scan && scan.subtitleGroups.length > 0) {
            subChoice = { kind: "external", label: scan.subtitleGroups[0].label }
        }
    }

    function startBroadcast() {
        var episodes = []
        for (var i = 0; i < itemsModel.count; i++) {
            var it = itemsModel.get(i)
            if (it.include)
                episodes.push({ file: it.file, name: it.name, number: it.number })
        }
        if (episodes.length === 0) {
            Sfx.error()
            window.toast("No episodes picked!", "Tick at least one episode.", "info")
            return
        }
        var audio = null
        if (probe && probe.audio && probe.audio.length > 0) {
            var a = probe.audio[audioChoice]
            audio = { index: audioChoice, lang: a.lang, title: a.title }
        }
        var id = backend.createChannel({
            folder: scan.folder,
            title: title,
            number: channelNumber,
            episodes: episodes,
            audio: audio,
            subs: subChoice,
            interval: interval,
            cover: scan.cover || "",
            thumb: probe && probe.thumb ? probe.thumb : ""
        })
        if (!id) {
            Sfx.error()
            return
        }
        Sfx.onAir()
        window.toast("★ CH " + channelNumber + " IS ON THE AIR! ★", title + " · episode 1 is ready to watch now!", "onair")
        shell.showPage("guide")
    }

    ListModel { id: itemsModel }

    Connections {
        target: backend
        function onProbeDone(result) {
            if (!page.scan)
                return
            page.probing = false
            page.probe = result
            page.defaultTracks()
        }
    }

    FolderDialog {
        id: folderDialog
        title: "Pick the folder with one season of a show"
        currentFolder: StandardPaths.standardLocations(StandardPaths.MoviesLocation)[0]
        onAccepted: page.loadFolder(selectedFolder)
    }

    Panel {
        anchors.fill: parent
        title: "NEW CHANNEL"
        jp: "新番組"
        accent: Theme.orange
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

                // ① folder
                Section {
                    number: "1"
                    title: "Pick a season folder"
                    jp: "フォルダ選択"
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        GlossButton {
                            text: page.scan ? "PICK ANOTHER..." : "BROWSE..."
                            baseColor: Theme.cyan
                            blink: !page.scan
                            onClicked: folderDialog.open()
                        }
                        Text {
                            Layout.fillWidth: true
                            text: page.scan && page.scan.ok ? page.scan.folder
                                  : "A folder with the episodes of ONE season, e.g.  Anime / Cowboy Bebop"
                            font.family: Theme.body
                            font.pixelSize: 13
                            color: page.scan ? Theme.ink : Theme.inkSoft
                            elide: Text.ElideMiddle
                        }
                    }
                }

                // ② title
                Section {
                    visible: page.scan && page.scan.ok
                    number: "2"
                    title: "Show title & channel number"
                    jp: "番組名"
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        RetroField {
                            Layout.fillWidth: true
                            text: page.title
                            placeholderText: "Show title"
                            onTextEdited: page.title = text
                        }
                        Text {
                            text: "CH"
                            font.family: Theme.pixel
                            font.pixelSize: 18
                            color: Theme.ink
                        }
                        GlossButton { small: true; text: "-"; baseColor: "#B9B2D0"; onClicked: page.channelNumber = Math.max(1, page.channelNumber - 1) }
                        LcdDisplay { text: Theme.pad(page.channelNumber); pixelSize: 22 }
                        GlossButton { small: true; text: "+"; baseColor: "#B9B2D0"; onClicked: page.channelNumber = Math.min(99, page.channelNumber + 1) }
                    }
                }

                // ③ episodes
                Section {
                    visible: page.scan && page.scan.ok
                    number: "3"
                    title: "Episodes, in airing order (" + page.includedCount + " picked)"
                    jp: "エピソード"
                    Text {
                        Layout.fillWidth: true
                        text: "Untick extras you don't want on air. Use the arrows if the order looks wrong."
                        font.family: Theme.body
                        font.pixelSize: 13
                        color: Theme.inkSoft
                        wrapMode: Text.WordWrap
                    }
                    ListView {
                        id: epList
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.min(contentHeight, 280)
                        clip: true
                        spacing: 3
                        model: itemsModel
                        boundsBehavior: Flickable.StopAtBounds
                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                        delegate: Rectangle {
                            width: epList.width - 14
                            height: 36
                            radius: 6
                            color: model.include ? (index % 2 ? "#FFF6FB" : "white") : "#EFEAF7"
                            border.width: 1
                            border.color: "#CFC6EA"
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 6
                                anchors.rightMargin: 6
                                spacing: 6
                                RetroCheck {
                                    checked: model.include
                                    onToggled: {
                                        itemsModel.setProperty(index, "include", checked)
                                        page.revision++
                                    }
                                }
                                Text {
                                    Layout.preferredWidth: 34
                                    text: model.number !== "" ? "#" + model.number : "?"
                                    font.family: Theme.pixel
                                    font.pixelSize: 14
                                    color: Theme.ink
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: model.file
                                    font.family: Theme.body
                                    font.pixelSize: 12
                                    color: model.include ? Theme.ink : "#9A90C0"
                                    elide: Text.ElideMiddle
                                }
                                Rectangle {
                                    visible: model.kind !== "episode"
                                    Layout.preferredWidth: tag.implicitWidth + 10
                                    Layout.preferredHeight: 18
                                    radius: 4
                                    color: model.kind === "extra" ? Theme.sky : Theme.babyPink
                                    border.width: 1
                                    border.color: Theme.ink
                                    Text {
                                        id: tag
                                        anchors.centerIn: parent
                                        text: model.kind === "extra" ? "EXTRA?" : "DUPLICATE?"
                                        font.family: Theme.pixel
                                        font.pixelSize: 10
                                        color: Theme.ink
                                    }
                                }
                                GlossButton {
                                    small: true
                                    text: "↑"
                                    baseColor: "#D9D2F0"
                                    enabled: index > 0
                                    silent: true
                                    onClicked: { itemsModel.move(index, index - 1, 1); page.revision++ }
                                }
                                GlossButton {
                                    small: true
                                    text: "↓"
                                    baseColor: "#D9D2F0"
                                    enabled: index < itemsModel.count - 1
                                    silent: true
                                    onClicked: { itemsModel.move(index, index + 1, 1); page.revision++ }
                                }
                            }
                        }
                    }
                }

                // ④ audio & subs
                Section {
                    visible: page.scan && page.scan.ok
                    number: "4"
                    title: "Audio & subtitles"
                    jp: "音声・字幕"

                    RowLayout {
                        visible: page.probing
                        spacing: 12
                        Image {
                            source: Theme.asset("img/mascot.svg")
                            sourceSize: Qt.size(48, 53)
                            RotationAnimation on rotation { running: page.probing; from: -10; to: 10; duration: 300; loops: Animation.Infinite; direction: RotationAnimation.Shortest }
                        }
                        Text {
                            text: "Tomo-chan is checking the tapes..."
                            font.family: Theme.pixel
                            font.pixelSize: 16
                            color: Theme.ink
                        }
                    }

                    Text {
                        visible: !page.probing && page.probe !== null && !page.probe.ok
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        text: "Couldn't open the first episode (" + (page.probe ? page.probe.error : "") + "). You can still make the channel."
                        font.family: Theme.body
                        font.pixelSize: 13
                        color: Theme.red
                    }

                    RowLayout {
                        visible: !page.probing && page.probe !== null && page.probe.ok
                        Layout.fillWidth: true
                        spacing: 18

                        // preview
                        Rectangle {
                            Layout.alignment: Qt.AlignTop
                            Layout.preferredWidth: 200
                            Layout.preferredHeight: 136
                            radius: 12
                            color: "#2B2350"
                            border.width: 3
                            border.color: Theme.ink
                            Image {
                                anchors { fill: parent; margins: 8 }
                                source: page.probe && page.probe.thumbUrl ? page.probe.thumbUrl : ""
                                fillMode: Image.PreserveAspectFit
                            }
                            Text {
                                anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter; bottomMargin: -20 }
                                text: page.probe ? page.probe.video : ""
                                font.family: Theme.pixel
                                font.pixelSize: 11
                                color: Theme.inkSoft
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            Text {
                                text: "♪ Audio  音声"
                                font.family: Theme.pixel
                                font.pixelSize: 15
                                color: Theme.ink
                            }
                            ButtonGroup { id: audioGroup }
                            Repeater {
                                model: page.probe ? page.probe.audio : []
                                RetroRadio {
                                    Layout.fillWidth: true
                                    text: modelData.label
                                    checked: page.audioChoice === index
                                    ButtonGroup.group: audioGroup
                                    onClicked: page.audioChoice = index
                                }
                            }
                            Text {
                                visible: page.probe && page.probe.audio.length === 0
                                text: "(no audio tracks found)"
                                font.family: Theme.body
                                font.pixelSize: 13
                                color: Theme.inkSoft
                            }
                            Item { Layout.preferredHeight: 6 }
                            Text {
                                text: "字 Subtitles  字幕"
                                font.family: Theme.pixel
                                font.pixelSize: 15
                                color: Theme.ink
                            }
                            ButtonGroup { id: subGroup }
                            RetroRadio {
                                Layout.fillWidth: true
                                text: "Off (no subtitles)"
                                checked: page.subChoice.kind === "off"
                                ButtonGroup.group: subGroup
                                onClicked: page.subChoice = { kind: "off" }
                            }
                            Repeater {
                                model: page.probe ? page.probe.subs : []
                                RetroRadio {
                                    Layout.fillWidth: true
                                    text: modelData.label
                                    detail: "inside the video file"
                                    checked: page.subChoice.kind === "embedded" && page.subChoice.index === index
                                    ButtonGroup.group: subGroup
                                    onClicked: page.subChoice = { kind: "embedded", index: index, lang: modelData.lang, title: modelData.title }
                                }
                            }
                            Repeater {
                                model: page.scan ? page.scan.subtitleGroups : []
                                RetroRadio {
                                    Layout.fillWidth: true
                                    text: "File: " + modelData.description
                                    detail: "separate subtitle files · found for " + modelData.count + " episode" + (modelData.count === 1 ? "" : "s")
                                    checked: page.subChoice.kind === "external" && page.subChoice.label === modelData.label
                                    ButtonGroup.group: subGroup
                                    onClicked: page.subChoice = { kind: "external", label: modelData.label }
                                }
                            }
                        }
                    }
                }

                // ⑤ schedule
                Section {
                    visible: page.scan && page.scan.ok
                    number: "5"
                    title: "Broadcast schedule"
                    jp: "放送スケジュール"
                    ButtonGroup { id: scheduleGroup }
                    Repeater {
                        model: [
                            { days: 7, text: "Weekly  毎週", detail: "One new episode every week. The real TV experience. (recommended)" },
                            { days: 3, text: "Every 3 days", detail: "Twice a week-ish, for impatient people." },
                            { days: 1, text: "Daily  毎日", detail: "One a day, like a morning drama." }
                        ]
                        RetroRadio {
                            Layout.fillWidth: true
                            text: modelData.text
                            detail: modelData.detail
                            checked: Math.round(page.interval / 86400) === modelData.days
                            ButtonGroup.group: scheduleGroup
                            onClicked: page.interval = modelData.days * 86400
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: airCol.implicitHeight + 16
                        radius: 8
                        color: "#FFFBE6"
                        border.width: 2
                        border.color: Theme.ink
                        Column {
                            id: airCol
                            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 8 }
                            spacing: 2
                            Repeater {
                                model: {
                                    var n = page.includedCount
                                    var out = []
                                    if (n === 0)
                                        return out
                                    var now = backend.now
                                    out.push("Episode 1 · airs RIGHT NOW!")
                                    for (var i = 1; i < Math.min(n, 3); i++)
                                        out.push("Episode " + (i + 1) + " · " + Theme.airText(now + i * page.interval))
                                    if (n > 4)
                                        out.push("...")
                                    if (n > 3)
                                        out.push("Final episode " + n + " · " + Theme.airText(now + (n - 1) * page.interval))
                                    return out
                                }
                                Text {
                                    text: "☆ " + modelData
                                    font.family: Theme.pixel
                                    font.pixelSize: 14
                                    color: Theme.ink
                                }
                            }
                        }
                    }
                }

                GlossButton {
                    visible: page.scan && page.scan.ok
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 6
                    Layout.bottomMargin: 10
                    text: "START BROADCAST!  放送開始"
                    fontSize: 20
                    baseColor: Theme.hotPink
                    blink: true
                    enabled: page.includedCount > 0 && page.title.trim() !== "" && !page.probing
                    onClicked: page.startBroadcast()
                }
            }
        }
    }

    component Section: ColumnLayout {
        id: section
        property string number: ""
        property string title: ""
        property string jp: ""
        Layout.fillWidth: true
        spacing: 8
        RowLayout {
            spacing: 8
            Rectangle {
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                radius: 14
                color: Theme.hotPink
                border.width: 2
                border.color: Theme.ink
                Text {
                    anchors.centerIn: parent
                    text: section.number
                    font.family: Theme.pixel
                    font.pixelSize: 16
                    color: "white"
                }
            }
            Text {
                text: section.title
                font.family: Theme.pixel
                font.pixelSize: 18
                color: Theme.ink
            }
            Text {
                text: section.jp
                font.family: Theme.pixel
                font.pixelSize: 13
                color: Theme.inkSoft
            }
        }
    }
}
