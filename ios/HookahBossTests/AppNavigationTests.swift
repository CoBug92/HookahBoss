import XCTest
@testable import HookahBoss

@MainActor final class AppNavigationTests:XCTestCase {
    func testMixFinderSelectsMixes(){let navigation=AppNavigation();navigation.openMixFinder();XCTAssertEqual(navigation.tab,.mixes)}
    func testInventoryActionSelectsMyAndRequestsResults(){let navigation=AppNavigation();navigation.openInventoryResults();XCTAssertEqual(navigation.tab,.collection);XCTAssertEqual(navigation.collectionDestination,.inventoryResults)}
}
