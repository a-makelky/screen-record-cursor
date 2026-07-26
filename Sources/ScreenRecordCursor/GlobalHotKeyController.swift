import AppKit
import Carbon.HIToolbox
import Foundation

enum HotKeyModifier: String {
    case control
    case option
    case shift
    case command

    var symbol: String {
        switch self {
        case .control: "⌃"
        case .option: "⌥"
        case .shift: "⇧"
        case .command: "⌘"
        }
    }

    var carbonMask: UInt32 {
        switch self {
        case .control: UInt32(controlKey)
        case .option: UInt32(optionKey)
        case .shift: UInt32(shiftKey)
        case .command: UInt32(cmdKey)
        }
    }

    static func capture(from flags: NSEvent.ModifierFlags) throws -> HotKeyModifier? {
        let active = [
            (NSEvent.ModifierFlags.control, HotKeyModifier.control),
            (.option, .option),
            (.shift, .shift),
            (.command, .command)
        ].compactMap { flag, modifier in
            flags.contains(flag) ? modifier : nil
        }

        guard active.count <= 1 else {
            throw HotKeyCaptureError.tooManyKeys
        }
        return active.first
    }
}

struct HotKeyShortcut: Equatable {
    let keyCode: UInt32
    let modifier: HotKeyModifier?
    let keyLabel: String

    static let defaultShortcut = HotKeyShortcut(
        keyCode: UInt32(kVK_ANSI_Semicolon),
        modifier: .control,
        keyLabel: ";"
    )

    var displayLabel: String {
        "\(modifier?.symbol ?? "")\(keyLabel)"
    }

    var carbonModifiers: UInt32 {
        modifier?.carbonMask ?? 0
    }

    static func capture(from event: NSEvent) throws -> HotKeyShortcut {
        let modifier = try HotKeyModifier.capture(
            from: event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        )
        let keyCode = UInt32(event.keyCode)

        guard let label = label(for: event) else {
            throw HotKeyCaptureError.unsupportedKey
        }

        if modifier == nil && !safeWithoutModifier.contains(keyCode) {
            throw HotKeyCaptureError.modifierRequired
        }

        return HotKeyShortcut(
            keyCode: keyCode,
            modifier: modifier,
            keyLabel: label
        )
    }

    private static func label(for event: NSEvent) -> String? {
        let code = UInt32(event.keyCode)
        if let label = specialKeyLabels[code] {
            return label
        }

        guard let characters = event.charactersIgnoringModifiers,
              !characters.isEmpty else {
            return nil
        }

        if characters == " " {
            return "Space"
        }
        return characters.uppercased()
    }

    private static let safeWithoutModifier: Set<UInt32> = Set(
        specialKeyLabels.keys
    )

    private static let specialKeyLabels: [UInt32: String] = [
        UInt32(kVK_F1): "F1",
        UInt32(kVK_F2): "F2",
        UInt32(kVK_F3): "F3",
        UInt32(kVK_F4): "F4",
        UInt32(kVK_F5): "F5",
        UInt32(kVK_F6): "F6",
        UInt32(kVK_F7): "F7",
        UInt32(kVK_F8): "F8",
        UInt32(kVK_F9): "F9",
        UInt32(kVK_F10): "F10",
        UInt32(kVK_F11): "F11",
        UInt32(kVK_F12): "F12",
        UInt32(kVK_F13): "F13",
        UInt32(kVK_F14): "F14",
        UInt32(kVK_F15): "F15",
        UInt32(kVK_F16): "F16",
        UInt32(kVK_F17): "F17",
        UInt32(kVK_F18): "F18",
        UInt32(kVK_F19): "F19",
        UInt32(kVK_F20): "F20",
        UInt32(kVK_LeftArrow): "←",
        UInt32(kVK_RightArrow): "→",
        UInt32(kVK_UpArrow): "↑",
        UInt32(kVK_DownArrow): "↓",
        UInt32(kVK_Home): "Home",
        UInt32(kVK_End): "End",
        UInt32(kVK_PageUp): "Page Up",
        UInt32(kVK_PageDown): "Page Down"
    ]
}

enum HotKeyCaptureError: LocalizedError {
    case tooManyKeys
    case modifierRequired
    case unsupportedKey

    var errorDescription: String? {
        switch self {
        case .tooManyKeys:
            "Use one key by itself or one modifier plus one key."
        case .modifierRequired:
            "Letters, numbers, and punctuation need one modifier key."
        case .unsupportedKey:
            "That key cannot be used as a global shortcut."
        }
    }
}

final class GlobalHotKeyController {
    private static let signature: OSType = 0x53524352 // "SRCR"
    private static let identifier: UInt32 = 1

    private let action: @MainActor () -> Void
    private var hotKeyReference: EventHotKeyRef?
    private var eventHandlerReference: EventHandlerRef?

    init(action: @escaping @MainActor () -> Void) {
        self.action = action

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let result = InstallEventHandler(
            GetApplicationEventTarget(),
            Self.eventHandler,
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandlerReference
        )
        if result != noErr {
            eventHandlerReference = nil
        }
    }

    deinit {
        unregister()
        if let eventHandlerReference {
            RemoveEventHandler(eventHandlerReference)
        }
    }

    @discardableResult
    func register(shortcut: HotKeyShortcut) -> Bool {
        unregister()
        guard eventHandlerReference != nil else { return false }

        let identifier = EventHotKeyID(
            signature: Self.signature,
            id: Self.identifier
        )
        let result = RegisterEventHotKey(
            shortcut.keyCode,
            shortcut.carbonModifiers,
            identifier,
            GetApplicationEventTarget(),
            0,
            &hotKeyReference
        )
        return result == noErr
    }

    func unregister() {
        if let hotKeyReference {
            UnregisterEventHotKey(hotKeyReference)
            self.hotKeyReference = nil
        }
    }

    private static let eventHandler: EventHandlerUPP = {
        _, _, userData in
        guard let userData else {
            return OSStatus(eventNotHandledErr)
        }

        let controller = Unmanaged<GlobalHotKeyController>
            .fromOpaque(userData)
            .takeUnretainedValue()
        Task { @MainActor in
            controller.action()
        }
        return noErr
    }
}
