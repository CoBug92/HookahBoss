import XCTest
@testable import HookahBoss

@MainActor final class AppNavigationTests:XCTestCase {
    func testMixFinderSelectsMixes(){let navigation=AppNavigation();navigation.openMixFinder();XCTAssertEqual(navigation.tab,.mixes)}
    func testInventoryActionSelectsMyAndRequestsResults(){let navigation=AppNavigation();navigation.openInventoryResults();XCTAssertEqual(navigation.tab,.collection);XCTAssertEqual(navigation.collectionPath,[.inventoryResults])}
    func testCollectionResumeReplacesStalePathWithRequestedSection(){let navigation=AppNavigation();navigation.collectionPath=[.inventory];navigation.openCollection(.favorites);XCTAssertEqual(navigation.tab,.collection);XCTAssertEqual(navigation.collectionPath,[.favorites])}
    func testSuccessfulAuthGateResumesRequestedCollectionDestinationOnce(){let gate=AuthGate();let navigation=AppNavigation();gate.request(.personal){navigation.openCollection(.personal)};gate.begin();gate.succeed();XCTAssertEqual(navigation.collectionPath,[.personal]);navigation.collectionPath=[];gate.succeed();XCTAssertTrue(navigation.collectionPath.isEmpty)}
}
