import AppKit
import SwiftUI

struct ShortcutRecorderView: NSViewRepresentable {
    let shortcut: HotKeyShortcut
    let onCapture: (HotKeyShortcut) -> Void
    let onClear: () -> Void
    let onMessage: (String?) -> Void

    func makeNSView(context: Context) -> ShortcutRecorderControl {
        let view = ShortcutRecorderControl()
        configure(view)
        return view
    }

    func updateNSView(_ view: ShortcutRecorderControl, context: Context) {
        configure(view)
    }

    private func configure(_ view: ShortcutRecorderControl) {
        view.shortcut = shortcut
        view.onCapture = onCapture
        view.onClear = onClear
        view.onMessage = onMessage
    }
}

final class ShortcutRecorderControl: NSView {
    var shortcut = HotKeyShortcut.defaultShortcut {
        didSet { needsDisplay = true }
    }
    var onCapture: ((HotKeyShortcut) -> Void)?
    var onClear: (() -> Void)?
    var onMessage: ((String?) -> Void)?

    private var isRecording = false {
        didSet { needsDisplay = true }
    }

    override var acceptsFirstResponder: Bool { true }
    override var intrinsicContentSize: NSSize {
        NSSize(width: 150, height: 28)
    }

    override func mouseDown(with event: NSEvent) {
        isRecording = true
        onMessage?(nil)
        window?.makeFirstResponder(self)
    }

    override func keyDown(with event: NSEvent) {
        let hasModifier = !event.modifierFlags.intersection(
            [.command, .control, .option, .shift]
        ).isEmpty

        if event.keyCode == UInt16(kVK_Escape) && !hasModifier {
            finishRecording()
            return
        }

        if event.keyCode == UInt16(kVK_Delete) && !hasModifier {
            onClear?()
            finishRecording()
            return
        }

        do {
            let captured = try HotKeyShortcut.capture(from: event)
            onCapture?(captured)
            onMessage?(nil)
            finishRecording()
        } catch {
            onMessage?(
                (error as? LocalizedError)?.errorDescription
                    ?? "That shortcut cannot be used."
            )
            NSSound.beep()
        }
    }

    override func resignFirstResponder() -> Bool {
        isRecording = false
        return super.resignFirstResponder()
    }

    override func draw(_ dirtyRect: NSRect) {
        let rect = bounds.insetBy(dx: 0.5, dy: 0.5)
        let path = NSBezierPath(roundedRect: rect, xRadius: 6, yRadius: 6)

        (isRecording
            ? NSColor.controlAccentColor.withAlphaComponent(0.14)
            : NSColor.controlBackgroundColor
        ).setFill()
        path.fill()

        (isRecording
            ? NSColor.controlAccentColor
            : NSColor.separatorColor
        ).setStroke()
        path.lineWidth = isRecording ? 1.5 : 1
        path.stroke()

        let text = isRecording ? "Type shortcut…" : shortcut.displayLabel
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 13, weight: .medium),
            .foregroundColor: NSColor.labelColor
        ]
        let size = text.size(withAttributes: attributes)
        let origin = NSPoint(
            x: bounds.midX - size.width / 2,
            y: bounds.midY - size.height / 2
        )
        text.draw(at: origin, withAttributes: attributes)
    }

    private func finishRecording() {
        isRecording = false
        window?.makeFirstResponder(nil)
    }
}
