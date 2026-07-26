import CoreGraphics
import Darwin
import Foundation

/// Owns the single balanced WindowServer hide request used by Recording mode.
///
/// Quartz only honors cursor visibility changes from the foreground application
/// by default. Because this is an LSUIElement menu-bar app, it opts its existing
/// WindowServer connection into background cursor control before hiding the
/// native pointer. The private symbols are resolved dynamically so a future
/// macOS release can fail safely instead of preventing the app from launching.
@MainActor
final class NativeCursorVisibilityController {
    private typealias MainConnectionIDFunction = @convention(c) () -> Int32
    private typealias SetConnectionPropertyFunction =
        @convention(c) (Int32, Int32, CFString, CFTypeRef) -> Int32
    private typealias CursorIsVisibleFunction = @convention(c) () -> Int32

    private var wantsCursorHidden = false
    private var hideRequestOutstanding = false
    private var backgroundControlResult: Bool?
    private var cursorIsVisibleFunction: CursorIsVisibleFunction?
    private var didResolveCursorIsVisible = false
    private var watchdog: DispatchSourceTimer?

    func hideForRecording() {
        guard !wantsCursorHidden else { return }
        wantsCursorHidden = true

        guard enableBackgroundCursorControl() else {
            NSLog(
                "Screen Record Cursor could not enable background cursor control; "
                    + "the native cursor will remain visible."
            )
            return
        }

        replaceHideRequest()
        startWatchdog()
    }

    func showAfterRecording() {
        wantsCursorHidden = false
        stopWatchdog()
        releaseHideRequest()
    }

    /// WindowServer or Dock activity can occasionally make the native cursor
    /// visible again. Replacing our one outstanding request restores invisibility
    /// without increasing Quartz's balanced hide count.
    private func replaceHideRequest() {
        if hideRequestOutstanding {
            _ = CGDisplayShowCursor(CGMainDisplayID())
            hideRequestOutstanding = false
        }

        let result = CGDisplayHideCursor(CGMainDisplayID())
        hideRequestOutstanding = result == .success
    }

    private func releaseHideRequest() {
        guard hideRequestOutstanding else { return }
        _ = CGDisplayShowCursor(CGMainDisplayID())
        hideRequestOutstanding = false
    }

    private func startWatchdog() {
        guard watchdog == nil else { return }

        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(
            deadline: .now() + .milliseconds(100),
            repeating: .milliseconds(100),
            leeway: .milliseconds(20)
        )
        timer.setEventHandler { [weak self] in
            guard
                let self,
                self.wantsCursorHidden,
                self.isNativeCursorVisible() == true
            else {
                return
            }

            self.replaceHideRequest()
        }
        watchdog = timer
        timer.resume()
    }

    private func isNativeCursorVisible() -> Bool? {
        if !didResolveCursorIsVisible {
            didResolveCursorIsVisible = true
            if
                let handle = dlopen(nil, RTLD_LAZY),
                let symbol = dlsym(handle, "CGCursorIsVisible")
            {
                cursorIsVisibleFunction = unsafeBitCast(
                    symbol,
                    to: CursorIsVisibleFunction.self
                )
            }
        }

        guard let cursorIsVisibleFunction else { return nil }
        return cursorIsVisibleFunction() != 0
    }

    private func stopWatchdog() {
        watchdog?.cancel()
        watchdog = nil
    }

    private func enableBackgroundCursorControl() -> Bool {
        if let backgroundControlResult {
            return backgroundControlResult
        }

        let result = Self.setBackgroundCursorControl()
        backgroundControlResult = result
        return result
    }

    private static func setBackgroundCursorControl() -> Bool {
        guard let handle = dlopen(nil, RTLD_LAZY) else { return false }

        let connectionSymbols = [
            "CGSMainConnectionID",
            "_CGSDefaultConnection",
            "SLSMainConnectionID"
        ]
        let propertySymbols = [
            "CGSSetConnectionProperty",
            "SLSSetConnectionProperty"
        ]

        guard
            let connectionSymbol = connectionSymbols.lazy
                .compactMap({ dlsym(handle, $0) })
                .first,
            let propertySymbol = propertySymbols.lazy
                .compactMap({ dlsym(handle, $0) })
                .first
        else {
            return false
        }

        let mainConnectionID = unsafeBitCast(
            connectionSymbol,
            to: MainConnectionIDFunction.self
        )
        let setConnectionProperty = unsafeBitCast(
            propertySymbol,
            to: SetConnectionPropertyFunction.self
        )

        let connectionID = mainConnectionID()
        let result = setConnectionProperty(
            connectionID,
            connectionID,
            "SetsCursorInBackground" as CFString,
            kCFBooleanTrue
        )
        return result == 0
    }
}
