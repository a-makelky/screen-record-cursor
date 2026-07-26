import CoreGraphics
import XCTest
@testable import CursorCore

final class KineticCursorModelTests: XCTestCase {
    func testFirstSampleDoesNotRotateCursor() {
        var model = KineticCursorModel()

        let frame = model.update(
            position: CGPoint(x: 100, y: 100),
            timestamp: 1,
            enabled: true
        )

        XCTAssertEqual(frame.rotationRadians, 0, accuracy: 0.0001)
        XCTAssertEqual(frame.speed, 0, accuracy: 0.0001)
    }

    func testFastRightwardMotionTurnsCursorClockwise() {
        var model = KineticCursorModel()
        _ = model.update(position: .zero, timestamp: 1, enabled: true)

        let frame = model.update(
            position: CGPoint(x: 30, y: 0),
            timestamp: 1.01,
            enabled: true
        )

        XCTAssertLessThan(frame.rotationRadians, 0)
        XCTAssertGreaterThan(frame.speed, 35)
    }

    func testFastLeftwardMotionTurnsCursorCounterclockwise() {
        var model = KineticCursorModel()
        _ = model.update(position: CGPoint(x: 100, y: 0), timestamp: 1, enabled: true)

        let frame = model.update(
            position: CGPoint(x: 70, y: 0),
            timestamp: 1.01,
            enabled: true
        )

        XCTAssertGreaterThan(frame.rotationRadians, 0)
        XCTAssertGreaterThan(frame.speed, 35)
    }

    func testDisabledModeReturnsTowardNeutral() {
        var model = KineticCursorModel()
        _ = model.update(position: .zero, timestamp: 1, enabled: true)
        let moving = model.update(
            position: CGPoint(x: 40, y: 0),
            timestamp: 1.01,
            enabled: true
        )
        let returning = model.update(
            position: CGPoint(x: 40, y: 0),
            timestamp: 1.08,
            enabled: false
        )

        XCTAssertLessThan(abs(returning.rotationRadians), abs(moving.rotationRadians))
    }

    func testDuplicateTimestampNeverProducesInvalidValues() {
        var model = KineticCursorModel()
        _ = model.update(position: .zero, timestamp: 1, enabled: true)

        let frame = model.update(
            position: CGPoint(x: 200, y: 200),
            timestamp: 1,
            enabled: true
        )

        XCTAssertTrue(frame.rotationRadians.isFinite)
        XCTAssertTrue(frame.speed.isFinite)
    }

    func testInvalidSampleDoesNotPoisonFutureMotion() {
        var model = KineticCursorModel()
        _ = model.update(position: .zero, timestamp: 1, enabled: true)
        _ = model.update(
            position: CGPoint(x: .nan, y: 20),
            timestamp: .nan,
            enabled: true
        )

        let frame = model.update(
            position: CGPoint(x: 30, y: 0),
            timestamp: 1.01,
            enabled: true
        )

        XCTAssertTrue(frame.rotationRadians.isFinite)
        XCTAssertGreaterThan(frame.speed, 35)
    }

    func testLongGapResetsTeleportMotion() {
        var model = KineticCursorModel()
        _ = model.update(position: .zero, timestamp: 1, enabled: true)
        _ = model.update(position: CGPoint(x: 30, y: 0), timestamp: 1.01, enabled: true)

        let frame = model.update(
            position: CGPoint(x: 5_000, y: 5_000),
            timestamp: 2,
            enabled: true
        )

        XCTAssertEqual(frame.rotationRadians, 0, accuracy: 0.0001)
        XCTAssertEqual(frame.speed, 0, accuracy: 0.0001)
    }

    func testKineticTiltStaysSubtle() {
        var model = KineticCursorModel()
        _ = model.update(position: .zero, timestamp: 1, enabled: true)

        var frame = CursorMotionFrame(rotationRadians: 0, speed: 0)
        for index in 1...20 {
            frame = model.update(
                position: CGPoint(x: CGFloat(index * 30), y: 0),
                timestamp: 1 + Double(index) * 0.016,
                enabled: true
            )
        }

        XCTAssertLessThanOrEqual(abs(frame.rotationRadians), 20 * .pi / 180 + 0.0001)
    }

    func testResetClearsMotionState() {
        var model = KineticCursorModel()
        _ = model.update(position: .zero, timestamp: 1, enabled: true)
        _ = model.update(position: CGPoint(x: 40, y: 0), timestamp: 1.01, enabled: true)

        model.reset()

        XCTAssertEqual(model.rotationRadians, 0, accuracy: 0.0001)
        XCTAssertEqual(model.speed, 0, accuracy: 0.0001)
    }
}
