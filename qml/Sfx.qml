pragma Singleton
import QtQuick
import QtMultimedia

// Chiptune UI blips. Toggle in Settings.
QtObject {
    property bool enabled: backend.settings.sounds

    property SoundEffect clickFx: SoundEffect { source: assetsUrl + "sounds/click.wav"; volume: 0.35 }
    property SoundEffect openFx: SoundEffect { source: assetsUrl + "sounds/open.wav"; volume: 0.35 }
    property SoundEffect backFx: SoundEffect { source: assetsUrl + "sounds/back.wav"; volume: 0.35 }
    property SoundEffect onAirFx: SoundEffect { source: assetsUrl + "sounds/onair.wav"; volume: 0.45 }
    property SoundEffect completeFx: SoundEffect { source: assetsUrl + "sounds/complete.wav"; volume: 0.4 }
    property SoundEffect errorFx: SoundEffect { source: assetsUrl + "sounds/error.wav"; volume: 0.35 }
    property SoundEffect tvOnFx: SoundEffect { source: assetsUrl + "sounds/tvon.wav"; volume: 0.5 }

    function click() { if (enabled) clickFx.play() }
    function open() { if (enabled) openFx.play() }
    function back() { if (enabled) backFx.play() }
    function onAir() { if (enabled) onAirFx.play() }
    function complete() { if (enabled) completeFx.play() }
    function error() { if (enabled) errorFx.play() }
    function tvOn() { if (enabled) tvOnFx.play() }
}
