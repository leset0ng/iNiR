pragma ComponentBehavior: Bound
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls

/**
 * Material 3 circular progress bar with wavy effects.
 * See https://m3.material.io/components/progress-indicators/overview
 */
ProgressBar {
    id: root

    // Size properties (similar to valueBarWidth/Height in StyledProgressBar)
    property real size: 40
    property real indicatorSize: size // Compatibility alias
    property real lineWidth: 3
    property real gapAngle: 360 / 18  // Gap between track and progress ends

    // Color properties (matching StyledProgressBar API)
    property color highlightColor: Appearance?.colors.colPrimary ?? "#685496"
    property color trackColor: Appearance?.m3colors.m3secondaryContainer ?? "#E8DEF8"

    // Wavy effect properties (matching StyledProgressBar API)
    property bool wavy: false // If true, the progress bar will have a wavy fill effect
    property bool animateWave: true
    property real waveAmplitudeMultiplier: wavy ? 1 : 0
    property real waveFrequency: 6
    property real waveFps: 60
    property real _rotationOffset: 0

    // Circular specific properties
    property bool enableAnimation: true
    property int animationDuration: 800
    property var easingType: Easing.OutCubic

    // Keep size in sync with indicatorSize for backward compatibility
    onSizeChanged: if (indicatorSize !== size) indicatorSize = size
    onIndicatorSizeChanged: if (size !== indicatorSize) size = indicatorSize

    implicitWidth: size
    implicitHeight: size

    // Animation behaviors matching StyledProgressBar
    Behavior on waveAmplitudeMultiplier {
        animation: Appearance?.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    Behavior on value {
        animation: Appearance?.animation.elementMoveEnter.numberAnimation.createObject(this)
    }

    // Internal properties
    readonly property real degree: value * 360
    readonly property real centerX: root.width / 2
    readonly property real centerY: root.height / 2
    readonly property real arcRadius: root.size / 2 - root.lineWidth / 2
    readonly property real startAngle: -90

    // Background track
    background: Canvas {
        id: trackCanvas
        anchors.fill: parent
        implicitWidth: root.size
        implicitHeight: root.size

        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            // Draw regular circular track
            ctx.strokeStyle = root.trackColor;
            ctx.lineWidth = root.lineWidth;
            ctx.lineCap = "round";
            ctx.beginPath();
            ctx.arc(root.centerX, root.centerY, root.arcRadius, 0, 2 * Math.PI);
            ctx.stroke();

        }
    }

    // Content item (progress indicator)
    contentItem: Canvas {
        id: progressCanvas
        anchors.fill: parent

        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(-lineWidth, -lineWidth, size + 2*lineWidth,height+ 2*lineWidth);

            if (root.value <= 0) return;

            if (root.wavy && wavyShapesLoader.item) {
                // Draw wavy progress using WavyCircular shapes
                var shapes = wavyShapesLoader.item;
                ctx.strokeStyle = root.highlightColor;
                ctx.lineWidth = root.lineWidth;
                ctx.lineCap = "round";

                // Scale to match the normalized polygon coordinates to canvas size
                var scale = root.arcRadius;

                ctx.save();

                // Create clipping region for progress arc
                ctx.beginPath();
                var progressAngle = root.degree * Math.PI / 180;
                ctx.moveTo(root.centerX, root.centerY);
                ctx.arc(root.centerX, root.centerY, root.size, -Math.PI / 2, -Math.PI / 2 + progressAngle, false);
                ctx.closePath();
                ctx.clip();

                shapes.drawProgressPath(ctx, root.centerX, root.centerY, root.size, root._rotationOffset);

                ctx.stroke();
                ctx.restore();
            } else {
                // Draw regular arc progress
                ctx.strokeStyle = root.highlightColor;
                ctx.lineWidth = root.lineWidth;
                ctx.lineCap = "round";
                ctx.beginPath();
                ctx.arc(
                    root.centerX, root.centerY, root.arcRadius,
                    -Math.PI / 2,
                    -Math.PI / 2 + (root.degree * Math.PI / 180)
                );
                ctx.stroke();
            }
        }
    }

    // Wavy shapes loader (only active when wavy mode is enabled)
    Loader {
        id: wavyShapesLoader
        active: root.wavy
        sourceComponent: WavyCircular {
            id: wavyShapes
            size: root.size/2
            strokeWidth: root.lineWidth
            requiresMorph: true
            amplitude:root.waveAmplitudeMultiplier
            frequency: root.waveFrequency

            // Update canvases when shapes are ready
            onUpdated: {
                trackCanvas.requestPaint();
                progressCanvas.requestPaint();
            }
        }
    }

    // Rotation animation frame
    FrameAnimation {
        running: root.wavy && root.animateWave
        onTriggered: {
            // Update rotation animation (0-1 range, maps to 0-360 degrees)
            if (wavyShapesLoader.item) {
                root._rotationOffset = (Date.now() / 3200.0 / Math.PI) % 1;
                progressCanvas.requestPaint();
            }
        }
    }

    // Trigger repaints when properties change
    onValueChanged: progressCanvas.requestPaint()
    onHighlightColorChanged: progressCanvas.requestPaint()
    onTrackColorChanged: trackCanvas.requestPaint()
    on_RotationOffsetChanged: progressCanvas.requestPaint()
}
