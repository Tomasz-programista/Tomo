import QtQuick
import QtQuick.Particles
import ".."

// Glitter that follows the mouse. Doesn't block clicks (HoverHandler is passive).
Item {
    id: root
    property bool active: true
    property point last: Qt.point(-1000, -1000)

    HoverHandler {
        id: hover
        enabled: root.active
        onPointChanged: {
            // Qt also sends hover updates when things animate under a still mouse: only sparkle on real movement.
            var p = point.position
            if (!root.active || !hovered || Math.abs(p.x - root.last.x) + Math.abs(p.y - root.last.y) < 8)
                return
            root.last = p
            emitter.burst(2)
        }
    }

    ParticleSystem {
        id: system
        running: root.active
    }

    ImageParticle {
        system: system
        source: Theme.asset("img/star.png")
        color: "#FFE94A"
        colorVariation: 0.7
        alpha: 0.9
        rotationVariation: 180
        rotationVelocityVariation: 240
        entryEffect: ImageParticle.Scale
    }

    Emitter {
        id: emitter
        system: system
        x: hover.point.position.x
        y: hover.point.position.y
        width: 2
        height: 2
        emitRate: 0
        maximumEmitted: 150
        lifeSpan: 650
        lifeSpanVariation: 250
        size: 14
        sizeVariation: 8
        endSize: 3
        velocity: AngleDirection { angle: 90; angleVariation: 70; magnitude: 45; magnitudeVariation: 35 }
        acceleration: PointDirection { y: 70 }
    }
}
