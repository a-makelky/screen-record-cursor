import AppKit
import Foundation

@MainActor
final class ClickSoundPlayer {
    private var soundsByStyle: [ClickSoundStyle: [NSSound]] = [:]
    private var nextSoundIndexByStyle: [ClickSoundStyle: Int] = [:]

    init() {
        for style in ClickSoundStyle.allCases {
            let data = Self.makeClickWAV(style: style)
            soundsByStyle[style] = (0..<4).compactMap { _ in
                NSSound(data: data)
            }
            nextSoundIndexByStyle[style] = 0
        }
    }

    func play(style: ClickSoundStyle, volume: Float) {
        guard let sounds = soundsByStyle[style], !sounds.isEmpty else { return }

        let nextIndex = nextSoundIndexByStyle[style] ?? 0
        let sound = sounds[nextIndex]
        nextSoundIndexByStyle[style] = (nextIndex + 1) % sounds.count
        sound.stop()
        sound.volume = min(1, max(0, volume))
        sound.play()
    }

    private static func makeClickWAV(style: ClickSoundStyle) -> Data {
        let sampleRate = 44_100
        let duration = style.duration
        let sampleCount = Int(Double(sampleRate) * duration)
        let bytesPerSample = 2
        let dataSize = sampleCount * bytesPerSample

        var data = Data()
        data.append(contentsOf: Array("RIFF".utf8))
        data.appendLittleEndian(UInt32(36 + dataSize))
        data.append(contentsOf: Array("WAVE".utf8))
        data.append(contentsOf: Array("fmt ".utf8))
        data.appendLittleEndian(UInt32(16))
        data.appendLittleEndian(UInt16(1))
        data.appendLittleEndian(UInt16(1))
        data.appendLittleEndian(UInt32(sampleRate))
        data.appendLittleEndian(UInt32(sampleRate * bytesPerSample))
        data.appendLittleEndian(UInt16(bytesPerSample))
        data.appendLittleEndian(UInt16(16))
        data.append(contentsOf: Array("data".utf8))
        data.appendLittleEndian(UInt32(dataSize))

        for index in 0..<sampleCount {
            let time = Double(index) / Double(sampleRate)
            let tone = sample(
                style: style,
                time: time,
                index: index
            )
            let sample = Int16(
                max(-1, min(1, tone)) * Double(Int16.max)
            )
            data.appendLittleEndian(sample)
        }

        return data
    }

    private static func sample(
        style: ClickSoundStyle,
        time: Double,
        index: Int
    ) -> Double {
        let noise = deterministicNoise(at: index)

        switch style {
        case .systemTick:
            let attack = min(1, time / 0.0015)
            let envelope = attack * exp(-time * 105)
            return (
                sin(2 * .pi * 1_650 * time) * 0.68
                + sin(2 * .pi * 820 * time) * 0.32
            ) * envelope * 0.36

        case .softTap:
            let envelope = min(1, time / 0.0025) * exp(-time * 78)
            return (
                sin(2 * .pi * 520 * time) * 0.72
                + noise * 0.28
            ) * envelope * 0.28

        case .mechanical:
            let primary = exp(-time * 185)
            let secondaryTime = max(0, time - 0.012)
            let secondary = time >= 0.012 ? exp(-secondaryTime * 210) : 0
            return (
                noise * primary * 0.34
                + sin(2 * .pi * 2_450 * time) * primary * 0.24
                + noise * secondary * 0.18
            )

        case .typewriter:
            let clack = exp(-time * 140)
            let thudTime = max(0, time - 0.018)
            let thud = time >= 0.018 ? exp(-thudTime * 68) : 0
            return (
                noise * clack * 0.25
                + sin(2 * .pi * 1_150 * time) * clack * 0.2
                + sin(2 * .pi * 185 * thudTime) * thud * 0.32
            )

        case .bubblePop:
            let envelope = min(1, time / 0.001) * exp(-time * 48)
            let phase = 2 * .pi * (1_100 * time - 3_900 * time * time)
            return sin(phase) * envelope * 0.38
        }
    }

    private static func deterministicNoise(at index: Int) -> Double {
        let value = sin(Double(index) * 12.9898) * 43_758.5453
        return (value - floor(value)) * 2 - 1
    }
}

private extension ClickSoundStyle {
    var duration: Double {
        switch self {
        case .systemTick: 0.036
        case .softTap: 0.05
        case .mechanical: 0.055
        case .typewriter: 0.085
        case .bubblePop: 0.075
        }
    }
}

private extension Data {
    mutating func appendLittleEndian<T: FixedWidthInteger>(_ value: T) {
        var littleEndian = value.littleEndian
        Swift.withUnsafeBytes(of: &littleEndian) { bytes in
            append(contentsOf: bytes)
        }
    }
}
