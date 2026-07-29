import AppKit

/// Uses AppKit's public cursor-image API so the Store edition displays one
/// pointer instead of stacking a window-drawn arrow below macOS's pointer.
///
/// Foreground apps may replace the current cursor as the pointer crosses text,
/// links, and resize handles. The frame loop asks this controller to restore the
/// selected cursor only when AppKit reports that another cursor replaced it.
@MainActor
final class StoreCursorController {
    private let artwork = StoreCursorArtwork()
    private var customCursor: NSCursor?
    private var cursorToRestore: NSCursor?
    private var isRunning = false

    func start(settings: CursorVisualSettings) {
        guard !isRunning else {
            update(settings: settings)
            return
        }

        isRunning = true
        customCursor = artwork.makeCursor(
            color: settings.cursorColor,
            scale: settings.cursorScale
        )
        reassertIfNeeded()
    }

    func update(settings: CursorVisualSettings) {
        guard isRunning else { return }

        let previousCustomCursor = customCursor
        let currentCursor = NSCursor.current
        if currentCursor !== previousCustomCursor {
            cursorToRestore = currentCursor
        }

        customCursor = artwork.makeCursor(
            color: settings.cursorColor,
            scale: settings.cursorScale
        )
        customCursor?.set()
    }

    func reassertIfNeeded() {
        guard isRunning, let customCursor else { return }

        let currentCursor = NSCursor.current
        guard currentCursor !== customCursor else { return }

        cursorToRestore = currentCursor
        customCursor.set()
    }

    func stop() {
        guard isRunning else { return }

        isRunning = false
        let restoreCursor = cursorToRestore ?? .arrow
        customCursor = nil
        cursorToRestore = nil
        restoreCursor.set()
    }
}

private struct StoreCursorArtwork {
    private let baseWidth: CGFloat = 21
    private let baseHeight: CGFloat = 31
    private let padding: CGFloat = 4

    func makeCursor(color: NSColor, scale: CGFloat) -> NSCursor {
        let clampedScale = min(3, max(1.1, scale))
        let imageSize = NSSize(
            width: ceil(baseWidth * clampedScale + padding * 2),
            height: ceil(baseHeight * clampedScale + padding * 2)
        )

        let image = NSImage(
            size: imageSize,
            flipped: true
        ) { _ in
            guard let context = NSGraphicsContext.current?.cgContext else {
                return false
            }

            context.saveGState()
            context.translateBy(x: padding, y: padding)
            context.scaleBy(x: clampedScale, y: clampedScale)

            let path = NSBezierPath()
            path.move(to: CGPoint(x: 0, y: 0))
            path.line(to: CGPoint(x: 0, y: 25))
            path.line(to: CGPoint(x: 6.5, y: 19))
            path.line(to: CGPoint(x: 11.5, y: 31))
            path.line(to: CGPoint(x: 17.2, y: 28.5))
            path.line(to: CGPoint(x: 12.2, y: 16.5))
            path.line(to: CGPoint(x: 21, y: 16.5))
            path.close()

            let outlineColor = color.contrastingStrokeColor
            path.lineJoinStyle = .round
            path.lineWidth = 4.8 / clampedScale
            outlineColor.setStroke()
            path.stroke()

            color.setFill()
            path.fill()

            path.lineWidth = 1.8 / clampedScale
            outlineColor.withAlphaComponent(0.98).setStroke()
            path.stroke()

            context.restoreGState()
            return true
        }
        image.isTemplate = false

        return NSCursor(
            image: image,
            hotSpot: NSPoint(x: padding, y: padding)
        )
    }
}
