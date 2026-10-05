import QtQuick
import QtMultimedia
import ".."
import "../Modes.js" as Modes

// The emulated display: device frame + video at a chosen resolution + screen shader.
// Children of this item (subtitles, on-screen display) are drawn *into* the screen,
// so they get the same scanlines, dithering, etc.
Item {
    id: root
    property string modeId: "crt"
    property int signalLines: 0          // 0 = the mode's own resolution
    property string aspectChoice: "device"
    property string fitChoice: "letterbox"
    property bool showFrame: true
    property bool playing: false
    property string channelText: ""
    property string fileName: ""
    property alias video: videoOut
    default property alias overlay: overlayLayer.data

    readonly property var mode: Modes.find(modeId)
    readonly property real videoAspect: videoOut.sourceRect.width > 0 && videoOut.sourceRect.height > 0
        ? videoOut.sourceRect.width / videoOut.sourceRect.height : 16 / 9
    readonly property real screenAspect: Modes.ratio(aspectChoice === "device" ? mode.aspect : aspectChoice, videoAspect)
    readonly property int lines: signalLines > 0 ? signalLines : mode.lines
    readonly property bool hasShader: mode.shader !== ""
    readonly property bool lowRes: lines > 0
    readonly property size textureSize: lowRes
        ? Qt.size(Math.max(16, Math.round(lines * screenAspect * mode.hFactor)), lines)
        : Qt.size(0, 0)
    readonly property rect screenRect: frameLoader.item ? frameLoader.item.screenRect : Qt.rect(0, 0, width, height)
    readonly property alias screenItem: screen

    onModeIdChanged: pictureTex.scheduleUpdate()

    Loader {
        id: frameLoader
        anchors.fill: parent
        sourceComponent: {
            if (!root.showFrame)
                return bareFrame
            switch (root.mode.device) {
            case "tv": return tvFrame
            case "monitor": return monitorFrame
            case "phone": return phoneFrame
            case "handheld": return handheldFrame
            case "window": return windowFrame
            case "flat": return flatFrame
            }
            return bareFrame
        }
    }

    Component { id: bareFrame; BareFrame { aspect: root.screenAspect; playing: root.playing } }
    Component { id: tvFrame; TvFrame { aspect: root.screenAspect; playing: root.playing } }
    Component { id: monitorFrame; MonitorFrame { aspect: root.screenAspect; playing: root.playing } }
    Component { id: phoneFrame; PhoneFrame { aspect: root.screenAspect; playing: root.playing; channelText: root.channelText } }
    Component { id: handheldFrame; HandheldFrame { aspect: root.screenAspect; playing: root.playing } }
    Component { id: flatFrame; FlatFrame { aspect: root.screenAspect; playing: root.playing } }
    Component { id: windowFrame; WindowFrame { aspect: root.screenAspect; playing: root.playing; fileName: root.fileName || "stream.rm" } }

    Item {
        id: screen
        x: root.screenRect.x
        y: root.screenRect.y
        width: root.screenRect.width
        height: root.screenRect.height
        clip: true

        Item {
            id: picture
            anchors.fill: parent
            Rectangle {
                anchors.fill: parent
                color: "black"
            }
            VideoOutput {
                id: videoOut
                anchors.fill: parent
                fillMode: root.fitChoice === "stretch" ? VideoOutput.Stretch
                        : root.fitChoice === "zoom" ? VideoOutput.PreserveAspectCrop
                        : VideoOutput.PreserveAspectFit
            }
        }

        // The picture rendered at the emulated resolution.
        ShaderEffectSource {
            id: pictureTex
            anchors.fill: parent
            sourceItem: (root.hasShader || root.lowRes) ? picture : null
            hideSource: root.hasShader || root.lowRes
            visible: root.lowRes && !root.hasShader
            textureSize: root.textureSize
            smooth: root.mode.smooth
            live: root.mode.fps === 0
        }

        // Subtitles + OSD at full resolution, composited inside the shader.
        ShaderEffectSource {
            id: overlayTex
            sourceItem: root.hasShader ? overlayLayer : null
            hideSource: root.hasShader
            visible: false
        }

        ShaderEffect {
            id: effect
            anchors.fill: parent
            visible: root.hasShader
            property variant source: pictureTex
            property variant overlay: overlayTex
            property real time: 0
            property real curvature: root.mode.curvature
            property real strength: 1.0
            property real variant: root.mode.variant
            property size srcSize: root.lowRes ? root.textureSize : Qt.size(width, height)
            property size outSize: Qt.size(width * Screen.devicePixelRatio, height * Screen.devicePixelRatio)
            fragmentShader: root.hasShader ? shadersUrl + root.mode.shader + ".frag.qsb" : ""
        }

        Item {
            id: overlayLayer
            anchors.fill: parent
        }

        FrameAnimation {
            running: root.hasShader && root.visible
            onTriggered: effect.time = elapsedTime
        }

        Timer {
            interval: root.mode.fps > 0 ? Math.round(1000 / root.mode.fps) : 1000
            running: root.mode.fps > 0 && root.visible
            repeat: true
            onTriggered: pictureTex.scheduleUpdate()
        }
    }
}
