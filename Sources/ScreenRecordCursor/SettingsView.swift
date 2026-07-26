import AppKit
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var state: AppState

    private let grid = Array(
        repeating: GridItem(.flexible(), spacing: 8),
        count: 5
    )

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            Divider()
            appearance
            Divider()
            clickFeedback
            Divider()
            motion
            footer
        }
        .padding(16)
        .frame(width: 340)
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

            Toggle("Recording mode", isOn: $state.isActive)
                .labelsHidden()
                .toggleStyle(.switch)
                .help("Show or hide the enhanced recording cursor")
        }
    }

    private var appearance: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Appearance")
                .font(.subheadline.weight(.semibold))

            LazyVGrid(columns: grid, spacing: 8) {
                ForEach(AppState.defaultColors, id: \.self) { hex in
                    Button {
                        state.colorHex = hex
                    } label: {
                        Circle()
                            .fill(Color(nsColor: NSColor(hex: hex) ?? .systemRed))
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
                    .accessibilityLabel("Use \(hex)")
                }
            }

            ColorPicker(
                "Custom color",
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
                title: "Cursor size",
                value: $state.cursorScale,
                range: 1.1...3,
                valueLabel: String(format: "%.1f×", state.cursorScale)
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
    }

    private var clickFeedback: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Click feedback")
                .font(.subheadline.weight(.semibold))

            Picker("Effect", selection: $state.clickEffect) {
                ForEach(ClickEffect.allCases) { effect in
                    Text(effect.label).tag(effect)
                }
            }
            .pickerStyle(.segmented)

            Toggle("Play subtle click sound", isOn: $state.soundEnabled)

            if state.soundEnabled {
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

    private var footer: some View {
        HStack {
            Text("Local only · No AI · No network")
                .font(.caption2)
                .foregroundStyle(.tertiary)
            Spacer()
            Button("Quit") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q")
        }
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
