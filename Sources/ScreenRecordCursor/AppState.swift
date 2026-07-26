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
    @Published private(set) var hotKeyEnabled: Bool
    @Published private(set) var hotKeyShortcut: HotKeyShortcut
    @Published private(set) var hotKeyMessage: String?

    @Published var colorHex: String {
        didSet {
            save(colorHex, for: Keys.colorHex)
            overlayController.refreshSettings()
        }
    }

    @Published var cursorColorHex: String {
        didSet {
            save(cursorColorHex, for: Keys.cursorColorHex)
            overlayController.refreshSettings()
        }
    }

    @Published var ringEnabled: Bool {
        didSet {
            save(ringEnabled, for: Keys.ringEnabled)
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

    @Published var soundStyle: ClickSoundStyle {
        didSet {
            save(soundStyle.rawValue, for: Keys.soundStyle)
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
    private lazy var globalHotKeyController = GlobalHotKeyController {
        [weak self] in
        self?.toggleRecordingMode()
    }
    private var overlayController: CursorOverlayController!

    private enum Keys {
        static let colorHex = "colorHex"
        static let cursorColorHex = "cursorColorHex"
        static let ringEnabled = "ringEnabled"
        static let ringDiameter = "ringDiameter"
        static let ringThickness = "ringThickness"
        static let cursorScale = "cursorScale"
        static let clickEffect = "clickEffect"
        static let soundEnabled = "soundEnabled"
        static let soundVolume = "soundVolume"
        static let soundStyle = "soundStyle"
        static let kineticEnabled = "kineticEnabled"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let hotKeyEnabled = "hotKeyEnabled"
        static let hotKeyModifier = "hotKeyModifier"
        static let hotKeyKeyCode = "hotKeyKeyCode"
        static let hotKeyKeyLabel = "hotKeyKeyLabel"
    }

    private init() {
        defaults.register(defaults: [
            Keys.colorHex: "#FF3B30",
            Keys.cursorColorHex: "#000000",
            Keys.ringEnabled: true,
            Keys.ringDiameter: 44.0,
            Keys.ringThickness: 4.0,
            Keys.cursorScale: 1.65,
            Keys.clickEffect: ClickEffect.ripple.rawValue,
            Keys.soundEnabled: true,
            Keys.soundVolume: 0.28,
            Keys.soundStyle: ClickSoundStyle.systemTick.rawValue,
            Keys.kineticEnabled: false,
            Keys.hotKeyEnabled: true,
            Keys.hotKeyModifier: HotKeyModifier.control.rawValue,
            Keys.hotKeyKeyCode: Int(HotKeyShortcut.defaultShortcut.keyCode),
            Keys.hotKeyKeyLabel: HotKeyShortcut.defaultShortcut.keyLabel
        ])

        colorHex = defaults.string(forKey: Keys.colorHex) ?? "#FF3B30"
        cursorColorHex = defaults.string(
            forKey: Keys.cursorColorHex
        ) ?? "#000000"
        ringEnabled = defaults.bool(forKey: Keys.ringEnabled)
        ringDiameter = defaults.double(forKey: Keys.ringDiameter)
        ringThickness = defaults.double(forKey: Keys.ringThickness)
        cursorScale = defaults.double(forKey: Keys.cursorScale)
        clickEffect = ClickEffect(
            rawValue: defaults.string(forKey: Keys.clickEffect) ?? ""
        ) ?? .ripple
        soundEnabled = defaults.bool(forKey: Keys.soundEnabled)
        soundVolume = defaults.double(forKey: Keys.soundVolume)
        soundStyle = ClickSoundStyle(
            rawValue: defaults.string(forKey: Keys.soundStyle) ?? ""
        ) ?? .systemTick
        kineticEnabled = defaults.bool(forKey: Keys.kineticEnabled)
        hasCompletedOnboarding = defaults.bool(
            forKey: Keys.hasCompletedOnboarding
        )
        hotKeyEnabled = defaults.bool(forKey: Keys.hotKeyEnabled)
        hotKeyShortcut = HotKeyShortcut(
            keyCode: UInt32(defaults.integer(forKey: Keys.hotKeyKeyCode)),
            modifier: defaults.string(forKey: Keys.hotKeyModifier)
                .flatMap(HotKeyModifier.init(rawValue:)),
            keyLabel: defaults.string(forKey: Keys.hotKeyKeyLabel) ?? ";"
        )

        overlayController = CursorOverlayController(
            settingsProvider: { [weak self] in
                self?.visualSettings ?? CursorVisualSettings(
                    ringColor: .systemRed,
                    cursorColor: .black,
                    ringEnabled: true,
                    ringDiameter: 44,
                    ringThickness: 4,
                    cursorScale: 1.65,
                    clickEffect: .ripple,
                    kineticEnabled: false
                )
            },
            clickSoundProvider: { [weak self] in
                guard let self, self.soundEnabled else { return nil }
                return (
                    style: self.soundStyle,
                    volume: Float(self.soundVolume)
                )
            }
        )

        refreshLaunchAtLoginStatus()
        configureGlobalHotKey()
    }

    var visualSettings: CursorVisualSettings {
        CursorVisualSettings(
            ringColor: NSColor(hex: colorHex) ?? .systemRed,
            cursorColor: NSColor(hex: cursorColorHex) ?? .black,
            ringEnabled: ringEnabled,
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

    var hotKeyLabel: String {
        hotKeyShortcut.displayLabel
    }

    func setHotKeyEnabled(_ enabled: Bool) {
        hotKeyMessage = nil

        if enabled {
            guard globalHotKeyController.register(shortcut: hotKeyShortcut) else {
                hotKeyEnabled = false
                save(false, for: Keys.hotKeyEnabled)
                hotKeyMessage = """
                \(hotKeyLabel) is already used by macOS or another app. \
                Record a different shortcut.
                """
                return
            }
        } else {
            globalHotKeyController.unregister()
        }

        hotKeyEnabled = enabled
        save(enabled, for: Keys.hotKeyEnabled)
    }

    func setHotKeyShortcut(_ shortcut: HotKeyShortcut) {
        guard shortcut != hotKeyShortcut else {
            hotKeyMessage = nil
            return
        }

        let previousShortcut = hotKeyShortcut
        hotKeyMessage = nil

        if hotKeyEnabled {
            guard globalHotKeyController.register(shortcut: shortcut) else {
                _ = globalHotKeyController.register(shortcut: previousShortcut)
                hotKeyMessage = """
                \(shortcut.displayLabel) is already used by macOS or another app.
                """
                return
            }
        }

        hotKeyShortcut = shortcut
        saveHotKeyShortcut()
    }

    func clearHotKey() {
        globalHotKeyController.unregister()
        hotKeyEnabled = false
        save(false, for: Keys.hotKeyEnabled)
        hotKeyMessage = "Shortcut cleared. Turn Global shortcut on to record another."
    }

    func setHotKeyMessage(_ message: String?) {
        hotKeyMessage = message
    }

    func resetSettings() {
        colorHex = "#FF3B30"
        cursorColorHex = "#000000"
        ringEnabled = true
        ringDiameter = 44
        ringThickness = 4
        cursorScale = 1.65
        clickEffect = .ripple
        soundEnabled = true
        soundVolume = 0.28
        soundStyle = .systemTick
        kineticEnabled = false
        hotKeyShortcut = .defaultShortcut
        saveHotKeyShortcut()
        if hotKeyEnabled {
            _ = globalHotKeyController.register(shortcut: hotKeyShortcut)
        }
        statusMessage = "Appearance, motion, click, and shortcut settings were reset."
    }

    func previewClickSound() {
        overlayController.previewClickSound(
            style: soundStyle,
            volume: Float(soundVolume)
        )
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

    private func configureGlobalHotKey() {
        guard hotKeyEnabled else { return }

        if !globalHotKeyController.register(shortcut: hotKeyShortcut) {
            hotKeyEnabled = false
            save(false, for: Keys.hotKeyEnabled)
            hotKeyMessage = """
            \(hotKeyLabel) is already used by macOS or another app. \
            Record a different shortcut.
            """
        }
    }

    private func saveHotKeyShortcut() {
        save(Int(hotKeyShortcut.keyCode), for: Keys.hotKeyKeyCode)
        save(hotKeyShortcut.modifier?.rawValue, for: Keys.hotKeyModifier)
        save(hotKeyShortcut.keyLabel, for: Keys.hotKeyKeyLabel)
    }

    private func save(_ value: Any, for key: String) {
        defaults.set(value, forKey: key)
    }
}
