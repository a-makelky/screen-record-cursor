import Foundation

/// A small set of motion presets for the optional kinetic cursor.
///
/// The default is deliberately smooth for screen recordings. Faster choices
/// remain available in Settings without exposing animation physics in the
/// everyday menu-bar popover.
public enum KineticResponse: String, CaseIterable, Identifiable, Sendable {
    case smooth
    case balanced
    case quick

    public var id: String { rawValue }

    public var configuration: KineticCursorModel.Configuration {
        switch self {
        case .smooth:
            KineticCursorModel.Configuration(
                activationSpeed: 28,
                fullEffectSpeed: 520,
                velocityResponse: 0.065,
                responsiveness: 13,
                restResponsiveness: 5.5
            )
        case .balanced:
            KineticCursorModel.Configuration(
                activationSpeed: 24,
                fullEffectSpeed: 470,
                velocityResponse: 0.042,
                responsiveness: 22,
                restResponsiveness: 6.5
            )
        case .quick:
            .screenRecording
        }
    }
}
