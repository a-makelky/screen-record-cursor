import AppKit
import Combine
import Foundation

@MainActor
final class AppState: ObservableObject {
    static let shared = AppState()

    static let defaultColors = [
        "#FF3B30", // red
        "#FF9500", // orange
        "#FFCC00", // yellow
        "#34C759", // green
        "#00C7BE", // teal
        "#007AFF", // blue
        "#5856D6", // indigo
        "#AF52DE", // purple
        "#FF2D55", // pink
        "#FFFFFF"  // white
    ]

    @Published private(set) var isActive = false
    @Published private(set) var statusMessage: String?
    @Published private(set) var hasCompletedOnboarding: Bool
    @Published private(set) var launchAtLoginEnabled = false
    @Published private(set) var launchAtLoginMessage: String?

    @Published var colorHex: String {
        didSet {
            save(colorHex, for: Keys.colorHex)
            overlayController.refreshSettings()
        }
    }

    @Published var ringDiameter: Double {
        didSet {
            save(ringDiameter, for: Keys.ringDiameter)
            overlayController.refreshSettings()
        }
    }

    @Published var ringThickness: Double {
        didSet {
            save(ringThickness, for: Keys.ringThickness)
            overlayController.refreshSettings()
        }
    }

    @Published var cursorScale: Double {
        didSet {
            save(cursorScale, for: Keys.cursorScale)
            overlayController.refreshSettings()
        }
    }

    @Published var clickEffect: ClickEffect {
        didSet {
            save(clickEffect.rawValue, for: Keys.clickEffect)
            overlayController.refreshSettings()
        }
    }

    @Published var soundEnabled: Bool {
        didSet {
            save(soundEnabled, for: Keys.soundEnabled)
        }
    }

    @Published var soundVolume: Double {
        didSet {
            save(soundVolume, for: Keys.soundVolume)
        }
    }

    @Published var kineticEnabled: Bool {
        didSet {
            save(kineticEnabled, for: Keys.kineticEnabled)
            overlayController.refreshSettings()
        }
    }

    private let defaults = UserDefaults.standard
    private let launchAtLoginController = LaunchAtLoginController()
    private var overlayController: CursorOverlayController!

    private enum Keys {
        static let colorHex = "colorHex"
        static let ringDiameter = "ringDiameter"
        static let ringThickness = "ringThickness"
        static let cursorScale = "cursorScale"
        static let clickEffect = "clickEffect"
        static let soundEnabled = "soundEnabled"
        static let soundVolume = "soundVolume"
        static let kineticEnabled = "kineticEnabled"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
    }

    private init() {
        defaults.register(defaults: [
            Keys.colorHex: "#FF3B30",
            Keys.ringDiameter: 44.0,
            Keys.ringThickness: 4.0,
            Keys.cursorScale: 1.65,
            Keys.clickEffect: ClickEffect.ripple.rawValue,
            Keys.soundEnabled: true,
            Keys.soundVolume: 0.28,
            Keys.kineticEnabled: false
        ])

        colorHex = defaults.string(forKey: Keys.colorHex) ?? "#FF3B30"
        ringDiameter = defaults.double(forKey: Keys.ringDiameter)
        ringThickness = defaults.double(forKey: Keys.ringThickness)
        cursorScale = defaults.double(forKey: Keys.cursorScale)
        clickEffect = ClickEffect(
            rawValue: defaults.string(forKey: Keys.clickEffect) ?? ""
        ) ?? .ripple
        soundEnabled = defaults.bool(forKey: Keys.soundEnabled)
        soundVolume = defaults.double(forKey: Keys.soundVolume)
        kineticEnabled = defaults.bool(forKey: Keys.kineticEnabled)
        hasCompletedOnboarding = defaults.bool(
            forKey: Keys.hasCompletedOnboarding
        )

        overlayController = CursorOverlayController(
            settingsProvider: { [weak self] in
                self?.visualSettings ?? CursorVisualSettings(
                    ringColor: .systemRed,
                    ringDiameter: 44,
                    ringThickness: 4,
                    cursorScale: 1.65,
                    clickEffect: .ripple,
                    kineticEnabled: false
                )
            },
            clickSoundProvider: { [weak self] in
                guard let self, self.soundEnabled else { return nil }
                return Float(self.soundVolume)
            }
        )

        refreshLaunchAtLoginStatus()
    }

    var visualSettings: CursorVisualSettings {
        CursorVisualSettings(
            ringColor: NSColor(hex: colorHex) ?? .systemRed,
            ringDiameter: ringDiameter,
            ringThickness: ringThickness,
            cursorScale: cursorScale,
            clickEffect: clickEffect,
            kineticEnabled: kineticEnabled
        )
    }

    func setRecordingMode(_ enabled: Bool) {
        guard enabled != isActive else { return }

        if enabled {
            statusMessage = nil
            guard overlayController.start() else {
                statusMessage = """
                Recording mode could not hide the native macOS cursor. \
                Your normal cursor was restored.
                """
                return
            }
            isActive = true
        } else {
            overlayController.stop()
            isActive = false
        }
    }

    func toggleRecordingMode() {
        setRecordingMode(!isActive)
    }

    func completeOnboarding(startTest: Bool) {
        hasCompletedOnboarding = true
        save(true, for: Keys.hasCompletedOnboarding)

        if startTest {
            setRecordingMode(true)
        }
    }

    func dismissStatusMessage() {
        statusMessage = nil
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        launchAtLoginMessage = nil

        do {
            try launchAtLoginController.setEnabled(enabled)
        } catch {
            launchAtLoginMessage = """
            macOS could not update Launch at Login. Move the app to Applications \
            and try again.
            """
        }

        refreshLaunchAtLoginStatus()
    }

    func refreshLaunchAtLoginStatus() {
        switch launchAtLoginController.state {
        case .enabled:
            launchAtLoginEnabled = true
            launchAtLoginMessage = nil
        case .disabled:
            launchAtLoginEnabled = false
        case .requiresApproval:
            launchAtLoginEnabled = false
            launchAtLoginMessage = """
            Approve Screen Record Cursor in System Settings → General → Login Items.
            """
        case .unavailable:
            launchAtLoginEnabled = false
            launchAtLoginMessage = """
            Launch at Login is available after the app is installed in Applications.
            """
        }
    }

    func resetSettings() {
        colorHex = "#FF3B30"
        ringDiameter = 44
        ringThickness = 4
        cursorScale = 1.65
        clickEffect = .ripple
        soundEnabled = true
        soundVolume = 0.28
        kineticEnabled = false
        statusMessage = "Appearance, motion, and click settings were reset."
    }

    func stopForSystemTransition() {
        stopForSafety(
            message: "Recording mode was turned off to restore your cursor before sleep or user switching."
        )
    }

    func stopForDisplayChange() {
        stopForSafety(
            message: "Recording mode was turned off after the display configuration changed."
        )
    }

    func stopForTermination() {
        overlayController.stop()
        isActive = false
    }

    private func stopForSafety(message: String) {
        guard isActive else {
            overlayController.stop()
            return
        }

        overlayController.stop()
        isActive = false
        statusMessage = message
    }

    private func save(_ value: Any, for key: String) {
        defaults.set(value, forKey: key)
    }
}
