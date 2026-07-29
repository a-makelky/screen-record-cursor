import AppKit
import CursorCore

@MainActor
final class CursorOverlayController {
    private let overlaySize = CGSize(width: 256, height: 256)
    private let settingsProvider: @MainActor () -> CursorVisualSettings
    private let clickSoundProvider:
        @MainActor () -> (style: ClickSoundStyle, volume: Float)?

    private var panel: CursorOverlayPanel?
    private var overlayView: CursorOverlayView?
    private var frameTimer: DispatchSourceTimer?
    private var clickMonitor: GlobalClickMonitor?
    private var kineticResponse = KineticResponse.smooth
    private var kineticModel = KineticCursorModel(
        configuration: KineticResponse.smooth.configuration
    )
    private let soundPlayer = ClickSoundPlayer()
    private let nativeCursorVisibility = NativeCursorVisibilityController()
    private var lastPosition: CGPoint?

    init(
        settingsProvider: @escaping @MainActor () -> CursorVisualSettings,
        clickSoundProvider:
            @escaping @MainActor () -> (style: ClickSoundStyle, volume: Float)?
    ) {
        self.settingsProvider = settingsProvider
        self.clickSoundProvider = clickSoundProvider
    }

    @discardableResult
    func start() -> Bool {
        guard panel == nil else { return true }

        let settings = settingsProvider()
        let view = CursorOverlayView(frame: CGRect(origin: .zero, size: overlaySize))
        view.settings = settings
        applyKineticResponse(settings.kineticResponse)

        let panel = CursorOverlayPanel(
            contentRect: CGRect(origin: .zero, size: overlaySize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.contentView = view
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.ignoresMouseEvents = true
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.level = CursorOverlayPanel.aboveSystemCursorLevel
        panel.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .stationary,
            .ignoresCycle
        ]
        panel.sharingType = .readWrite

        self.panel = panel
        overlayView = view
        kineticModel.reset()
        updateFrame()
        panel.orderFrontRegardless()

        guard nativeCursorVisibility.hideForRecording() else {
            stop()
            return false
        }

        let monitor = GlobalClickMonitor { [weak self] in
            self?.handleClick()
        }
        clickMonitor = monitor
        monitor.start()

        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(
            deadline: .now(),
            repeating: .milliseconds(16),
            leeway: .milliseconds(2)
        )
        timer.setEventHandler { [weak self] in
            self?.updateFrame()
        }
        frameTimer = timer
        timer.resume()
        return true
    }

    func stop() {
        frameTimer?.cancel()
        frameTimer = nil

        clickMonitor?.stop()
        clickMonitor = nil

        panel?.orderOut(nil)
        panel?.close()
        panel = nil
        overlayView = nil
        lastPosition = nil
        kineticModel.reset()
        nativeCursorVisibility.showAfterRecording()
    }

    func refreshSettings() {
        let settings = settingsProvider()
        applyKineticResponse(settings.kineticResponse)
        overlayView?.settings = settings
    }

    private func updateFrame() {
        guard let panel, let overlayView else { return }

        let position = NSEvent.mouseLocation
        let timestamp = ProcessInfo.processInfo.systemUptime
        let settings = settingsProvider()
        let motion = kineticModel.update(
            position: position,
            timestamp: timestamp,
            enabled: settings.kineticEnabled
        )

        if abs(overlayView.rotationRadians - motion.rotationRadians) > 0.0001 {
            overlayView.rotationRadians = motion.rotationRadians
        }
        overlayView.advance(to: timestamp)

        if lastPosition != position {
            panel.setFrameOrigin(
                CGPoint(
                    x: position.x - overlaySize.width / 2,
                    y: position.y - overlaySize.height / 2
                )
            )
            lastPosition = position
        }
    }

    private func handleClick() {
        let timestamp = ProcessInfo.processInfo.systemUptime
        overlayView?.registerClick(at: timestamp)

        if let sound = clickSoundProvider() {
            soundPlayer.play(style: sound.style, volume: sound.volume)
        }
    }

    private func applyKineticResponse(_ response: KineticResponse) {
        guard response != kineticResponse else { return }

        kineticResponse = response
        kineticModel = KineticCursorModel(configuration: response.configuration)
    }
}

final class CursorOverlayPanel: NSPanel {
    /// Keep the replacement visible above ordinary app and system UI windows.
    /// Recording mode separately hides the hardware-composited native cursor.
    static let aboveSystemCursorLevel = NSWindow.Level(
        rawValue: Int(CGWindowLevelForKey(.cursorWindow)) + 1
    )

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
