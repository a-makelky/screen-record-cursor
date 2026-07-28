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
                .foregroundStyle(Color.accentColor)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 5) {
                Text("A cursor made for recording")
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
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

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
        .frame(height: 64)
    }

    private var quickControls: some View {
        VStack(spacing: 0) {
            quickRow(
                title: "Ring",
                value: state.ringVisibility.label,
                systemImage: "circle.fill",
                color: Color(nsColor: NSColor(hex: state.colorHex) ?? .systemRed),
                section: .cursor
            )

            quickRow(
                title: "Cursor",
                value: String(format: "%.1f×", state.cursorScale),
                systemImage: "cursorarrow",
                color: Color(
                    nsColor: NSColor(hex: state.cursorColorHex) ?? .labelColor
                ),
                section: .cursor
            )

            quickRow(
                title: "Click feedback",
                value: state.ringVisibility.allowsClickFeedback
                    ? state.clickEffect.label
                    : "Off",
                systemImage: "cursorarrow.click",
                color: .accentColor,
                section: .clicks
            )

            quickRow(
                title: "Kinetic cursor",
                value: state.kineticEnabled ? "On" : "Off",
                systemImage: "cursorarrow.motionlines",
                color: .accentColor,
                section: .cursor
            )

            quickRow(
                title: "Click sound",
                value: state.soundEnabled ? state.soundStyle.label : "Off",
                systemImage: "speaker.wave.2.fill",
                color: .accentColor,
                section: .clicks
            )

            quickRow(
                title: "Shortcut",
                value: state.hotKeyEnabled ? state.hotKeyLabel : "Off",
                systemImage: "keyboard",
                color: .secondary,
                section: .general,
                showsDivider: false
            )
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
        .frame(height: 48)
    }

    private func quickRow(
        title: String,
        value: String,
        systemImage: String,
        color: Color,
        section: SettingsSection,
        showsDivider: Bool = true
    ) -> some View {
        Button {
            SettingsWindowController.shared.show(section: section)
        } label: {
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    Image(systemName: systemImage)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(color)
                        .frame(width: 18, height: 18)
                        .accessibilityHidden(true)

                    Text(title)
                        .font(.callout.weight(.medium))
                        .foregroundStyle(.primary)

                    Spacer(minLength: 8)

                    Text(value)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.tertiary)
                        .accessibilityHidden(true)
                }
                .frame(height: 46)
                .contentShape(Rectangle())

                if showsDivider {
                    Divider()
                        .padding(.leading, 28)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title), \(value)")
        .accessibilityHint("Opens \(section.label) settings")
    }

    private func status(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(Color.accentColor)
                .accessibilityHidden(true)

            Text(message)
                .font(.caption)
                .fixedSize(horizontal: false, vertical: true)

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

struct PersistentRecordingSwitch: View {
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
