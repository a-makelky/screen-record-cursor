import AppKit

@MainActor
final class GlobalClickMonitor {
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private let onClick: @MainActor () -> Void

    init(onClick: @escaping @MainActor () -> Void) {
        self.onClick = onClick
    }

    @discardableResult
    func start() -> Bool {
        stop()

        let events: NSEvent.EventTypeMask = [
            .leftMouseDown,
            .rightMouseDown,
            .otherMouseDown
        ]

        globalMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: events
        ) { [weak self] _ in
            self?.onClick()
        }

        localMonitor = NSEvent.addLocalMonitorForEvents(
            matching: events
        ) { [weak self] event in
            self?.onClick()
            return event
        }

        return globalMonitor != nil
    }

    func stop() {
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
            self.globalMonitor = nil
        }

        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
        }
    }

}
