import AppKit
import Foundation

@MainActor
final class ClickSoundPlayer {
    private var sounds: [NSSound]
    private var nextSoundIndex = 0

    init() {
        let data = Self.makeClickWAV()
        sounds = (0..<4).compactMap { _ in NSSound(data: data) }
    }

    func play(volume: Float) {
        guard !sounds.isEmpty else { return }
        let sound = sounds[nextSoundIndex]
        nextSoundIndex = (nextSoundIndex + 1) % sounds.count
        sound.stop()
        sound.volume = min(1, max(0, volume))
        sound.play()
    }

    private static func makeClickWAV() -> Data {
        let sampleRate = 44_100
        let duration = 0.036
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
            let attack = min(1, time / 0.0015)
            let envelope = attack * exp(-time * 105)
            let tone = (
                sin(2 * .pi * 1_650 * time) * 0.68
                + sin(2 * .pi * 820 * time) * 0.32
            )
            let sample = Int16(
                max(-1, min(1, tone * envelope * 0.36)) * Double(Int16.max)
            )
            data.appendLittleEndian(sample)
        }

        return data
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
