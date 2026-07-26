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

    @Published var isActive = false {
        didSet {
            guard oldValue != isActive else { return }
            isActive ? overlayController.start() : overlayController.stop()
        }
    }

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

    func stopForTermination() {
        if isActive {
            isActive = false
        } else {
            overlayController.stop()
        }
    }

    private func save(_ value: Any, for key: String) {
        defaults.set(value, forKey: key)
    }
}
