import XCTest
@testable import CursorCore

final class RingVisibilityModeTests: XCTestCase {
    func testNewInstallDefaultsToOnClick() {
        XCTAssertEqual(
            RingVisibilityMode.initial(
                storedRawValue: nil,
                legacyRingEnabled: nil
            ),
            .onClick
        )
    }

    func testStoredVisibilityWinsOverLegacyPreference() {
        XCTAssertEqual(
            RingVisibilityMode.initial(
                storedRawValue: RingVisibilityMode.onClick.rawValue,
                legacyRingEnabled: true
            ),
            .onClick
        )
    }

    func testLegacyPreferenceMigratesWithoutChangingUserChoice() {
        XCTAssertEqual(
            RingVisibilityMode.initial(
                storedRawValue: nil,
                legacyRingEnabled: true
            ),
            .always
        )
        XCTAssertEqual(
            RingVisibilityMode.initial(
                storedRawValue: nil,
                legacyRingEnabled: false
            ),
            .off
        )
    }

    func testAlwaysShowsPersistentRingAndClickFeedback() {
        XCTAssertTrue(RingVisibilityMode.always.showsPersistentRing)
        XCTAssertTrue(RingVisibilityMode.always.allowsClickFeedback)
        XCTAssertTrue(
            RingVisibilityMode.always.showsBaseRing(
                isClickAnimationActive: false
            )
        )
    }

    func testOnClickHidesPersistentRingButAllowsClickFeedback() {
        XCTAssertFalse(RingVisibilityMode.onClick.showsPersistentRing)
        XCTAssertTrue(RingVisibilityMode.onClick.allowsClickFeedback)
        XCTAssertFalse(
            RingVisibilityMode.onClick.showsBaseRing(
                isClickAnimationActive: false
            )
        )
        XCTAssertTrue(
            RingVisibilityMode.onClick.showsBaseRing(
                isClickAnimationActive: true
            )
        )
    }

    func testOffHidesPersistentRingAndClickFeedback() {
        XCTAssertFalse(RingVisibilityMode.off.showsPersistentRing)
        XCTAssertFalse(RingVisibilityMode.off.allowsClickFeedback)
        XCTAssertFalse(
            RingVisibilityMode.off.showsBaseRing(
                isClickAnimationActive: true
            )
        )
    }

    func testRawValuesRemainStableForSavedSettings() {
        XCTAssertEqual(RingVisibilityMode.always.rawValue, "always")
        XCTAssertEqual(RingVisibilityMode.onClick.rawValue, "onClick")
        XCTAssertEqual(RingVisibilityMode.off.rawValue, "off")
    }
}
