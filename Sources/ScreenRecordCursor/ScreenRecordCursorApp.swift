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
            Label(
                "Screen Record Cursor",
                systemImage: state.isActive ? "cursorarrow.rays" : "cursorarrow"
            )
        }
        .menuBarExtraStyle(.window)
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }

    func applicationWillTerminate(_ notification: Notification) {
        AppState.shared.stopForTermination()
    }
}
