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
        clickEffect: .ripple
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

}
