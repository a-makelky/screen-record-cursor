import Carbon.HIToolbox
import Foundation

enum HotKeyModifier: String, CaseIterable, Identifiable {
    case control
    case option
    case shift
    case command

    var id: String { rawValue }

    var label: String {
        switch self {
        case .control: "Control ⌃"
        case .option: "Option ⌥"
        case .shift: "Shift ⇧"
        case .command: "Command ⌘"
        }
    }

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
}

enum HotKeyKey: String, CaseIterable, Identifiable {
    case semicolon
    case slash
    case backslash
    case comma
    case period
    case c
    case k
    case p
    case r

    var id: String { rawValue }

    var label: String {
        switch self {
        case .semicolon: ";"
        case .slash: "/"
        case .backslash: "\\"
        case .comma: ","
        case .period: "."
        case .c: "C"
        case .k: "K"
        case .p: "P"
        case .r: "R"
        }
    }

    var carbonKeyCode: UInt32 {
        switch self {
        case .semicolon: UInt32(kVK_ANSI_Semicolon)
        case .slash: UInt32(kVK_ANSI_Slash)
        case .backslash: UInt32(kVK_ANSI_Backslash)
        case .comma: UInt32(kVK_ANSI_Comma)
        case .period: UInt32(kVK_ANSI_Period)
        case .c: UInt32(kVK_ANSI_C)
        case .k: UInt32(kVK_ANSI_K)
        case .p: UInt32(kVK_ANSI_P)
        case .r: UInt32(kVK_ANSI_R)
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
    func register(modifier: HotKeyModifier, key: HotKeyKey) -> Bool {
        unregister()
        guard eventHandlerReference != nil else { return false }

        let identifier = EventHotKeyID(
            signature: Self.signature,
            id: Self.identifier
        )
        let result = RegisterEventHotKey(
            key.carbonKeyCode,
            modifier.carbonMask,
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
