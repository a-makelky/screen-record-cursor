import AppKit

@MainActor
final class CursorOverlayController {
    struct StartResult {
        let clickMonitoringAvailable: Bool
    }

    private let overlaySize = CGSize(width: 256, height: 256)
    private let settingsProvider: @MainActor () -> CursorVisualSettings
    private let clickSoundProvider:
        @MainActor () -> (style: ClickSoundStyle, volume: Float)?

    private var panel: CursorOverlayPanel?
    private var overlayView: CursorOverlayView?
    private var frameTimer: DispatchSourceTimer?
    private var clickMonitor: GlobalClickMonitor?
    private let soundPlayer = ClickSoundPlayer()
    private var lastPosition: CGPoint?

    init(
        settingsProvider: @escaping @MainActor () -> CursorVisualSettings,
        clickSoundProvider:
            @escaping @MainActor () -> (style: ClickSoundStyle, volume: Float)?
    ) {
        self.settingsProvider = settingsProvider
        self.clickSoundProvider = clickSoundProvider
    }

    func start() -> StartResult {
        guard panel == nil else {
            return StartResult(clickMonitoringAvailable: clickMonitor != nil)
        }

        let settings = settingsProvider()
        let view = CursorOverlayView(frame: CGRect(origin: .zero, size: overlaySize))
        view.settings = settings

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
        updateFrame()
        panel.orderFrontRegardless()

        let monitor = GlobalClickMonitor { [weak self] in
            self?.handleClick()
        }
        clickMonitor = monitor
        let clickMonitoringAvailable = monitor.start()

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
        return StartResult(
            clickMonitoringAvailable: clickMonitoringAvailable
        )
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
    }

    func refreshSettings() {
        overlayView?.settings = settingsProvider()
    }

    private func updateFrame() {
        guard let panel, let overlayView else { return }

        let position = NSEvent.mouseLocation
        let timestamp = ProcessInfo.processInfo.systemUptime
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
}

final class CursorOverlayPanel: NSPanel {
    /// Keep the public-API overlay visible above ordinary app and system UI
    /// windows. The native cursor remains active underneath.
    static let aboveSystemCursorLevel = NSWindow.Level(
        rawValue: Int(CGWindowLevelForKey(.cursorWindow)) + 1
    )

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
