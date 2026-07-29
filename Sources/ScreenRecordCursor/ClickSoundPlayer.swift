import AppKit
import Foundation

@MainActor
final class ClickSoundPlayer {
    private var soundsByStyle: [ClickSoundStyle: [NSSound]] = [:]
    private var nextSoundIndexByStyle: [ClickSoundStyle: Int] = [:]

    init() {
        for style in ClickSoundStyle.allCases {
            guard let url = Self.soundURL(for: style) else {
                continue
            }

            soundsByStyle[style] = (0..<4).compactMap { _ in
                NSSound(contentsOf: url, byReference: false)
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

    private static func soundURL(for style: ClickSoundStyle) -> URL? {
        if let bundledURL = Bundle.main.url(
            forResource: style.resourceName,
            withExtension: "wav",
            subdirectory: "Sounds"
        ) {
            return bundledURL
        }

        #if DEBUG
            let sourceRoot = URL(fileURLWithPath: #filePath)
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .deletingLastPathComponent()
            let developmentURL = sourceRoot
                .appendingPathComponent("Resources", isDirectory: true)
                .appendingPathComponent("Sounds", isDirectory: true)
                .appendingPathComponent("\(style.resourceName).wav")
            return FileManager.default.fileExists(atPath: developmentURL.path)
                ? developmentURL
                : nil
        #else
            return nil
        #endif
    }
}
