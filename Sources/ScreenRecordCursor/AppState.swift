import AppKit
import Combine
import CursorCore
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

    static let cursorColors = [
        "#000000", // black
        "#FFFFFF", // white
        "#FFCC00", // yellow
        "#FF3B30", // red
        "#007AFF", // blue
        "#34C759", // green
        "#AF52DE", // purple
        "#FF2D55", // pink
        "#FF9500", // orange
        "#00C7BE"  // teal
    ]

    static let quickCursorColors = [
        "#000000", // black
        "#FFFFFF", // white
        "#007AFF", // blue
        "#AF52DE"  // purple
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

    @Published var ringVisibility: RingVisibilityMode {
        didSet {
            save(ringVisibility.rawValue, for: Keys.ringVisibility)
            save(
                ringVisibility != .off,
                for: Keys.legacyRingEnabled
            )

            if ringVisibility == .onClick, clickEffect == .off {
                clickEffect = .ripple
            }

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
        static let ringVisibility = "ringVisibility"
        static let legacyRingEnabled = "ringEnabled"
        static let ringDiameter = "ringDiameter"
        static let ringThickness = "ringThickness"
        static let cursorScale = "cursorScale"
        static let migratedDefaultCursorScale = "migratedDefaultCursorScale"
        static let clickEffect = "clickEffect"
        static let soundEnabled = "soundEnabled"
        static let soundVolume = "soundVolume"
        static let soundStyle = "soundStyle"
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
            Keys.ringDiameter: 44.0,
            Keys.ringThickness: 4.0,
            Keys.cursorScale: 1.5,
            Keys.clickEffect: ClickEffect.ripple.rawValue,
            Keys.soundEnabled: true,
            Keys.soundVolume: 0.28,
            Keys.soundStyle: ClickSoundStyle.mouseClick.rawValue,
            Keys.hotKeyEnabled: true,
            Keys.hotKeyModifier: HotKeyModifier.control.rawValue,
            Keys.hotKeyKeyCode: Int(HotKeyShortcut.defaultShortcut.keyCode),
            Keys.hotKeyKeyLabel: HotKeyShortcut.defaultShortcut.keyLabel
        ])

        colorHex = defaults.string(forKey: Keys.colorHex) ?? "#FF3B30"
        cursorColorHex = defaults.string(
            forKey: Keys.cursorColorHex
        ) ?? "#000000"
        let initialRingVisibility = RingVisibilityMode.initial(
            storedRawValue: defaults.string(forKey: Keys.ringVisibility),
            legacyRingEnabled: defaults.object(
                forKey: Keys.legacyRingEnabled
            ) as? Bool
        )
        ringVisibility = initialRingVisibility
        ringDiameter = defaults.double(forKey: Keys.ringDiameter)
        ringThickness = defaults.double(forKey: Keys.ringThickness)
        let storedCursorScale = defaults.double(forKey: Keys.cursorScale)
        let shouldMigrateDefaultCursorScale = (
            !defaults.bool(forKey: Keys.migratedDefaultCursorScale)
                && abs(storedCursorScale - 1.65) < 0.001
        )
        cursorScale = shouldMigrateDefaultCursorScale ? 1.5 : storedCursorScale
        let storedClickEffect = ClickEffect(
            rawValue: defaults.string(forKey: Keys.clickEffect) ?? ""
        ) ?? .ripple
        clickEffect = initialRingVisibility == .onClick && storedClickEffect == .off
            ? .ripple
            : storedClickEffect
        soundEnabled = defaults.bool(forKey: Keys.soundEnabled)
        soundVolume = defaults.double(forKey: Keys.soundVolume)
        soundStyle = ClickSoundStyle(
            rawValue: defaults.string(forKey: Keys.soundStyle) ?? ""
        ) ?? .mouseClick
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
                    ringVisibility: .onClick,
                    ringDiameter: 44,
                    ringThickness: 4,
                    cursorScale: 1.5,
                    clickEffect: .ripple
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

        if defaults.string(forKey: Keys.ringVisibility) == nil {
            save(ringVisibility.rawValue, for: Keys.ringVisibility)
        }
        if !defaults.bool(forKey: Keys.migratedDefaultCursorScale) {
            if shouldMigrateDefaultCursorScale {
                save(cursorScale, for: Keys.cursorScale)
            }
            save(true, for: Keys.migratedDefaultCursorScale)
        }
    }

    var visualSettings: CursorVisualSettings {
        CursorVisualSettings(
            ringColor: NSColor(hex: colorHex) ?? .systemRed,
            cursorColor: NSColor(hex: cursorColorHex) ?? .black,
            ringVisibility: ringVisibility,
            ringDiameter: ringDiameter,
            ringThickness: ringThickness,
            cursorScale: cursorScale,
            clickEffect: clickEffect
        )
    }

    func setRecordingMode(_ enabled: Bool) {
        guard enabled != isActive else { return }

        if enabled {
            statusMessage = nil
            let result = overlayController.start()
            isActive = true

            if !result.clickMonitoringAvailable {
                statusMessage = """
                The enhanced cursor is on, but macOS did not allow click \
                feedback or click sounds.
                """
            }
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
            Approve Screen Recording Cursor in System Settings → General → Login Items.
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
        ringVisibility = .onClick
        ringDiameter = 44
        ringThickness = 4
        cursorScale = 1.5
        clickEffect = .ripple
        soundEnabled = true
        soundVolume = 0.28
        soundStyle = .mouseClick
        hotKeyShortcut = .defaultShortcut
        saveHotKeyShortcut()
        if hotKeyEnabled {
            _ = globalHotKeyController.register(shortcut: hotKeyShortcut)
        }
        statusMessage = "Appearance, click, and shortcut settings were reset."
    }

    func stopForSystemTransition() {
        stopForSafety(
            message: "The enhanced cursor was turned off before sleep or user switching."
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
        if let modifier = hotKeyShortcut.modifier {
            save(modifier.rawValue, for: Keys.hotKeyModifier)
        } else {
            save("none", for: Keys.hotKeyModifier)
        }
        save(hotKeyShortcut.keyLabel, for: Keys.hotKeyKeyLabel)
    }

    private func save(_ value: Any, for key: String) {
        defaults.set(value, forKey: key)
    }
}
