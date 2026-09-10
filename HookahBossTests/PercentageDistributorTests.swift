import XCTest
@testable import HookahBoss

final class PercentageDistributorTests: XCTestCase {
    func testAllEmptyPercentagesMaterializeDeterministicEqualShare() {
        XCTAssertEqual(PercentageDistributor.validate([nil, nil, nil]), .valid(effective: [34, 33, 33], automatic: [0, 1, 2]))
    }

    func testRemainderIsDistributedEquallyAcrossEmptyComponents() {
        XCTAssertEqual(PercentageDistributor.validate([40, nil, nil]), .valid(effective: [40, 30, 30], automatic: [1, 2]))
    }

    func testRoundingRemainderKeepsTotalAtOneHundred() {
        XCTAssertEqual(PercentageDistributor.validate([33, nil, nil]), .valid(effective: [33, 34, 33], automatic: [1, 2]))
    }

    func testEnteredTotalAboveOneHundredIsRejected() {
        XCTAssertEqual(PercentageDistributor.validate([70, 40, nil]), .exceeds100)
    }

    func testFullyEnteredPercentagesMustTotalOneHundred() {
        XCTAssertEqual(PercentageDistributor.validate([40, 40]), .percentagesMustTotal100)
        XCTAssertEqual(PercentageDistributor.validate([40, 60]), .valid(effective: [40, 60], automatic: []))
    }

    func testAtLeastOneComponentIsRequired() {
        XCTAssertEqual(PercentageDistributor.validate([]), .noComponents)
    }
}
