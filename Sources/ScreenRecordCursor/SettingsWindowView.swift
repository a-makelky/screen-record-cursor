import AppKit
import CursorCore
import SwiftUI

struct SettingsWindowView: View {
    @EnvironmentObject private var state: AppState
    @EnvironmentObject private var navigation: SettingsNavigationModel

    var body: some View {
        HStack(spacing: 0) {
            sidebar

            Group {
                switch navigation.selection {
                case .cursor:
                    cursorSettings
                case .clicks:
                    clickSettings
                case .general:
                    generalSettings
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .frame(minWidth: 720, minHeight: 470)
        .onAppear {
            state.refreshLaunchAtLoginStatus()
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(SettingsSection.allCases) { section in
                Button {
                    navigation.selection = section
                } label: {
                    Label(section.label, systemImage: section.systemImage)
                        .font(.callout.weight(
                            navigation.selection == section ? .medium : .regular
                        ))
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 10)
                        .frame(height: 38)
                        .background(
                            navigation.selection == section
                                ? Color.accentColor.opacity(0.14)
                                : Color.clear,
                            in: RoundedRectangle(cornerRadius: 8)
                        )
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            Spacer()

            Text("\(versionLabel) · Local only")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 14)
        .frame(width: 190)
        .background(Color(nsColor: .underPageBackgroundColor))
    }

    private var cursorSettings: some View {
        VStack(alignment: .leading, spacing: 14) {
            heading(
                "Cursor",
                subtitle: "Adjust the pointer, click ring, and optional motion."
            )

            settingsCard(title: "Pointer") {
                paletteRow(
                    title: "Color",
                    colors: AppState.cursorColors,
                    selection: $state.cursorColorHex,
                    fallback: .black,
                    customTitle: "Custom cursor color"
                )
                sliderRow(
                    title: "Size",
                    value: $state.cursorScale,
                    range: 1.1...3,
                    valueLabel: String(format: "%.1f×", state.cursorScale)
                )
                Toggle("Kinetic cursor", isOn: $state.kineticEnabled)

                if state.kineticEnabled {
                    HStack(spacing: 12) {
                        Text("Motion")
                            .font(.callout)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Picker("Motion", selection: $state.kineticResponse) {
                            ForEach(KineticResponse.allCases) { response in
                                Text(response.label).tag(response)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.segmented)
                        .frame(width: 260)
                        .accessibilityLabel("Kinetic cursor motion")
                    }
                }
            }

            settingsCard {
                HStack(spacing: 16) {
                    Text("Click ring")
                        .font(.callout.weight(.semibold))
                    Spacer()

                    Picker("Ring visibility", selection: $state.ringVisibility) {
                        ForEach(RingVisibilityMode.allCases) { visibility in
                            Text(visibility.label).tag(visibility)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .frame(width: 260)
                    .accessibilityLabel("Ring visibility")
                }

                if state.ringVisibility != .off {
                    paletteRow(
                        title: "Color",
                        colors: AppState.defaultColors,
                        selection: $state.colorHex,
                        fallback: .systemRed,
                        customTitle: "Custom ring color"
                    )
                    sliderRow(
                        title: "Size",
                        value: $state.ringDiameter,
                        range: 28...88,
                        valueLabel: "\(Int(state.ringDiameter)) pt"
                    )
                    sliderRow(
                        title: "Weight",
                        value: $state.ringThickness,
                        range: 2...10,
                        valueLabel: "\(Int(state.ringThickness)) pt"
                    )
                }
            }

            Spacer(minLength: 0)
        }
    }

    private var clickSettings: some View {
        VStack(alignment: .leading, spacing: 14) {
            heading(
                "Clicks",
                subtitle: "Choose what viewers see and hear when you click."
            )

            settingsCard(title: "Click feedback") {
                if state.ringVisibility.allowsClickFeedback {
                    Text("Visual effect")
                        .font(.callout)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                        ForEach(availableClickEffects) { effect in
                            clickEffectButton(effect)
                        }
                    }
                } else {
                    Text(
                        "Turn on the Click ring in Cursor settings to use a visual effect."
                    )
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                Divider()

                HStack {
                    Text("Click sound")
                        .font(.callout.weight(.semibold))
                    Spacer()
                    Toggle("", isOn: $state.soundEnabled)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }

                if state.soundEnabled {
                    HStack(spacing: 10) {
                        Text("Sound")
                            .font(.callout)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Picker("", selection: $state.soundStyle) {
                            ForEach(ClickSoundStyle.allCases) { style in
                                Text(style.label).tag(style)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 190)
                    }

                    sliderRow(
                        title: "Volume",
                        value: $state.soundVolume,
                        range: 0.05...0.75,
                        valueLabel: "\(Int(state.soundVolume * 100))%"
                    )
                }
            }

            Spacer(minLength: 0)
        }
    }

    private var generalSettings: some View {
        VStack(alignment: .leading, spacing: 14) {
            heading(
                "General",
                subtitle: "Set startup behavior and the global Recording mode shortcut."
            )

            settingsCard(title: "Startup") {
                Toggle(
                    "Launch at Login",
                    isOn: Binding(
                        get: { state.launchAtLoginEnabled },
                        set: { state.setLaunchAtLogin($0) }
                    )
                )

                if let launchAtLoginMessage = state.launchAtLoginMessage {
                    Text(launchAtLoginMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            settingsCard {
                HStack {
                    Text("Global shortcut")
                        .font(.callout.weight(.semibold))
                    Spacer()
                    Toggle(
                        "",
                        isOn: Binding(
                            get: { state.hotKeyEnabled },
                            set: { state.setHotKeyEnabled($0) }
                        )
                    )
                    .labelsHidden()
                    .toggleStyle(.switch)
                }

                if state.hotKeyEnabled {
                    ShortcutRecorderView(
                        shortcut: state.hotKeyShortcut,
                        onCapture: state.setHotKeyShortcut,
                        onClear: state.clearHotKey,
                        onMessage: state.setHotKeyMessage
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
                    .help("Click, then press one key or one modifier plus one key")
                }

                if let hotKeyMessage = state.hotKeyMessage {
                    Text(hotKeyMessage)
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            settingsCard(title: "About") {
                HStack {
                    Text("Everything runs locally. No account or screen capture.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Button("Support") {
                        openSupport()
                    }

                    Button("Reset Settings") {
                        state.resetSettings()
                    }
                }
            }

            Spacer(minLength: 0)
        }
    }

    private func heading(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.title2.weight(.semibold))
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var availableClickEffects: [ClickEffect] {
        state.ringVisibility == .onClick
            ? ClickEffect.animatedCases
            : ClickEffect.allCases
    }

    private func settingsCard<Content: View>(
        title: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title {
                Text(title)
                    .font(.callout.weight(.semibold))
            }
            content()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color(nsColor: .controlBackgroundColor),
            in: RoundedRectangle(cornerRadius: 12)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color(nsColor: .separatorColor), lineWidth: 1)
        }
    }

    private func paletteRow(
        title: String,
        colors: [String],
        selection: Binding<String>,
        fallback: NSColor,
        customTitle: String
    ) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.callout)
                .foregroundStyle(.secondary)

            Spacer(minLength: 12)

            HStack(spacing: 6) {
                ForEach(colors, id: \.self) { hex in
                    Button {
                        selection.wrappedValue = hex
                    } label: {
                        Circle()
                            .fill(Color(nsColor: NSColor(hex: hex) ?? fallback))
                            .overlay {
                                Circle()
                                    .strokeBorder(
                                        Color.primary.opacity(
                                            selection.wrappedValue == hex ? 0.9 : 0.18
                                        ),
                                        lineWidth: selection.wrappedValue == hex ? 2.5 : 1
                                    )
                            }
                            .frame(width: 20, height: 20)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Use \(hex.accessibleColorName)")
                    .accessibilityValue(
                        selection.wrappedValue == hex ? "Selected" : "Not selected"
                    )
                }

                Button {
                    ColorPanelCoordinator.shared.present(
                        title: customTitle,
                        color: NSColor(hex: selection.wrappedValue) ?? fallback
                    ) { color in
                        selection.wrappedValue = color.hexString
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(
                                Color(
                                    nsColor: NSColor(hex: selection.wrappedValue)
                                        ?? fallback
                                )
                            )
                        Circle()
                            .strokeBorder(Color.primary.opacity(0.32), lineWidth: 1)
                        Image(systemName: "ellipsis")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(
                                Color(
                                    nsColor: (
                                        NSColor(hex: selection.wrappedValue) ?? fallback
                                    ).contrastingStrokeColor
                                )
                            )
                    }
                    .frame(width: 20, height: 20)
                }
                .buttonStyle(.plain)
                .help(customTitle)
                .accessibilityLabel(customTitle)
                .accessibilityHint("Opens the macOS color picker")
            }
        }
    }

    private func clickEffectButton(_ effect: ClickEffect) -> some View {
        let isSelected = state.clickEffect == effect

        return Button {
            state.clickEffect = effect
        } label: {
            VStack(spacing: 6) {
                Image(systemName: effect.systemImage)
                    .font(.system(size: 17, weight: .medium))
                    .frame(height: 20)

                Text(effect.label)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .foregroundStyle(isSelected ? Color.accentColor : Color.primary)
            .background(
                isSelected
                    ? Color.accentColor.opacity(0.12)
                    : Color.clear,
                in: RoundedRectangle(cornerRadius: 8)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(
                        isSelected
                            ? Color.accentColor
                            : Color(nsColor: .separatorColor),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(effect.label) click effect")
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
    }

    private func sliderRow(
        title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        valueLabel: String
    ) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(width: 58, alignment: .leading)

            Slider(value: value, in: range)

            Text(valueLabel)
                .font(.callout.monospacedDigit())
                .frame(width: 54, alignment: .trailing)
        }
    }

    private var versionLabel: String {
        let version = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String ?? "Development"
        return "Version \(version)"
    }

    private func openSupport() {
        guard let url = URL(
            string: "https://github.com/a-makelky/screen-record-cursor/issues"
        ) else {
            return
        }
        NSWorkspace.shared.open(url)
    }
}

@MainActor
final class ColorPanelCoordinator: NSObject {
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
