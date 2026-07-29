import AppKit
import CursorCore

@MainActor
final class CursorOverlayView: NSView {
    private struct Ripple {
        let startedAt: TimeInterval
    }

    var settings = CursorVisualSettings(
        ringColor: .systemRed,
        cursorColor: .black,
        ringVisibility: .onClick,
        ringDiameter: 44,
        ringThickness: 4,
        cursorScale: 1.5,
        clickEffect: .ripple,
        kineticEnabled: false,
        kineticResponse: .smooth
    ) {
        didSet {
            let shouldClearClickAnimation = (
                !settings.ringVisibility.allowsClickFeedback
                    || settings.clickEffect == .off
            )
            if shouldClearClickAnimation {
                ripples.removeAll()
                pulseStartedAt = nil
            }
            needsDisplay = true
        }
    }

    var rotationRadians: Double = 0 {
        didSet { needsDisplay = true }
    }

    private var ripples: [Ripple] = []
    private var pulseStartedAt: TimeInterval?
    private var currentTime = ProcessInfo.processInfo.systemUptime

    override var isOpaque: Bool { false }

    func registerClick(at timestamp: TimeInterval) {
        guard settings.ringVisibility.allowsClickFeedback else { return }

        switch settings.clickEffect {
        case .ripple:
            ripples.append(Ripple(startedAt: timestamp))
        case .pulse:
            pulseStartedAt = timestamp
        case .both:
            ripples.append(Ripple(startedAt: timestamp))
            pulseStartedAt = timestamp
        case .off:
            break
        }
        needsDisplay = true
    }

    func advance(to timestamp: TimeInterval) {
        let hadActiveEffects = !ripples.isEmpty || pulseStartedAt != nil
        currentTime = timestamp
        ripples.removeAll { timestamp - $0.startedAt > 0.42 }

        if let pulseStartedAt, timestamp - pulseStartedAt > 0.22 {
            self.pulseStartedAt = nil
        }

        if hadActiveEffects {
            needsDisplay = true
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let hotspot = CGPoint(x: bounds.midX, y: bounds.midY)
        if settings.ringVisibility.allowsClickFeedback {
            drawRipples(around: hotspot)
        }
        if settings.ringVisibility.showsBaseRing(
            isClickAnimationActive: pulseStartedAt != nil
        ) {
            drawPersistentRing(
                around: hotspot,
                clickOnly: !settings.ringVisibility.showsPersistentRing
            )
        }
        drawCursor(at: hotspot)
    }

    private func drawPersistentRing(
        around point: CGPoint,
        clickOnly: Bool = false
    ) {
        var opacity: CGFloat = 0.94
        var thickness = settings.ringThickness
        var diameter = settings.ringDiameter

        if let started = pulseStartedAt {
            let progress = min(1, max(0, (currentTime - started) / 0.2))
            let wave = CGFloat(sin(progress * .pi))
            opacity = 0.94 - wave * 0.34
            thickness += wave * 5
            diameter += wave * 8

            if clickOnly {
                opacity *= CGFloat(1 - progress)
            }
        }

        let rect = CGRect(
            x: point.x - diameter / 2,
            y: point.y - diameter / 2,
            width: diameter,
            height: diameter
        )
        let path = NSBezierPath(ovalIn: rect)
        path.lineWidth = thickness
        settings.ringColor.withAlphaComponent(opacity).setStroke()
        path.stroke()
    }

    private func drawRipples(around point: CGPoint) {
        for ripple in ripples {
            let progress = min(1, max(0, (currentTime - ripple.startedAt) / 0.38))
            let eased = 1 - pow(1 - progress, 3)
            let diameter = settings.ringDiameter * (1 + CGFloat(eased) * 1.25)
            let opacity = CGFloat(pow(1 - progress, 1.6)) * 0.8
            let rect = CGRect(
                x: point.x - diameter / 2,
                y: point.y - diameter / 2,
                width: diameter,
                height: diameter
            )
            let path = NSBezierPath(ovalIn: rect)
            path.lineWidth = max(2, settings.ringThickness * (1 - CGFloat(progress) * 0.45))
            settings.ringColor.withAlphaComponent(opacity).setStroke()
            path.stroke()
        }
    }

    private func drawCursor(at hotspot: CGPoint) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }

        context.saveGState()
        context.translateBy(x: hotspot.x, y: hotspot.y)
        context.rotate(by: CGFloat(rotationRadians))
        context.scaleBy(x: settings.cursorScale, y: settings.cursorScale)

        let path = NSBezierPath()
        path.move(to: CGPoint(x: 0, y: 0))
        path.line(to: CGPoint(x: 0, y: -25))
        path.line(to: CGPoint(x: 6.5, y: -19))
        path.line(to: CGPoint(x: 11.5, y: -31))
        path.line(to: CGPoint(x: 17.2, y: -28.5))
        path.line(to: CGPoint(x: 12.2, y: -16.5))
        path.line(to: CGPoint(x: 21, y: -16.5))
        path.close()

        // First paint a wider opaque silhouette. The overlay lives above the
        // system cursor, and this antialiased coverage pass prevents native
        // cursor pixels from leaking through around the arrowhead.
        let outlineColor = settings.cursorColor.contrastingStrokeColor
        outlineColor.setStroke()
        path.lineJoinStyle = .round
        path.lineWidth = 4.8 / settings.cursorScale
        path.stroke()

        settings.cursorColor.setFill()
        path.fill()

        outlineColor.withAlphaComponent(0.98).setStroke()
        path.lineWidth = 1.8 / settings.cursorScale
        path.stroke()

        context.restoreGState()
    }
}
