import QtQuick
import qs.modules.common
import "shapes/material-shapes.js" as MaterialShapes
import "shapes/shapes/rounded-polygon.js" as RoundedPolygon
import "shapes/shapes/corner-rounding.js" as CornerRounding
import "shapes/shapes/morph.js" as Morph

/**
 * A QML component that returns and caches the RoundedPolygons and the Morph
 * for circular progress indicators with wavy/star effect.
 *
 * This is a QML port of the Android CircularShapes class.
 */
QtObject {
    id: root

    // Public properties
    property real strokeWidth: 4
    property bool requiresMorph: false
    property real amplitude: 0  // 0 = circle, 1 = star
    property real size: 100
    property real frequency: 6

    // Public signals
    signal updated()

    // Private properties (cached state)
    property var _currentSize: null
    property real _currentFrequency: -1
    property var _trackPolygon: null
    property var _activeIndicatorPolygon: null
    property var _activeIndicatorMorph: null
    property int _currentVertexCount: -1

    // Constants
    readonly property int minCircularVertexCount: 8

    // Update the shapes based on size, frequency, and strokeWidth
    function update(newSize, newFrequency, newStrokeWidth, needsMorph) {
        if (newFrequency <= 0) {
            console.warn("Frequency should be greater than zero")
            return
        }

        // Check if update is needed
        const sizeChanged = newSize !== _currentSize
        const frequencyChanged = newFrequency !== _currentFrequency

        if (!sizeChanged && !frequencyChanged) {
            // Just check if we need to create morph
            if (needsMorph && !_activeIndicatorMorph && _trackPolygon && _activeIndicatorPolygon) {
                _activeIndicatorMorph = new Morph.Morph(_trackPolygon, _activeIndicatorPolygon)
            }
            return
        }

        // Compute number of vertices based on frequency
        // frequency: number of wave cycles around the circle
        // Each wave cycle needs 2 vertices (peak and trough)
        const numVertices = Math.max(minCircularVertexCount, Math.round(newFrequency))

        if (numVertices !== _currentVertexCount) {
            // Create track polygon (circle)
            _trackPolygon = RoundedPolygon.RoundedPolygon.circle(numVertices).normalized()

            // Create active indicator polygon (star)
            const outerRounding = new CornerRounding.CornerRounding(0.35, 0.4)
            const innerRounding = new CornerRounding.CornerRounding(0.5)
            _activeIndicatorPolygon = RoundedPolygon.RoundedPolygon.star(
                numVertices,
                1,           // radius
                0.75,        // innerRadius
                outerRounding,
                innerRounding
            ).normalized()

            // Create morph if requested
            if (needsMorph) {
                _activeIndicatorMorph = new Morph.Morph(_trackPolygon, _activeIndicatorPolygon)
            } else {
                _activeIndicatorMorph = null
            }
        } else if (needsMorph && !_activeIndicatorMorph) {
            // Just need to create morph with existing polygons
            _activeIndicatorMorph = new Morph.Morph(_trackPolygon, _activeIndicatorPolygon)
        }

        _currentSize = newSize
        _currentFrequency = newFrequency
        _currentVertexCount = numVertices

        updated()
    }

    // Get the path for the track polygon (returns cubics array)
    function getTrackCubics() {
        if (!_trackPolygon) {
            // Initialize with default values if not yet updated
            update(size, frequency, strokeWidth, requiresMorph)
        }
        return _trackPolygon ? _trackPolygon.cubics : []
    }

    // Get cubics for progress path based on amplitude
    // amplitude: 0 = circle, 1 = star
    function getProgressCubics(progressAmplitude) {
        if (!_trackPolygon) {
            update(size, frequency, strokeWidth, requiresMorph)
        }

        if (_activeIndicatorMorph) {
            // Use morph for smooth transition
            return _activeIndicatorMorph.asCubics(Math.max(0, Math.min(1, progressAmplitude)))
        } else {
            // No morph - use direct polygon selection
            if (progressAmplitude >= 1 && _activeIndicatorPolygon) {
                return _activeIndicatorPolygon.cubics
            } else {
                return _trackPolygon ? _trackPolygon.cubics : []
            }
        }
    }

    // Draw track path to canvas context
    function drawTrackPath(ctx, centerX, centerY, scale) {
        const cubics = getTrackCubics()
        if (cubics.length === 0) return

        ctx.save()
        ctx.translate(centerX, centerY)
        if (scale !== undefined && scale !== 1) {
            ctx.scale(scale, scale)
        }

        ctx.beginPath()
        ctx.moveTo(cubics[0].anchor0X, cubics[0].anchor0Y)
        for (const cubic of cubics) {
            ctx.bezierCurveTo(
                cubic.control0X, cubic.control0Y,
                cubic.control1X, cubic.control1Y,
                cubic.anchor1X, cubic.anchor1Y
            )
        }
        ctx.closePath()
        ctx.restore()
    }

    // Draw progress path to canvas context
    function drawProgressPath(ctx, centerX, centerY, scale, offset) {
        const cubics = getProgressCubics(amplitude * 6)
        if (cubics.length === 0) return

        ctx.save()
        if (scale !== undefined && scale !== 1) {
            ctx.scale(scale, scale)
        }
        // Normalize coordinates are in 0-1 range, center is at (0.5, 0.5)
        // Translate center to origin, rotate, then translate back
        ctx.translate(0.5, 0.5)
        if (offset !== undefined) {
            ctx.rotate(offset * 2 * Math.PI)
        }
        ctx.translate(-0.5, -0.5)
        ctx.beginPath()
        ctx.moveTo(cubics[0].anchor0X, cubics[0].anchor0Y)
        for (const cubic of cubics) {
            ctx.bezierCurveTo(
                cubic.control0X, cubic.control0Y,
                cubic.control1X, cubic.control1Y,
                cubic.anchor1X, cubic.anchor1Y
            )
        }
        ctx.closePath()
        ctx.restore()
    }

    // Force recreation of shapes
    function invalidate() {
        _currentSize = null
        _currentFrequency = -1
        _trackPolygon = null
        _activeIndicatorPolygon = null
        _activeIndicatorMorph = null
        _currentVertexCount = -1
    }

    // Auto-update when properties change
    onSizeChanged: update(size, frequency, strokeWidth, requiresMorph)
    onFrequencyChanged: update(size, frequency, strokeWidth, requiresMorph)
    onStrokeWidthChanged: update(size, frequency, strokeWidth, requiresMorph)
    onRequiresMorphChanged: update(size, frequency, strokeWidth, requiresMorph)

    Component.onCompleted: {
        update(size, frequency, strokeWidth, requiresMorph)
    }
}
