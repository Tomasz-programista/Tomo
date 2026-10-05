import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import QtQuick.Particles
import QtMultimedia
import ".."
import "../components"
import "../screen"
import "../Modes.js" as Modes

// The TV. Plays one episode (TV mode) or any file (free play).
Item {
    id: player
    property var info: ({})
    readonly property bool tvMode: info.mode === "tv"
    readonly property string channelText: tvMode ? "CH " + info.channelNumber : "ビデオ1"

    // watch progress
    property real watched: info.fraction || 0
    property var segments: info.segments || []
    property bool completed: info.isRerun === true
    property bool loaded: false
    property bool titleCardDone: !tvMode
    property bool ended: false
    property bool finished: false   // shutdown() ran

    // tracks
    property var audioTracks: []
    property var subTracks: []
    property int audioIndex: -1
    property var subChoice: ({ kind: "off" })
    property bool tracksApplied: false

    // sound
    property real volume: window.settings.volume
    property bool muted: false

    // chrome
    readonly property bool fullscreen: window.visibility === Window.FullScreen
    property bool controlsShown: true
    readonly property bool playing: mp.playbackState === MediaPlayer.PlayingState
    readonly property var mode: Modes.find(window.settings.screen)

    focus: true

    // ------------------------------------------------------------ lifecycle

    Component.onCompleted: {
        subtitleRelay.setMode("off")
        subtitleRelay.target = emulator.video.videoSink
        if (tvMode)
            titleCard.show()
        forceActiveFocus()
    }
    Component.onDestruction: shutdown()

    function shutdown() {
        if (finished)
            return
        finished = true
        var pos = mp.position
        mp.stop()
        subtitleRelay.setMode("off")
        subtitleRelay.target = null
        backend.closeEpisode(pos)
        saveVolume()
    }

    function onLoaded() {
        refreshTracks()
        if (info.resume > 0) {
            mp.position = info.resume
            osd.message("Resumed from " + Theme.timecode(info.resume), "続きから")
        }
        if (titleCardDone)
            startPlaying()
    }

    function startPlaying() {
        mp.play()
        osd.showChannel()
        if (mode.id === "stream")
            osd.buffering()
    }

    function onEnded() {
        ended = true
        if (tvMode && mp.duration <= 0) {
            // Some files never report their length; the end position is the length then.
            var r = backend.reportProgress(mp.position, mp.position, false)
            if (r.newlyCompleted)
                celebrate()
        }
        if (tvMode) {
            endDialog.refresh()
            endDialog.open()
        } else {
            osd.message("END", "おわり")
        }
    }

    // ------------------------------------------------------------ tracks

    function refreshTracks() {
        var a = [], s = []
        for (var i = 0; i < mp.audioTracks.length; i++) {
            var t = mp.audioTracks[i]
            var lang = t.stringValue(MediaMetaData.Language), title = t.stringValue(MediaMetaData.Title)
            var codec = t.stringValue(MediaMetaData.AudioCodec)
            a.push({ index: i, lang: lang, title: title, codec: codec,
                     label: (lang || "Unknown") + (title && title.toLowerCase() !== lang.toLowerCase() ? " — " + title : "") + (codec ? " [" + codec + "]" : "") })
        }
        for (var j = 0; j < mp.subtitleTracks.length; j++) {
            var st = mp.subtitleTracks[j]
            var sl = st.stringValue(MediaMetaData.Language), stt = st.stringValue(MediaMetaData.Title)
            s.push({ index: j, lang: sl, title: stt,
                     label: (sl || "Unknown") + (stt && stt.toLowerCase() !== sl.toLowerCase() ? " — " + stt : "") })
        }
        audioTracks = a
        subTracks = s
        if (!tracksApplied && (mp.mediaStatus === MediaPlayer.LoadedMedia || a.length > 0 || s.length > 0)) {
            tracksApplied = true
            var ai = backend.pickAudio(info.audio, a)
            if (ai >= 0) {
                audioIndex = ai
                mp.activeAudioTrack = ai
            }
            applySubPref(info.subs || { kind: "off" })
        }
    }

    function applySubPref(pref) {
        var ext = info.externalOptions || []
        if (pref.kind === "external") {
            for (var i = 0; i < ext.length; i++)
                if (ext[i].label === pref.label)
                    return setSub({ kind: "external", path: ext[i].path, label: ext[i].label }, false)
        }
        if (pref.kind === "embedded" || pref.kind === "external" || pref.kind === "auto") {
            var idx = backend.pickSubtitle(pref.kind === "embedded" ? pref : null, subTracks)
            if (idx >= 0)
                return setSub({ kind: "embedded", index: idx }, false)
            if (ext.length > 0 && pref.kind !== "embedded")
                return setSub({ kind: "external", path: ext[0].path, label: ext[0].label }, false)
        }
        setSub({ kind: "off" }, false)
    }

    function setSub(choice, byUser) {
        subChoice = choice
        if (choice.kind === "embedded") {
            mp.activeSubtitleTrack = choice.index
            subtitleRelay.setMode("embedded")
        } else if (choice.kind === "external") {
            mp.activeSubtitleTrack = -1
            if (subtitleRelay.loadExternal(choice.path))
                subtitleRelay.setMode("external")
            else
                subtitleRelay.setMode("off")
        } else {
            mp.activeSubtitleTrack = -1
            subtitleRelay.setMode("off")
        }
        if (byUser) {
            osd.message(choice.kind === "off" ? "字幕 OFF" : "字幕 " + subName(choice), "")
            rememberTracks()
        }
    }

    function subName(choice) {
        if (choice.kind === "embedded" && subTracks[choice.index])
            return subTracks[choice.index].lang || ("#" + (choice.index + 1))
        if (choice.kind === "external")
            return "file"
        return "OFF"
    }

    function setAudio(index, byUser) {
        audioIndex = index
        mp.activeAudioTrack = index
        if (byUser) {
            var t = audioTracks[index]
            osd.message(audioName(index) + "  " + (t ? (t.lang || t.title || "") : ""), "")
            rememberTracks()
        }
    }

    function audioName(index) {
        if (audioTracks.length < 2)
            return "音声"
        return index === 0 ? "主音声" : (index === 1 ? "副音声" : "音声" + (index + 1))
    }

    function rememberTracks() {
        if (!tvMode)
            return
        var a = audioTracks[audioIndex]
        var audio = a ? { index: audioIndex, lang: a.lang, title: a.title } : null
        var subs = { kind: "off" }
        if (subChoice.kind === "embedded") {
            var s = subTracks[subChoice.index] || {}
            subs = { kind: "embedded", index: subChoice.index, lang: s.lang || "", title: s.title || "" }
        } else if (subChoice.kind === "external") {
            subs = { kind: "external", label: subChoice.label }
        }
        backend.rememberTracks(info.channelId, audio, subs)
    }

    function cycleAudio() {
        if (audioTracks.length > 1)
            setAudio((audioIndex + 1) % audioTracks.length, true)
    }

    function cycleSubs() {
        var opts = subOptions()
        var cur = JSON.stringify(subChoice)
        for (var i = 0; i < opts.length; i++)
            if (JSON.stringify(opts[i].value) === cur)
                return setSub(opts[(i + 1) % opts.length].value, true)
        setSub(opts[0].value, true)
    }

    function subOptions() {
        var opts = [{ text: "Off", detail: "no subtitles", value: { kind: "off" } }]
        for (var i = 0; i < subTracks.length; i++)
            opts.push({ text: subTracks[i].label, detail: "inside the video file", value: { kind: "embedded", index: i } })
        var ext = info.externalOptions || []
        for (var j = 0; j < ext.length; j++)
            opts.push({ text: "File: " + ext[j].description, detail: ext[j].path, value: { kind: "external", path: ext[j].path, label: ext[j].label } })
        return opts
    }

    // ------------------------------------------------------------ playback controls

    function togglePlay() {
        if (!loaded || !titleCardDone)
            return
        if (playing)
            mp.pause()
        else {
            if (ended) {
                ended = false
                endDialog.close()
            }
            mp.play()
        }
    }

    function seekTo(ms) {
        if (!loaded)
            return
        var target = Math.max(0, Math.min(mp.duration - 500, ms))
        osd.vcr(target < mp.position ? "rew" : "ff")
        mp.position = target
        backend.notifySeek()
        if (ended && target < mp.duration - 1000) {
            ended = false
            endDialog.close()
            mp.play()
        }
    }

    function changeVolume(v) {
        volume = Math.max(0, Math.min(1, v))
        muted = false
        osd.showVolume()
        volumeSave.restart()
    }

    function saveVolume() {
        if (Math.abs(window.settings.volume - volume) > 0.001)
            backend.setSetting("volume", volume)
    }

    function toggleFullscreen() {
        if (fullscreen)
            window.showNormal()
        else
            window.showFullScreen()
    }

    function cycleScreen(step) {
        var i = Modes.indexOf(window.settings.screen)
        var n = Modes.modes.length
        var next = Modes.modes[(i + step + n) % n]
        backend.setSetting("screen", next.id)
        osd.message(next.name, next.jp)
    }

    function poke() {
        controlsShown = true
        hideTimer.restart()
    }

    Keys.onPressed: (event) => {
        poke()
        switch (event.key) {
        case Qt.Key_Space: case Qt.Key_K: togglePlay(); break
        case Qt.Key_Left: case Qt.Key_J: seekTo(mp.position - 10000); break
        case Qt.Key_Right: case Qt.Key_L: seekTo(mp.position + 10000); break
        case Qt.Key_Up: changeVolume(volume + 0.05); break
        case Qt.Key_Down: changeVolume(volume - 0.05); break
        case Qt.Key_M: muted = !muted; osd.showVolume(); break
        case Qt.Key_F: case Qt.Key_F11: toggleFullscreen(); break
        case Qt.Key_A: cycleAudio(); break
        case Qt.Key_S: cycleSubs(); break
        case Qt.Key_V: cycleScreen(event.modifiers & Qt.ShiftModifier ? -1 : 1); break
        case Qt.Key_I: osd.showChannel(); break
        case Qt.Key_Escape:
            if (fullscreen)
                window.showNormal()
            else
                window.closePlayer()
            break
        default: return
        }
        event.accepted = true
    }

    Timer {
        id: volumeSave
        interval: 900
        onTriggered: player.saveVolume()
    }

    Timer {
        id: hideTimer
        interval: 2600
        onTriggered: if (player.playing) player.controlsShown = false
    }

    Timer {
        interval: 250
        repeat: true
        running: player.tvMode && player.loaded && !player.finished
        onTriggered: {
            var r = backend.reportProgress(mp.position, mp.duration, player.playing)
            if (r.fraction === undefined)
                return
            player.watched = r.fraction
            player.segments = r.segments
            if (r.newlyCompleted)
                player.celebrate()
            player.completed = r.completed
        }
    }

    function celebrate() {
        Sfx.complete()
        osd.complete()
        var ch = backend.currentChannel()
        var next = ""
        if (ch.finished)
            next = "That was the last one. Series complete!"
        else if (ch.canWatch)
            next = ch.nextLabel + " is already on air."
        else if (ch.nextEpisodeAir)
            next = ch.nextLabel + " airs " + Theme.airText(ch.nextEpisodeAir) + "."
        window.toast("★ EPISODE COUNTED! ★", info.label + " is marked as watched. " + next, "done")
    }

    MediaPlayer {
        id: mp
        source: player.info.url || ""
        videoOutput: subtitleRelay.sink
        audioOutput: AudioOutput {
            volume: player.volume
            muted: player.muted
        }
        onMediaStatusChanged: {
            if (mediaStatus === MediaPlayer.LoadedMedia && !player.loaded) {
                player.loaded = true
                player.onLoaded()
            } else if (mediaStatus === MediaPlayer.EndOfMedia) {
                player.onEnded()
            } else if (mediaStatus === MediaPlayer.InvalidMedia) {
                errorDialog.message = "This file can't be played."
                errorDialog.open()
            }
        }
        onTracksChanged: player.refreshTracks()
        onErrorOccurred: (error, message) => {
            errorDialog.message = message || "Something went wrong while playing."
            errorDialog.open()
        }
        onPlaybackStateChanged: {
            if (playbackState === MediaPlayer.PlayingState)
                osd.vcr("play")
            else if (playbackState === MediaPlayer.PausedState)
                osd.vcr("pause")
        }
    }

    // ------------------------------------------------------------ layout

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        cursorShape: player.controlsShown || !player.fullscreen ? Qt.ArrowCursor : Qt.BlankCursor
        onPositionChanged: player.poke()
    }

    // top bar
    Rectangle {
        id: topBar
        visible: !player.fullscreen
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: visible ? 52 : 0
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "#FFB7DD" }
            GradientStop { position: 1.0; color: "#C9B8FF" }
        }
        Rectangle {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: 3
            color: Theme.ink
        }
        RowLayout {
            anchors { fill: parent; leftMargin: 12; rightMargin: 14; bottomMargin: 3 }
            spacing: 12
            GlossButton {
                small: true
                text: "BACK"
                iconName: "back"
                baseColor: Theme.purple
                onClicked: window.closePlayer()
            }
            Rectangle {
                Layout.preferredWidth: chLabel.implicitWidth + 16
                Layout.preferredHeight: 28
                radius: 6
                color: "#14102A"
                border.width: 2
                border.color: Theme.ink
                Text {
                    id: chLabel
                    anchors.centerIn: parent
                    text: player.channelText
                    font.family: Theme.pixel
                    font.pixelSize: 15
                    color: Theme.osdGreen
                }
            }
            Text {
                Layout.fillWidth: true
                text: player.tvMode
                      ? player.info.channelTitle + "  ·  " + player.info.label + "  ·  " + player.info.name
                      : player.info.name
                font.family: Theme.pixel
                font.pixelSize: 17
                color: Theme.ink
                elide: Text.ElideRight
            }
            Rectangle {
                visible: player.info.isRerun === true
                Layout.preferredWidth: rerunText.implicitWidth + 14
                Layout.preferredHeight: 24
                radius: 4
                color: Theme.purple
                border.width: 2
                border.color: Theme.ink
                Text { id: rerunText; anchors.centerIn: parent; text: "RERUN 再放送"; font.family: Theme.pixel; font.pixelSize: 12; color: "white" }
            }
            LcdDisplay {
                text: Theme.clock(backend.now)
                pixelSize: 18
            }
        }
    }

    ScreenEmulator {
        id: emulator
        anchors {
            left: parent.left; right: parent.right
            top: topBar.bottom
            bottom: player.fullscreen ? parent.bottom : controls.top
            margins: player.fullscreen ? 0 : 14
        }
        modeId: window.settings.screen
        signalLines: window.settings.signal
        aspectChoice: window.settings.aspect
        fitChoice: window.settings.fit
        showFrame: window.settings.frame
        playing: player.playing
        channelText: player.channelText
        fileName: player.info.url ? decodeURIComponent(player.info.url.split("/").pop()) : ""

        // ~~~~~~~~ everything below is drawn INSIDE the emulated screen ~~~~~~~~
        Item {
            id: osd
            anchors.fill: parent
            readonly property real u: Math.max(6, height / 100)   // 1% of the screen height
            property string vcrState: ""

            function showChannel() { channelOsd.flash(5000) }
            function message(text, sub) { msgText.text = text; msgSub.text = sub || ""; msgOsd.flash(2600) }
            function showVolume() { volumeOsd.flash(2000) }
            function vcr(state) {
                vcrState = state
                if (state === "pause")
                    vcrOsd.flash(0)                 // stays up while paused
                else if (state === "play" && player.mode.id !== "vhs")
                    vcrOsd.hideNow()
                else
                    vcrOsd.flash(state === "play" ? 2500 : 1500)
            }
            function buffering() { bufferOsd.start() }
            function complete() { completeOsd.flash(3500); confetti.burst(80) }

            // subtitles
            OutlinedText {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: parent.width * 0.04; bottomMargin: parent.height * 0.055 }
                text: subtitleRelay.bottom
                pixelSize: Math.max(11, osd.u * 5.6)
            }
            OutlinedText {
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: parent.width * 0.04; topMargin: parent.height * 0.05 }
                text: subtitleRelay.top
                pixelSize: Math.max(10, osd.u * 4.8)
            }

            // channel number + broadcast marks, top right like an old TV
            OsdItem {
                id: channelOsd
                anchors { right: parent.right; top: parent.top; margins: osd.u * 5 }
                Column {
                    spacing: osd.u
                    Row {
                        anchors.right: parent.right
                        spacing: osd.u
                        Text {
                            anchors.baseline: chNum.baseline
                            text: player.tvMode ? "CH" : ""
                            font.family: Theme.pixel
                            font.pixelSize: osd.u * 5
                            color: Theme.osdGreen
                            style: Text.Outline
                            styleColor: "black"
                        }
                        Text {
                            id: chNum
                            text: player.tvMode ? player.info.channelNumber : "ビデオ1"
                            font.family: Theme.pixel
                            font.pixelSize: osd.u * (player.tvMode ? 12 : 7)
                            color: Theme.osdGreen
                            style: Text.Outline
                            styleColor: "black"
                        }
                    }
                    Row {
                        anchors.right: parent.right
                        spacing: osd.u * 0.8
                        Repeater {
                            model: {
                                var marks = []
                                if (player.tvMode && player.info.index === 0 && !player.info.isRerun) marks.push("新")
                                if (player.tvMode && player.info.isFinale && !player.info.isRerun) marks.push("終")
                                if (player.info.isRerun) marks.push("再")
                                if (player.subChoice.kind !== "off") marks.push("字")
                                if (player.audioTracks.length > 1) marks.push("二")
                                return marks
                            }
                            Rectangle {
                                width: osd.u * 5.4
                                height: width
                                color: "transparent"
                                border.width: Math.max(1, osd.u * 0.45)
                                border.color: "white"
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData
                                    font.family: Theme.pixel
                                    font.pixelSize: osd.u * 3.8
                                    color: "white"
                                    style: Text.Outline
                                    styleColor: "black"
                                }
                            }
                        }
                    }
                    Text {
                        anchors.right: parent.right
                        visible: player.tvMode
                        text: player.info.label || ""
                        font.family: Theme.pixel
                        font.pixelSize: osd.u * 4
                        color: "white"
                        style: Text.Outline
                        styleColor: "black"
                    }
                }
            }

            // VCR style status, top left
            OsdItem {
                id: vcrOsd
                anchors { left: parent.left; top: parent.top; margins: osd.u * 5 }
                Row {
                    spacing: osd.u * 1.5
                    Text {
                        text: osd.vcrState === "play" ? "PLAY" : osd.vcrState === "pause" ? "PAUSE"
                            : osd.vcrState === "rew" ? "REW" : "FF"
                        font.family: Theme.pixel
                        font.pixelSize: osd.u * 6
                        color: "white"
                        style: Text.Outline
                        styleColor: "black"
                    }
                    Image {
                        anchors.verticalCenter: parent.verticalCenter
                        source: Theme.icon(osd.vcrState === "pause" ? "pause" : osd.vcrState === "rew" ? "rewind" : osd.vcrState === "ff" ? "forward" : "play")
                        sourceSize: Qt.size(osd.u * 6, osd.u * 6)
                    }
                }
            }

            // tape counter in VHS mode
            Text {
                visible: player.mode.id === "vhs"
                anchors { right: parent.right; bottom: parent.bottom; margins: osd.u * 5 }
                text: "SP  " + Theme.timecode(mp.position)
                font.family: Theme.pixel
                font.pixelSize: osd.u * 5
                color: "white"
                style: Text.Outline
                styleColor: "black"
            }

            // messages (audio / subtitle switching...)
            OsdItem {
                id: msgOsd
                anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: parent.height * 0.18 }
                Column {
                    spacing: osd.u
                    Text {
                        id: msgText
                        anchors.horizontalCenter: parent.horizontalCenter
                        font.family: Theme.pixel
                        font.pixelSize: osd.u * 6
                        color: Theme.osdGreen
                        style: Text.Outline
                        styleColor: "black"
                    }
                    Text {
                        id: msgSub
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: text !== ""
                        font.family: Theme.pixel
                        font.pixelSize: osd.u * 4
                        color: "white"
                        style: Text.Outline
                        styleColor: "black"
                    }
                }
            }

            // volume bars
            OsdItem {
                id: volumeOsd
                anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: parent.height * 0.2 }
                Row {
                    spacing: osd.u * 1.2
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: player.muted ? "消音" : "音量"
                        font.family: Theme.pixel
                        font.pixelSize: osd.u * 5
                        color: Theme.osdGreen
                        style: Text.Outline
                        styleColor: "black"
                    }
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: osd.u * 0.5
                        Repeater {
                            model: 20
                            Rectangle {
                                width: osd.u * 1.3
                                height: osd.u * 4.5
                                color: !player.muted && index < Math.round(player.volume * 20) ? Theme.osdGreen : "#30FFFFFF"
                                border.width: 1
                                border.color: "black"
                            }
                        }
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: player.muted ? "" : Math.round(player.volume * 100)
                        font.family: Theme.pixel
                        font.pixelSize: osd.u * 5
                        color: Theme.osdGreen
                        style: Text.Outline
                        styleColor: "black"
                    }
                }
            }

            // 56k buffering gag
            Rectangle {
                id: bufferOsd
                property real pct: 0
                visible: false
                anchors.centerIn: parent
                width: bufferText.implicitWidth + osd.u * 6
                height: bufferText.implicitHeight + osd.u * 4
                color: "#C0000000"
                border.width: 1
                border.color: "white"
                function start() { pct = 0; visible = true; bufferAnim.restart() }
                Text {
                    id: bufferText
                    anchors.centerIn: parent
                    text: "Buffering... " + Math.round(bufferOsd.pct) + "%"
                    font.family: Theme.pixel
                    font.pixelSize: osd.u * 5
                    color: "white"
                }
                SequentialAnimation {
                    id: bufferAnim
                    NumberAnimation { target: bufferOsd; property: "pct"; to: 87; duration: 1800 }
                    PauseAnimation { duration: 600 }
                    NumberAnimation { target: bufferOsd; property: "pct"; to: 100; duration: 500 }
                    ScriptAction { script: bufferOsd.visible = false }
                }
            }

            // episode complete!
            OsdItem {
                id: completeOsd
                anchors.centerIn: parent
                Column {
                    spacing: osd.u
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "★ 視聴完了 ★"
                        font.family: Theme.pixel
                        font.pixelSize: osd.u * 10
                        color: Theme.yellow
                        style: Text.Outline
                        styleColor: "black"
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "EPISODE COUNTED!"
                        font.family: Theme.pixel
                        font.pixelSize: osd.u * 5
                        color: "white"
                        style: Text.Outline
                        styleColor: "black"
                    }
                }
            }

            ParticleSystem { id: confettiSystem }
            ImageParticle {
                system: confettiSystem
                source: Theme.asset("img/star.png")
                color: Theme.yellow
                colorVariation: 0.9
                rotationVariation: 180
                rotationVelocityVariation: 300
            }
            Emitter {
                id: confetti
                system: confettiSystem
                anchors { horizontalCenter: parent.horizontalCenter; top: parent.top }
                width: parent.width * 0.8
                height: 2
                emitRate: 0
                lifeSpan: 2600
                size: osd.u * 4
                sizeVariation: osd.u * 2
                velocity: AngleDirection { angle: 90; angleVariation: 35; magnitude: osd.u * 25; magnitudeVariation: osd.u * 15 }
                acceleration: PointDirection { y: osd.u * 20 }
            }

            // title card before the episode
            Rectangle {
                id: titleCard
                anchors.fill: parent
                visible: false
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#FF9ACB" }
                    GradientStop { position: 1.0; color: "#8E6CF0" }
                }
                function show() { visible = true; opacity = 1; cardAnim.restart() }
                Sparkles {
                    anchors.fill: parent
                    count: 18
                    maxSize: osd.u * 8
                }
                Column {
                    anchors.centerIn: parent
                    spacing: osd.u * 2
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "TOMO☆TV  " + player.channelText
                        font.family: Theme.pixel
                        font.pixelSize: osd.u * 4.5
                        color: "white"
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: player.info.label || ""
                        font.family: Theme.pixel
                        font.pixelSize: osd.u * 17
                        color: "white"
                        style: Text.Outline
                        styleColor: Theme.ink
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: titleCard.width * 0.8
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        text: player.info.name || ""
                        font.family: Theme.body
                        font.weight: Font.ExtraBold
                        font.pixelSize: osd.u * 5.5
                        color: "white"
                        style: Text.Outline
                        styleColor: Theme.ink
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: player.info.isFinale ? "～ 最終回 FINALE ～" : (player.info.index === 0 ? "～ 新番組 PREMIERE ～" : "")
                        visible: text !== ""
                        font.family: Theme.pixel
                        font.pixelSize: osd.u * 5
                        color: Theme.yellow
                        style: Text.Outline
                        styleColor: Theme.ink
                    }
                }
                SequentialAnimation {
                    id: cardAnim
                    PauseAnimation { duration: 2600 }
                    NumberAnimation { target: titleCard; property: "opacity"; to: 0; duration: 500 }
                    ScriptAction {
                        script: {
                            titleCard.visible = false
                            player.titleCardDone = true
                            if (player.loaded)
                                player.startPlaying()
                        }
                    }
                }
            }
        }
    }

    // ------------------------------------------------------------ control panel

    Rectangle {
        id: controls
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: player.fullscreen ? 18 : 0 }
        height: 112
        radius: player.fullscreen ? 16 : 0
        opacity: !player.fullscreen || player.controlsShown ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 250 } }
        border.width: player.fullscreen ? 3 : 0
        border.color: Theme.ink
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#FFFFFF" }
            GradientStop { position: 1.0; color: "#E9E1FF" }
        }
        Rectangle {
            visible: !player.fullscreen
            anchors { left: parent.left; right: parent.right; top: parent.top }
            height: 3
            color: Theme.ink
        }

        ColumnLayout {
            anchors { fill: parent; leftMargin: 18; rightMargin: 18; topMargin: 8; bottomMargin: 10 }
            spacing: 6

            WatchBar {
                Layout.fillWidth: true
                position: mp.position
                duration: mp.duration
                segments: player.segments
                tvMode: player.tvMode
                completed: player.completed
                onSeekRequested: (ms) => player.seekTo(ms)
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                IconButton { iconName: "rewind"; tip: "-10s  (←)"; onClicked: player.seekTo(mp.position - 10000) }
                IconButton {
                    iconName: player.playing ? "pause" : "play"
                    size: 52
                    baseColor: Theme.pink
                    tip: "Play / pause  (Space)"
                    onClicked: player.togglePlay()
                }
                IconButton { iconName: "forward"; tip: "+10s  (→)"; onClicked: player.seekTo(mp.position + 10000) }

                LcdDisplay {
                    text: Theme.timecode(mp.position) + " / " + Theme.timecode(mp.duration)
                    pixelSize: 17
                }

                // watch meter
                Column {
                    visible: player.tvMode
                    spacing: 3
                    Text {
                        text: player.completed ? "★ COUNTED!  視聴完了" : "WATCHED  " + Math.round(player.watched * 100) + "% / 70%"
                        font.family: Theme.pixel
                        font.pixelSize: 13
                        color: player.completed ? "#C98A00" : Theme.ink
                    }
                    Rectangle {
                        width: 170
                        height: 12
                        radius: 6
                        color: "#EDE6FF"
                        border.width: 2
                        border.color: Theme.ink
                        Rectangle {
                            width: Math.max(0, Math.min(1, player.watched)) * (parent.width - 4)
                            x: 2; y: 2
                            height: parent.height - 4
                            radius: 4
                            color: player.completed ? Theme.yellow : Theme.pink
                        }
                        Rectangle {
                            x: parent.width * 0.7
                            y: -3
                            width: 2
                            height: parent.height + 6
                            color: Theme.ink
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                IconButton {
                    iconName: player.muted ? "mute" : "volume"
                    size: 36
                    baseColor: Theme.mint
                    tip: "Mute  (M)"
                    onClicked: { player.muted = !player.muted; osd.showVolume() }
                }
                RetroSlider {
                    Layout.preferredWidth: 120
                    from: 0
                    to: 1
                    value: player.volume
                    focusPolicy: Qt.NoFocus
                    onMoved: player.changeVolume(value)
                }
                IconButton {
                    iconName: "audio"
                    size: 40
                    baseColor: Theme.orange
                    tip: "Audio track  (A)"
                    enabled: player.audioTracks.length > 0
                    onClicked: audioPopup.open()
                }
                IconButton {
                    iconName: "subs"
                    size: 40
                    baseColor: Theme.yellow
                    checked: player.subChoice.kind !== "off"
                    tip: "Subtitles  (S)"
                    onClicked: subsPopup.open()
                }
                IconButton {
                    iconName: "tv"
                    size: 40
                    baseColor: Theme.cyan
                    tip: "Screen: " + player.mode.name + "  (V)"
                    onClicked: screenDialog.open()
                }
                IconButton {
                    iconName: "fullscreen"
                    size: 40
                    baseColor: Theme.purple
                    tip: "Fullscreen  (F)"
                    onClicked: player.toggleFullscreen()
                }
            }
        }
    }

    // ------------------------------------------------------------ popups

    ChoicePopup {
        id: audioPopup
        title: "AUDIO"
        jp: "音声切替"
        accent: Theme.orange
        options: {
            var out = []
            for (var i = 0; i < player.audioTracks.length; i++)
                out.push({ text: player.audioName(i) + "  " + player.audioTracks[i].label, value: i })
            return out
        }
        current: player.audioIndex
        onChosen: (value) => player.setAudio(value, true)
        onClosed: player.forceActiveFocus()
    }

    ChoicePopup {
        id: subsPopup
        title: "SUBTITLES"
        jp: "字幕"
        accent: Theme.yellow
        accent2: Theme.orange
        options: player.subOptions()
        current: player.subChoice
        onChosen: (value) => player.setSub(value, true)
        onClosed: player.forceActiveFocus()
    }

    ScreenDialog {
        id: screenDialog
        onClosed: player.forceActiveFocus()
    }

    RetroDialog {
        id: errorDialog
        property string message: ""
        title: "PLAYBACK ERROR"
        jp: "エラー"
        accent: Theme.red
        accent2: Theme.hotPink
        Text {
            Layout.fillWidth: true
            Layout.preferredWidth: 460
            wrapMode: Text.WordWrap
            text: "Tomo-chan couldn't play this video (´；ω；`)\n\n" + errorDialog.message
            font.family: Theme.body
            font.pixelSize: 14
            color: Theme.ink
        }
        GlossButton {
            Layout.alignment: Qt.AlignRight
            small: true
            text: "BACK TO GUIDE"
            onClicked: { errorDialog.close(); window.closePlayer() }
        }
    }

    // つづく — shown when an episode ends in TV mode
    RetroDialog {
        id: endDialog
        property var ch: ({})
        readonly property bool counted: ch.episodeDone === true
        closePolicy: Popup.CloseOnEscape
        title: counted ? (ch.finished ? "THE END" : "TO BE CONTINUED") : "NOT COUNTED YET"
        jp: counted ? (ch.finished ? "おしまい" : "つづく") : "もう少し!"
        accent: counted ? Theme.hotPink : Theme.orange
        implicitWidth: 560
        function refresh() { ch = backend.currentChannel() }
        onClosed: player.forceActiveFocus()

        RowLayout {
            Layout.fillWidth: true
            spacing: 16
            Image {
                Layout.alignment: Qt.AlignTop
                source: Theme.asset("img/mascot.svg")
                sourceSize: Qt.size(110, 121)
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8
                Text {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    font.family: Theme.pixel
                    font.pixelSize: 20
                    color: Theme.ink
                    text: !endDialog.counted ? "Hmm, that one doesn't count yet!"
                        : endDialog.ch.finished ? "You finished the whole show! おめでとう!"
                        : endDialog.ch.canWatch ? "Good news: " + endDialog.ch.nextLabel + " already aired!"
                        : "See you next week! また来週!"
                }
                Text {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    font.family: Theme.body
                    font.pixelSize: 14
                    color: Theme.inkSoft
                    text: !endDialog.counted
                        ? "You watched " + Math.round(player.watched * 100) + "% of this episode. Watch at least 70% (skipping doesn't count) and the next episode can air."
                        : endDialog.ch.finished
                          ? "All " + endDialog.ch.total + " episodes of " + endDialog.ch.title + ", one at a time. That's real dedication ☆ Reruns are always open."
                          : endDialog.ch.canWatch
                            ? "You have " + endDialog.ch.backlog + " aired episode" + (endDialog.ch.backlog === 1 ? "" : "s") + " waiting. Watch the next one now, or save it for later."
                            : endDialog.ch.nextLabel + " airs " + Theme.airText(endDialog.ch.nextEpisodeAir) + "."
                }
                LcdDisplay {
                    visible: endDialog.counted && !endDialog.ch.finished && !endDialog.ch.canWatch && endDialog.ch.nextEpisodeAir > 0
                    text: Theme.countdown(endDialog.ch.nextEpisodeAir - backend.now)
                    pixelSize: 20
                    litColor: "#FF9BD2"
                    backColor: "#2A1630"
                }
            }
        }
        RowLayout {
            Layout.alignment: Qt.AlignRight
            spacing: 8
            GlossButton {
                visible: !endDialog.counted
                small: true
                text: "REWIND & WATCH"
                baseColor: Theme.orange
                onClicked: {
                    endDialog.close()
                    player.ended = false
                    mp.position = 0
                    backend.notifySeek()
                    mp.play()
                }
            }
            GlossButton {
                small: true
                text: "BACK TO GUIDE"
                baseColor: endDialog.counted && endDialog.ch.canWatch ? "#B9B2D0" : Theme.pink
                onClicked: { endDialog.close(); window.closePlayer() }
            }
            GlossButton {
                visible: endDialog.counted && endDialog.ch.canWatch === true
                small: true
                text: "WATCH " + (endDialog.ch.nextLabel || "")
                baseColor: Theme.hotPink
                blink: true
                onClicked: {
                    endDialog.close()
                    window.watch(player.info.channelId, endDialog.ch.nextIndex)
                }
            }
        }
    }

    // An OSD element that shows for a while and then hides.
    component OsdItem: Item {
        id: item
        width: childrenRect.width
        height: childrenRect.height
        visible: false
        function flash(ms) {
            visible = true
            if (ms > 0) {
                hide.interval = ms
                hide.restart()
            } else {
                hide.stop()
            }
        }
        function hideNow() {
            hide.stop()
            visible = false
        }
        Timer {
            id: hide
            onTriggered: item.visible = false
        }
    }
}
