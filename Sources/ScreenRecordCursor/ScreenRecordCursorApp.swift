import AppKit
import SwiftUI

@main
@MainActor
struct ScreenRecordCursorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var state = AppState.shared

    var body: some Scene {
        MenuBarExtra {
            SettingsView()
                .environmentObject(state)
        } label: {
            MenuBarStatusLabel(isActive: state.isActive)
        }
        .menuBarExtraStyle(.window)
    }
}

private struct MenuBarStatusLabel: View {
    let isActive: Bool

    var body: some View {
        ZStack {
            if isActive {
                Circle()
                    .fill(BrandPalette.brightBlue)
                    .frame(width: 19, height: 19)
                    .accessibilityHidden(true)
            }

            Image(systemName: isActive ? "cursorarrow.rays" : "cursorarrow")
                .font(.system(size: isActive ? 10 : 13, weight: .semibold))
                .foregroundStyle(isActive ? Color.white : Color.primary)
                .accessibilityHidden(true)
        }
        .frame(width: 22, height: 22)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Screen Recording Cursor")
        .accessibilityValue(
            isActive ? "Enhanced cursor on" : "Enhanced cursor off"
        )
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        observeCursorSafetyEvents()
    }

    func applicationWillTerminate(_ notification: Notification) {
        AppState.shared.stopForTermination()
    }

    private func observeCursorSafetyEvents() {
        let workspaceCenter = NSWorkspace.shared.notificationCenter
        workspaceCenter.addObserver(
            self,
            selector: #selector(stopForSystemTransition(_:)),
            name: NSWorkspace.willSleepNotification,
            object: nil
        )
        workspaceCenter.addObserver(
            self,
            selector: #selector(stopForSystemTransition(_:)),
            name: NSWorkspace.screensDidSleepNotification,
            object: nil
        )
        workspaceCenter.addObserver(
            self,
            selector: #selector(stopForSystemTransition(_:)),
            name: NSWorkspace.sessionDidResignActiveNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(stopForDisplayChange(_:)),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    @objc
    private func stopForSystemTransition(_ notification: Notification) {
        AppState.shared.stopForSystemTransition()
    }

    @objc
    private func stopForDisplayChange(_ notification: Notification) {
        AppState.shared.stopForDisplayChange()
    }
}
