import AppKit
import CursorCore
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        Group {
            if state.hasCompletedOnboarding {
                compactPopover
            } else {
                onboarding
            }
        }
        .frame(width: 336)
        .onAppear {
            state.refreshLaunchAtLoginStatus()
        }
    }

    private var compactPopover: some View {
        VStack(spacing: 0) {
            header

            if let statusMessage = state.statusMessage {
                status(statusMessage)
                    .padding(.bottom, 8)
            }

            quickControls
            footer
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 10)
    }

    private var onboarding: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: "cursorarrow.motionlines")
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(.primary)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 5) {
                Text("Make your cursor easy to follow")
                    .font(.title3.weight(.semibold))
                Text("Turn it on before you record. Everything stays on your Mac.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button {
                state.completeOnboarding(startTest: true)
            } label: {
                Text("Try the cursor")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color(nsColor: .windowBackgroundColor))
                    .frame(maxWidth: .infinity)
                    .frame(height: 30)
                    .background(
                        Color.primary,
                        in: RoundedRectangle(cornerRadius: 7)
                    )
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.defaultAction)
            .accessibilityHint("Turns on the enhanced cursor")

            Button("Set up later") {
                state.completeOnboarding(startTest: false)
            }
            .buttonStyle(.link)
            .frame(maxWidth: .infinity)
        }
        .padding(20)
    }

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Screen Recording Cursor")
                    .font(.headline)
                Text(state.isActive ? "Enhanced cursor is on" : "Enhanced cursor is off")
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
            .help("Turn the enhanced cursor on or off")
        }
        .frame(height: 58)
    }

    private var quickControls: some View {
        VStack(spacing: 0) {
            quickControlRow(title: "Cursor color") {
                HStack(spacing: 6) {
                    ForEach(AppState.quickCursorColors, id: \.self) { hex in
                        quickColorButton(hex: hex)
                    }

                    Button {
                        ColorPanelCoordinator.shared.present(
                            title: "Custom cursor color",
                            color: NSColor(hex: state.cursorColorHex) ?? .black
                        ) { color in
                            state.cursorColorHex = color.hexString
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(
                                    Color(
                                        nsColor: NSColor(hex: state.cursorColorHex)
                                            ?? .black
                                    )
                                )
                            Circle()
                                .strokeBorder(
                                    Color.primary.opacity(0.35),
                                    lineWidth: 1
                                )
                            Image(systemName: "ellipsis")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(
                                    Color(
                                        nsColor: (
                                            NSColor(hex: state.cursorColorHex)
                                                ?? .black
                                        ).contrastingStrokeColor
                                    )
                                )
                        }
                        .frame(width: 22, height: 22)
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .help("Choose a custom cursor color")
                    .accessibilityLabel("Choose a custom cursor color")
                }
            }

            quickControlRow(title: "Cursor size") {
                HStack(spacing: 4) {
                    ForEach(CursorScalePreset.quickChoices) { preset in
                        Button {
                            state.cursorScale = preset.value
                        } label: {
                            Text(preset.label)
                                .font(.caption.weight(.medium))
                                .frame(width: 40, height: 28)
                                .background(
                                    preset.matches(state.cursorScale)
                                        ? Color.accentColor
                                        : Color(nsColor: .controlBackgroundColor),
                                    in: RoundedRectangle(cornerRadius: 6)
                                )
                                .foregroundStyle(
                                    preset.matches(state.cursorScale)
                                        ? Color.white
                                        : Color.primary
                                )
                                .overlay {
                                    RoundedRectangle(cornerRadius: 6)
                                        .strokeBorder(
                                            preset.matches(state.cursorScale)
                                                ? Color.clear
                                                : Color(nsColor: .separatorColor),
                                            lineWidth: 1
                                        )
                                }
                                .contentShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Set cursor size to \(preset.label)")
                        .accessibilityValue(
                            preset.matches(state.cursorScale)
                                ? "Selected"
                                : "Not selected"
                        )
                    }
                }
            }

            quickControlRow(title: "Click ring") {
                Picker("Click ring", selection: $state.ringVisibility) {
                    ForEach(RingVisibilityMode.allCases) { visibility in
                        Text(visibility.label).tag(visibility)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .frame(width: 190)
                .accessibilityLabel("Click ring visibility")
                .accessibilityValue(state.ringVisibility.label)
            }

            quickControlRow(
                title: "Click feedback",
                showsDivider: false
            ) {
                HStack(spacing: 8) {
                    Menu {
                        ForEach(availableClickEffects) { effect in
                            Button {
                                state.clickEffect = effect
                            } label: {
                                Label(effect.label, systemImage: effect.systemImage)
                            }
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: currentClickEffect.systemImage)
                                .accessibilityHidden(true)
                            Text(currentClickEffect.label)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 8, weight: .semibold))
                                .accessibilityHidden(true)
                        }
                        .font(.caption)
                        .frame(minWidth: 78, minHeight: 28)
                        .contentShape(Rectangle())
                    }
                    .disabled(!state.ringVisibility.allowsClickFeedback)
                    .accessibilityLabel("Click effect, \(currentClickEffect.label)")

                    Button {
                        state.soundEnabled.toggle()
                    } label: {
                        Image(
                            systemName: state.soundEnabled
                                ? "speaker.wave.2.fill"
                                : "speaker.slash.fill"
                        )
                        .font(.system(size: 13, weight: .medium))
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .help(state.soundEnabled ? "Mute click sound" : "Turn on click sound")
                    .accessibilityLabel(
                        state.soundEnabled ? "Mute click sound" : "Turn on click sound"
                    )
                }
            }

        }
    }

    private var footer: some View {
        HStack {
            Button("Settings…") {
                SettingsWindowController.shared.show(section: .cursor)
            }
            .buttonStyle(.link)

            Spacer()

            Button("Quit") {
                NSApp.terminate(nil)
            }
            .buttonStyle(.plain)
            .keyboardShortcut("q")
        }
        .font(.callout)
        .frame(height: 44)
    }

    private func quickControlRow<Control: View>(
        title: String,
        showsDivider: Bool = true,
        @ViewBuilder control: () -> Control
    ) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Text(title)
                    .font(.callout.weight(.medium))

                Spacer(minLength: 8)

                control()
            }
            .frame(height: 46)

            if showsDivider {
                Divider()
            }
        }
    }

    private func quickColorButton(hex: String) -> some View {
        let isSelected = state.cursorColorHex == hex
        let color = NSColor(hex: hex) ?? .black

        return Button {
            state.cursorColorHex = hex
        } label: {
            Circle()
                .fill(Color(nsColor: color))
                .overlay {
                    Circle()
                        .strokeBorder(
                            isSelected
                                ? Color.accentColor
                                : Color.primary.opacity(0.25),
                            lineWidth: isSelected ? 3 : 1
                        )
                }
                .padding(isSelected ? 1 : 0)
                .frame(width: 22, height: 22)
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Use \(hex.accessibleColorName) cursor")
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
    }

    private var availableClickEffects: [ClickEffect] {
        state.ringVisibility == .onClick
            ? ClickEffect.animatedCases
            : ClickEffect.allCases
    }

    private var currentClickEffect: ClickEffect {
        state.ringVisibility.allowsClickFeedback ? state.clickEffect : .off
    }

    private func status(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(Color.accentColor)
                .accessibilityHidden(true)

            Text(message)
                .font(.caption)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
                .help(message)

            Spacer(minLength: 4)

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
}

private struct CursorScalePreset: Identifiable {
    let label: String
    let value: Double

    var id: Double { value }

    func matches(_ currentValue: Double) -> Bool {
        abs(value - currentValue) < 0.01
    }

    static let quickChoices = [
        CursorScalePreset(label: "1×", value: 1),
        CursorScalePreset(label: "1.5×", value: 1.5),
        CursorScalePreset(label: "2×", value: 2),
        CursorScalePreset(label: "3×", value: 3)
    ]
}

struct PersistentRecordingSwitch: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var isOn: Bool

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            ZStack(alignment: isOn ? .trailing : .leading) {
                Capsule()
                    .fill(isOn ? enabledColor : disabledColor)
                    .frame(width: 48, height: 28)

                Circle()
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.22), radius: 1.5, y: 1)
                    .frame(width: 22, height: 22)
                    .padding(3)
            }
            .animation(
                reduceMotion ? nil : .easeInOut(duration: 0.14),
                value: isOn
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Recording mode")
        .accessibilityValue(isOn ? "On" : "Off")
    }

    private var enabledColor: Color {
        BrandPalette.brightBlue
    }

    private var disabledColor: Color {
        Color(nsColor: .tertiaryLabelColor).opacity(0.32)
    }
}
