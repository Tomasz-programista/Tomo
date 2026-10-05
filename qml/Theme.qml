pragma Singleton
import QtQuick

QtObject {
    // ~ palette ~
    readonly property color ink: "#2B2350"
    readonly property color inkSoft: "#5B4F8F"
    readonly property color paper: "#FFFFFF"
    readonly property color paperPink: "#FFF5FB"
    readonly property color pink: "#FF5FA8"
    readonly property color hotPink: "#FF2E88"
    readonly property color babyPink: "#FFD3EA"
    readonly property color lavender: "#E7DDFF"
    readonly property color purple: "#8B5CF6"
    readonly property color cyan: "#3FD2FF"
    readonly property color sky: "#C4EEFF"
    readonly property color mint: "#62E8B0"
    readonly property color lime: "#B5F43C"
    readonly property color yellow: "#FFE94A"
    readonly property color orange: "#FF9F43"
    readonly property color red: "#FF3B5C"
    readonly property color onAir: "#FF2442"
    readonly property color osdGreen: "#62FF6E"
    readonly property color shadow: "#552B2350"

    // ~ fonts (loaded by Python) ~
    readonly property string pixel: appFonts.pixel
    readonly property string body: appFonts.body
    readonly property string tiny: appFonts.tiny
    readonly property string lcd: appFonts.lcd

    readonly property var rainbow: ["#FF5FA8", "#FF9F43", "#F5C400", "#3CCB6E", "#3FB8FF", "#8B5CF6"]

    function asset(path) { return assetsUrl + path }
    function icon(name) { return assetsUrl + "img/icons/" + name + ".svg" }

    // ~ time helpers ~
    readonly property var daysJa: ["日", "月", "火", "水", "木", "金", "土"]
    readonly property var daysEn: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    readonly property var monthsEn: ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

    function pad(n) { return (n < 10 ? "0" : "") + n }

    function clock(t) {
        var d = new Date(t * 1000)
        return pad(d.getHours()) + ":" + pad(d.getMinutes())
    }

    function dateJa(t) {
        var d = new Date(t * 1000)
        return (d.getMonth() + 1) + "月" + d.getDate() + "日(" + daysJa[d.getDay()] + ")"
    }

    function dateEn(t) {
        var d = new Date(t * 1000)
        return daysEn[d.getDay()] + " " + d.getDate() + " " + monthsEn[d.getMonth()]
    }

    function airText(t) {
        return dateEn(t) + " · " + clock(t)
    }

    function countdown(seconds) {
        var s = Math.max(0, Math.floor(seconds))
        var days = Math.floor(s / 86400)
        s -= days * 86400
        var h = Math.floor(s / 3600), m = Math.floor((s % 3600) / 60), sec = s % 60
        var hms = pad(h) + ":" + pad(m) + ":" + pad(sec)
        return days > 0 ? days + "d " + hms : hms
    }

    function timecode(ms) {
        var s = Math.max(0, Math.floor(ms / 1000))
        var h = Math.floor(s / 3600), m = Math.floor((s % 3600) / 60), sec = s % 60
        return (h > 0 ? h + ":" + pad(m) : m) + ":" + pad(sec)
    }

    function intervalName(seconds) {
        var days = Math.round(seconds / 86400)
        if (days === 7) return "Weekly 毎週"
        if (days === 1) return "Daily 毎日"
        if (seconds < 86400) return "Every " + Math.round(seconds / 3600) + "h"
        return "Every " + days + " days"
    }
}
