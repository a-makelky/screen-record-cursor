import CoreGraphics
import Foundation

public struct CursorMotionFrame: Equatable, Sendable {
    public let rotationRadians: Double
    public let speed: Double

    public init(rotationRadians: Double, speed: Double) {
        self.rotationRadians = rotationRadians
        self.speed = speed
    }
}

/// A deterministic, presentation-only motion model.
///
/// The cursor hotspot always remains at the real pointer location. Kinetic mode
/// rotates the drawn arrow around its fixed hotspot so its tail trails behind the
/// direction of travel, then smoothly returns it to the standard northwest
/// heading after motion stops.
public struct KineticCursorModel: Sendable {
    public struct Configuration: Equatable, Sendable {
        public var activationSpeed: Double
        public var fullEffectSpeed: Double
        public var velocityResponse: TimeInterval
        public var responsiveness: Double
        public var restResponsiveness: Double
        public var baseHeadingRadians: Double
        public var maximumTiltRadians: Double

        public init(
            activationSpeed: Double = 20,
            fullEffectSpeed: Double = 420,
            velocityResponse: TimeInterval = 0.025,
            responsiveness: Double = 36,
            restResponsiveness: Double = 7,
            baseHeadingRadians: Double = 3 * .pi / 4,
            maximumTiltRadians: Double = .pi
        ) {
            self.activationSpeed = activationSpeed
            self.fullEffectSpeed = fullEffectSpeed
            self.velocityResponse = velocityResponse
            self.responsiveness = responsiveness
            self.restResponsiveness = restResponsiveness
            self.baseHeadingRadians = baseHeadingRadians
            self.maximumTiltRadians = maximumTiltRadians
        }

        public static let screenRecording = Configuration()
    }

    private(set) public var rotationRadians: Double = 0
    private(set) public var speed: Double = 0

    private var lastPosition: CGPoint?
    private var lastTimestamp: TimeInterval?
    private var filteredVelocityX: Double = 0
    private var filteredVelocityY: Double = 0
    private let configuration: Configuration

    public init(configuration: Configuration = .screenRecording) {
        self.configuration = configuration
    }

    public mutating func update(
        position: CGPoint,
        timestamp: TimeInterval,
        enabled: Bool
    ) -> CursorMotionFrame {
        guard position.x.isFinite,
              position.y.isFinite,
              timestamp.isFinite else {
            return CursorMotionFrame(rotationRadians: rotationRadians, speed: speed)
        }

        guard let previousPosition = lastPosition,
              let previousTimestamp = lastTimestamp else {
            lastPosition = position
            lastTimestamp = timestamp
            return CursorMotionFrame(rotationRadians: rotationRadians, speed: speed)
        }

        let elapsed = timestamp - previousTimestamp

        guard elapsed > 0 else {
            return CursorMotionFrame(rotationRadians: rotationRadians, speed: speed)
        }

        if elapsed >= 0.25 {
            lastPosition = position
            lastTimestamp = timestamp
            speed = 0
            filteredVelocityX = 0
            filteredVelocityY = 0
            rotationRadians = 0
            return CursorMotionFrame(rotationRadians: rotationRadians, speed: speed)
        }

        lastPosition = position
        lastTimestamp = timestamp

        let velocityX = Double(position.x - previousPosition.x) / elapsed
        let velocityY = Double(position.y - previousPosition.y) / elapsed
        let velocityAlpha = 1 - exp(-elapsed / configuration.velocityResponse)

        filteredVelocityX += velocityAlpha * (velocityX - filteredVelocityX)
        filteredVelocityY += velocityAlpha * (velocityY - filteredVelocityY)
        speed = hypot(filteredVelocityX, filteredVelocityY)

        let targetRotation: Double
        let response: Double

        if enabled, speed >= configuration.activationSpeed {
            let direction = atan2(filteredVelocityY, filteredVelocityX)
            let directionalRotation = wrappedAngle(
                direction - configuration.baseHeadingRadians
            )
            let strength = smoothstep(
                edge0: configuration.activationSpeed,
                edge1: configuration.fullEffectSpeed,
                value: speed
            )
            targetRotation = min(
                configuration.maximumTiltRadians,
                max(-configuration.maximumTiltRadians, directionalRotation)
            ) * strength
            response = configuration.responsiveness
        } else {
            targetRotation = 0
            response = configuration.restResponsiveness
        }

        rotationRadians = approach(
            current: rotationRadians,
            target: targetRotation,
            rate: response,
            elapsed: elapsed
        )

        return CursorMotionFrame(rotationRadians: rotationRadians, speed: speed)
    }

    public mutating func reset() {
        rotationRadians = 0
        speed = 0
        filteredVelocityX = 0
        filteredVelocityY = 0
        lastPosition = nil
        lastTimestamp = nil
    }

    private func approach(
        current: Double,
        target: Double,
        rate: Double,
        elapsed: TimeInterval
    ) -> Double {
        let alpha = 1 - exp(-max(0, rate) * max(0, elapsed))
        let delta = wrappedAngle(target - current)
        return wrappedAngle(current + delta * alpha)
    }

    private func smoothstep(edge0: Double, edge1: Double, value: Double) -> Double {
        guard edge1 > edge0 else {
            return value >= edge1 ? 1 : 0
        }
        let normalized = min(1, max(0, (value - edge0) / (edge1 - edge0)))
        return normalized * normalized * (3 - 2 * normalized)
    }

    private func wrappedAngle(_ angle: Double) -> Double {
        var result = angle.truncatingRemainder(dividingBy: 2 * .pi)
        if result > .pi {
            result -= 2 * .pi
        } else if result < -.pi {
            result += 2 * .pi
        }
        return result
    }
}
