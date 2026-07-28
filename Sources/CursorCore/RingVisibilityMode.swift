public enum RingVisibilityMode: String, CaseIterable, Identifiable, Sendable {
    case always
    case onClick
    case off

    public var id: String { rawValue }

    public static func initial(
        storedRawValue: String?,
        legacyRingEnabled: Bool?
    ) -> Self {
        if let storedRawValue,
           let storedMode = Self(rawValue: storedRawValue) {
            return storedMode
        }

        if let legacyRingEnabled {
            return legacyRingEnabled ? .always : .off
        }

        return .onClick
    }

    public var showsPersistentRing: Bool {
        self == .always
    }

    public var allowsClickFeedback: Bool {
        self != .off
    }

    public func showsBaseRing(isClickAnimationActive: Bool) -> Bool {
        switch self {
        case .always:
            true
        case .onClick:
            isClickAnimationActive
        case .off:
            false
        }
    }
}
