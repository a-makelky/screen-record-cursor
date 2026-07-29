import CoreGraphics
import XCTest
@testable import CursorCore

final class KineticResponseTests: XCTestCase {
    func testRawValuesRemainStableForSavedSettings() {
        XCTAssertEqual(KineticResponse.smooth.rawValue, "smooth")
        XCTAssertEqual(KineticResponse.balanced.rawValue, "balanced")
        XCTAssertEqual(KineticResponse.quick.rawValue, "quick")
    }

    func testSmoothRespondsMoreGentlyThanQuick() {
        var smooth = KineticCursorModel(
            configuration: KineticResponse.smooth.configuration
        )
        var quick = KineticCursorModel(
            configuration: KineticResponse.quick.configuration
        )

        _ = smooth.update(position: .zero, timestamp: 1, enabled: true)
        _ = quick.update(position: .zero, timestamp: 1, enabled: true)

        let position = CGPoint(x: 18, y: 0)
        let smoothFrame = smooth.update(
            position: position,
            timestamp: 1.016,
            enabled: true
        )
        let quickFrame = quick.update(
            position: position,
            timestamp: 1.016,
            enabled: true
        )

        XCTAssertLessThan(
            abs(smoothFrame.rotationRadians),
            abs(quickFrame.rotationRadians)
        )
    }

    func testAllResponsesReturnTowardNeutralWhenDisabled() {
        for response in KineticResponse.allCases {
            var model = KineticCursorModel(configuration: response.configuration)
            _ = model.update(position: .zero, timestamp: 1, enabled: true)
            let moving = model.update(
                position: CGPoint(x: 40, y: 0),
                timestamp: 1.016,
                enabled: true
            )
            let returning = model.update(
                position: CGPoint(x: 40, y: 0),
                timestamp: 1.08,
                enabled: false
            )

            XCTAssertLessThan(
                abs(returning.rotationRadians),
                abs(moving.rotationRadians),
                "\(response.rawValue) should return toward neutral"
            )
        }
    }
}
