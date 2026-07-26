import AppKit
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var state: AppState

    private let grid = Array(
        repeating: GridItem(.flexible(), spacing: 8),
        count: 5
    )

    var body: some View {
        Group {
            if state.hasCompletedOnboarding {
                if usesCompactSettingsLayout {
                    ScrollView {
                        settings
                    }
                    .frame(height: compactSettingsHeight)
                } else {
                    settings
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                onboarding
            }
        }
        .padding(16)
        .frame(width: 340)
        .onAppear {
            state.refreshLaunchAtLoginStatus()
        }
    }

    private var usesCompactSettingsLayout: Bool {
        let visibleHeight = NSScreen.main?.visibleFrame.height ?? 900
        return visibleHeight < 840
    }

    private var compactSettingsHeight: CGFloat {
        let visibleHeight = NSScreen.main?.visibleFrame.height ?? 760
        return max(420, min(720, visibleHeight - 96))
    }

    private var settings: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            if let statusMessage = state.statusMessage {
                status(statusMessage)
            }

            Divider()
            appearance
            Divider()
            clickFeedback
            Divider()
            motion
            Divider()
            general
            footer
        }
    }

    private var onboarding: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: "cursorarrow.motionlines")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(Color.accentColor)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 5) {
                Text("A cursor made for recording")
                    .font(.title3.weight(.semibold))
                Text(
                    """
                    Screen Recording Cursor replaces the tiny Mac pointer with one \
                    larger cursor, clear click feedback, and optional kinetic motion.
                    """
                )
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 9) {
                onboardingStep(
                    icon: "1.circle.fill",
                    text: "Turn on Recording mode before you record."
                )
                onboardingStep(
                    icon: "2.circle.fill",
                    text: "Capture a full display or region so the overlay is included."
                )
                onboardingStep(
                    icon: "3.circle.fill",
                    text: "Turn Recording mode off to restore the normal cursor."
                )
            }

            Text("Everything runs locally. No account, data collection, or screen capture.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button {
                state.completeOnboarding(startTest: true)
            } label: {
                Text("Start a 5-second cursor test")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Button("Open settings without testing") {
                state.completeOnboarding(startTest: false)
            }
            .buttonStyle(.link)
            .frame(maxWidth: .infinity)
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Screen Recording Cursor")
                    .font(.headline)
                Text(state.isActive ? "Recording mode is on" : "Ready when you are")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            PersistentRecordingSwitch(
                isOn: Binding(
                    get: { state.isActive },
                    set: { state.setRecordingMode($0) }
                )
            )
            .help("Show or hide the enhanced recording cursor")
        }
    }

    private var appearance: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Appearance")
                .font(.subheadline.weight(.semibold))

            Toggle("Show ring", isOn: $state.ringEnabled)

            if state.ringEnabled {
                Text("Ring color")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: grid, spacing: 8) {
                    ForEach(AppState.defaultColors, id: \.self) { hex in
                        Button {
                            state.colorHex = hex
                        } label: {
                            Circle()
                                .fill(
                                    Color(
                                        nsColor: NSColor(hex: hex) ?? .systemRed
                                    )
                                )
                                .overlay {
                                    Circle()
                                        .strokeBorder(
                                            Color.primary.opacity(
                                                state.colorHex == hex ? 0.9 : 0.16
                                            ),
                                            lineWidth: state.colorHex == hex ? 3 : 1
                                        )
                                }
                                .frame(width: 28, height: 28)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Use \(hex) for the ring")
                    }
                }

                customColorButton(
                    title: "Custom ring color",
                    hex: $state.colorHex,
                    fallback: .systemRed
                )

                slider(
                    title: "Ring size",
                    value: $state.ringDiameter,
                    range: 28...88,
                    valueLabel: "\(Int(state.ringDiameter)) pt"
                )

                slider(
                    title: "Ring weight",
                    value: $state.ringThickness,
                    range: 2...10,
                    valueLabel: "\(Int(state.ringThickness)) pt"
                )
            }

            Text("Cursor color")
                .font(.caption)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: grid, spacing: 8) {
                ForEach(AppState.cursorColors, id: \.self) { hex in
                    Button {
                        state.cursorColorHex = hex
                    } label: {
                        Circle()
                            .fill(
                                Color(
                                    nsColor: NSColor(hex: hex) ?? .black
                                )
                            )
                            .overlay {
                                Circle()
                                    .strokeBorder(
                                        Color.primary.opacity(
                                            state.cursorColorHex == hex ? 0.9 : 0.16
                                        ),
                                        lineWidth: state.cursorColorHex == hex ? 3 : 1
                                    )
                            }
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Use \(hex) for the cursor")
                }
            }

            customColorButton(
                title: "Custom cursor color",
                hex: $state.cursorColorHex,
                fallback: .black
            )

            slider(
                title: "Cursor size",
                value: $state.cursorScale,
                range: 1.1...3,
                valueLabel: String(format: "%.1f×", state.cursorScale)
            )
        }
    }

    private var clickFeedback: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Click feedback")
                .font(.subheadline.weight(.semibold))

            if state.ringEnabled {
                Picker("Ring effect", selection: $state.clickEffect) {
                    ForEach(ClickEffect.allCases) { effect in
                        Text(effect.label).tag(effect)
                    }
                }
                .pickerStyle(.segmented)
            } else {
                Text("Ring effects are hidden. Sound can still play on every click.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Toggle("Play click sound", isOn: $state.soundEnabled)

            if state.soundEnabled {
                HStack {
                    Picker("Sound", selection: $state.soundStyle) {
                        ForEach(ClickSoundStyle.allCases) { style in
                            Text(style.label).tag(style)
                        }
                    }

                    Button("Preview") {
                        state.previewClickSound()
                    }
                }

                slider(
                    title: "Click volume",
                    value: $state.soundVolume,
                    range: 0.05...0.75,
                    valueLabel: "\(Int(state.soundVolume * 100))%"
                )
            }
        }
    }

    private var motion: some View {
        VStack(alignment: .leading, spacing: 5) {
            Toggle("Kinetic cursor", isOn: $state.kineticEnabled)
            Text("The arrow swings into its movement while its hotspot stays exact.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var general: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("General")
                .font(.subheadline.weight(.semibold))

            Toggle(
                "Launch at Login",
                isOn: Binding(
                    get: { state.launchAtLoginEnabled },
                    set: { state.setLaunchAtLogin($0) }
                )
            )

            Toggle(
                "Global shortcut",
                isOn: Binding(
                    get: { state.hotKeyEnabled },
                    set: { state.setHotKeyEnabled($0) }
                )
            )

            if state.hotKeyEnabled {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Shortcut")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ShortcutRecorderView(
                        shortcut: state.hotKeyShortcut,
                        onCapture: state.setHotKeyShortcut,
                        onClear: state.clearHotKey,
                        onMessage: state.setHotKeyMessage
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
                }

                Text(
                    "Click the field, then press one key or one modifier plus one key. "
                        + "Escape cancels; Delete clears."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }

            if let hotKeyMessage = state.hotKeyMessage {
                Text(hotKeyMessage)
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let launchAtLoginMessage = state.launchAtLoginMessage {
                Text(launchAtLoginMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(versionLabel)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Spacer()
                Button("Support") {
                    openSupport()
                }
                Button("Quit") {
                    NSApp.terminate(nil)
                }
                .keyboardShortcut("q")
            }

            HStack {
                Text("Local only · No AI · No network")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Spacer()
                Button("Reset Settings") {
                    state.resetSettings()
                }
                .buttonStyle(.link)
            }
        }
    }

    private var versionLabel: String {
        let version = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String ?? "Development"
        return "Version \(version)"
    }

    private func onboardingStep(icon: String, text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(Color.accentColor)
            Text(text)
                .font(.callout)
        }
    }

    private func status(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(Color.accentColor)
            Text(message)
                .font(.caption)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Button {
                state.dismissStatusMessage()
            } label: {
                Image(systemName: "xmark")
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss")
        }
        .padding(8)
        .background(
            Color.accentColor.opacity(0.1),
            in: RoundedRectangle(cornerRadius: 8)
        )
    }

    private func openSupport() {
        guard let url = URL(
            string: "https://github.com/a-makelky/screen-record-cursor/issues"
        ) else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    private func customColorButton(
        title: String,
        hex: Binding<String>,
        fallback: NSColor
    ) -> some View {
        Button {
            ColorPanelCoordinator.shared.present(
                title: title,
                color: NSColor(hex: hex.wrappedValue) ?? fallback
            ) { color in
                hex.wrappedValue = color.hexString
            }
        } label: {
            HStack {
                Text(title)
                Spacer()
                RoundedRectangle(cornerRadius: 7)
                    .fill(
                        Color(
                            nsColor: NSColor(hex: hex.wrappedValue) ?? fallback
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 7)
                            .strokeBorder(Color.primary.opacity(0.28), lineWidth: 1)
                    }
                    .frame(width: 44, height: 22)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens the macOS color picker")
    }

    private func slider(
        title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        valueLabel: String
    ) -> some View {
        VStack(spacing: 3) {
            HStack {
                Text(title)
                    .font(.caption)
                Spacer()
                Text(valueLabel)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Slider(value: value, in: range)
        }
    }
}

private struct PersistentRecordingSwitch: View {
    @Binding var isOn: Bool

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            ZStack(alignment: isOn ? .trailing : .leading) {
                Capsule()
                    .fill(isOn ? enabledColor : disabledColor)
                    .frame(width: 52, height: 30)

                Circle()
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.22), radius: 1.5, y: 1)
                    .frame(width: 24, height: 24)
                    .padding(3)
            }
            .animation(.easeInOut(duration: 0.14), value: isOn)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Recording mode")
        .accessibilityValue(isOn ? "On" : "Off")
    }

    private var enabledColor: Color {
        Color(red: 0.039, green: 0.518, blue: 1)
    }

    private var disabledColor: Color {
        Color(nsColor: .tertiaryLabelColor).opacity(0.32)
    }
}

@MainActor
private final class ColorPanelCoordinator: NSObject {
    static let shared = ColorPanelCoordinator()

    private var onChange: ((NSColor) -> Void)?

    func present(
        title: String,
        color: NSColor,
        onChange: @escaping (NSColor) -> Void
    ) {
        self.onChange = onChange

        let panel = NSColorPanel.shared
        panel.title = title
        panel.color = color
        panel.isContinuous = true
        panel.setTarget(self)
        panel.setAction(#selector(colorDidChange(_:)))

        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
    }

    @objc
    private func colorDidChange(_ sender: NSColorPanel) {
        onChange?(sender.color)
    }
}
