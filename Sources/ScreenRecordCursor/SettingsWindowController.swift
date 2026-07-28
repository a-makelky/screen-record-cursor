import AppKit
import Combine
import SwiftUI

enum SettingsSection: String, CaseIterable, Identifiable {
    case cursor
    case clicks
    case general

    var id: String { rawValue }

    var label: String {
        switch self {
        case .cursor: "Cursor"
        case .clicks: "Clicks"
        case .general: "General"
        }
    }

    var systemImage: String {
        switch self {
        case .cursor: "cursorarrow"
        case .clicks: "cursorarrow.click"
        case .general: "gearshape"
        }
    }
}

@MainActor
final class SettingsNavigationModel: ObservableObject {
    @Published var selection = SettingsSection.cursor
}

@MainActor
final class SettingsWindowController: NSObject, NSWindowDelegate {
    static let shared = SettingsWindowController()

    let navigation = SettingsNavigationModel()
    private var windowController: NSWindowController?

    func show(section: SettingsSection) {
        navigation.selection = section

        if windowController == nil {
            windowController = makeWindowController()
        }

        guard let window = windowController?.window else { return }
        NSApp.activate(ignoringOtherApps: true)
        windowController?.showWindow(nil)
        window.makeKeyAndOrderFront(nil)
    }

    private func makeWindowController() -> NSWindowController {
        let rootView = SettingsWindowView()
            .environmentObject(AppState.shared)
            .environmentObject(navigation)
        let hostingController = NSHostingController(rootView: rootView)
        let window = NSWindow(contentViewController: hostingController)

        window.title = "Screen Recording Cursor"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.setContentSize(NSSize(width: 824, height: 488))
        window.minSize = NSSize(width: 720, height: 470)
        window.isReleasedWhenClosed = false
        window.center()
        window.delegate = self

        return NSWindowController(window: window)
    }
}
