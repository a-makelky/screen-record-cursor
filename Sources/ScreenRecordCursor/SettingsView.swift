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
                ScrollView {
                    settings
                }
                .frame(maxHeight: settingsMaximumHeight)
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

    private var settingsMaximumHeight: CGFloat {
        let visibleHeight = NSScreen.main?.visibleFrame.height ?? 760
        return max(420, min(760, visibleHeight - 48))
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
                    Screen Record Cursor replaces the tiny Mac pointer with one \
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
                Text("Screen Record Cursor")
                    .font(.headline)
                Text(state.isActive ? "Recording mode is on" : "Ready when you are")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle(
                "Recording mode",
                isOn: Binding(
                    get: { state.isActive },
                    set: { state.setRecordingMode($0) }
                )
            )
                .labelsHidden()
                .toggleStyle(.switch)
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

                ColorPicker(
                    "Custom ring color",
                    selection: Binding(
                        get: {
                            Color(
                                nsColor: NSColor(hex: state.colorHex) ?? .systemRed
                            )
                        },
                        set: { color in
                            state.colorHex = NSColor(color).hexString
                        }
                    ),
                    supportsOpacity: false
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

            ColorPicker(
                "Cursor color",
                selection: Binding(
                    get: {
                        Color(
                            nsColor: NSColor(hex: state.cursorColorHex) ?? .black
                        )
                    },
                    set: { color in
                        state.cursorColorHex = NSColor(color).hexString
                    }
                ),
                supportsOpacity: false
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
                HStack {
                    Picker(
                        "Modifier",
                        selection: Binding(
                            get: { state.hotKeyModifier },
                            set: { state.setHotKeyModifier($0) }
                        )
                    ) {
                        ForEach(HotKeyModifier.allCases) { modifier in
                            Text(modifier.label).tag(modifier)
                        }
                    }

                    Picker(
                        "Key",
                        selection: Binding(
                            get: { state.hotKeyKey },
                            set: { state.setHotKeyKey($0) }
                        )
                    ) {
                        ForEach(HotKeyKey.allCases) { key in
                            Text(key.label).tag(key)
                        }
                    }
                    .frame(width: 74)
                }

                Text("\(state.hotKeyLabel) toggles Recording mode from any app.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
