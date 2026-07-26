import AppKit
import CursorCore

enum ClickEffect: String, CaseIterable, Identifiable {
    case ripple
    case pulse
    case both
    case off

    var id: String { rawValue }

    var label: String {
        switch self {
        case .ripple: "Ripple"
        case .pulse: "Blink"
        case .both: "Both"
        case .off: "Off"
        }
    }

    static let animatedCases: [ClickEffect] = [.ripple, .pulse, .both]
}

extension RingVisibilityMode {
    var label: String {
        switch self {
        case .always: "Always"
        case .onClick: "On Click"
        case .off: "Off"
        }
    }
}

enum ClickSoundStyle: String, CaseIterable, Identifiable {
    case mouseClick
    case plopClick
    case typewriter
    case spacebar
    case mousePop

    var id: String { rawValue }

    var label: String {
        switch self {
        case .mouseClick: "Mouse Click"
        case .plopClick: "Plop Click"
        case .typewriter: "Typewriter"
        case .spacebar: "Space Bar"
        case .mousePop: "Mouse Pop"
        }
    }

    var resourceName: String {
        switch self {
        case .mouseClick: "mouse-click"
        case .plopClick: "plop-click"
        case .typewriter: "typewriter"
        case .spacebar: "spacebar"
        case .mousePop: "mouse-pop"
        }
    }
}

struct CursorVisualSettings {
    var ringColor: NSColor
    var cursorColor: NSColor
    var ringVisibility: RingVisibilityMode
    var ringDiameter: CGFloat
    var ringThickness: CGFloat
    var cursorScale: CGFloat
    var clickEffect: ClickEffect
    var kineticEnabled: Bool
}

extension NSColor {
    convenience init?(hex: String) {
        let value = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        guard value.count == 6, let integer = UInt64(value, radix: 16) else {
            return nil
        }

        self.init(
            srgbRed: CGFloat((integer >> 16) & 0xFF) / 255,
            green: CGFloat((integer >> 8) & 0xFF) / 255,
            blue: CGFloat(integer & 0xFF) / 255,
            alpha: 1
        )
    }

    var hexString: String {
        guard let rgb = usingColorSpace(.sRGB) else {
            return "#FF3B30"
        }

        return String(
            format: "#%02X%02X%02X",
            Int(round(rgb.redComponent * 255)),
            Int(round(rgb.greenComponent * 255)),
            Int(round(rgb.blueComponent * 255))
        )
    }

    var contrastingStrokeColor: NSColor {
        guard let rgb = usingColorSpace(.sRGB) else {
            return .white
        }

        let luminance = (
            0.2126 * rgb.redComponent
            + 0.7152 * rgb.greenComponent
            + 0.0722 * rgb.blueComponent
        )
        return luminance > 0.58 ? .black : .white
    }
}
