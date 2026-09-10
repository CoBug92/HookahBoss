import XCTest
@testable import HookahBoss

@MainActor
final class CollectionViewModelTests: XCTestCase {
    func testAnonymousSnapshotKeepsPlaceholdersVisible() async {
        let service = CollectionServiceSpy(snapshot: snapshot(authenticated: false))
        let model = CollectionViewModel(service: service)
        model.appear(locale: .en); await waitUntil { service.snapshotCalls == 1 }
        XCTAssertTrue(model.showsSignedOutPlaceholders)
    }

    func testAuthenticatedInitializationPublishesInventory() async {
        let item = InventoryItem(id: UUID().uuidString, brand: "Brand", line: nil, flavor: "Pear", level: .low)
        let service = CollectionServiceSpy(snapshot: snapshot(authenticated: true, inventory: [item]))
        let model = CollectionViewModel(service: service)
        model.appear(locale: .ru); await waitUntil { model.inventory.count == 1 }
        XCTAssertEqual(model.inventory.first?.flavor, "Pear")
        XCTAssertEqual(service.locales, [.ru])
    }

    func testInventoryMutationUpdatesPresentationAndService() {
        let item = InventoryItem(id: "item", brand: "Brand", line: nil, flavor: "Pear", level: .low)
        let service = CollectionServiceSpy(snapshot: snapshot(authenticated: true, inventory: [item]))
        let model = CollectionViewModel(service: service)
        model.setLevel(.plenty, itemID: item.id)
        XCTAssertEqual(service.levelUpdate?.0, .plenty)
        XCTAssertEqual(service.levelUpdate?.1, "item")
    }

    func testLogoutAndDeleteErrorAreOwnedByViewModel() async {
        let service = CollectionServiceSpy(snapshot: snapshot(authenticated: true)); service.deleteError = TestDeleteError.expected
        let model = CollectionViewModel(service: service)
        model.logout(); await waitUntil { model.didLogout }
        model.deleteAccount(); await waitUntil { model.errorMessage != nil }
        XCTAssertEqual(service.logoutCalls, 1)
        XCTAssertNotNil(model.errorMessage)
    }

    private func snapshot(authenticated: Bool, inventory: [InventoryItem] = []) -> CollectionSnapshot {
        CollectionSnapshot(isAuthenticated: authenticated, isAdmin: false, favoriteMixIDs: [], inventory: inventory,
                           personalMixes: [], catalogMixes: [], products: [])
    }
    private func waitUntil(_ condition: @escaping @MainActor () -> Bool) async { for _ in 0..<100 where !condition() { await Task.yield() } }
}

private enum TestDeleteError: Error { case expected }
@MainActor
private final class CollectionServiceSpy: CollectionServing {
    let value: CollectionSnapshot
    var deleteError: Error?
    private(set) var snapshotCalls = 0; private(set) var locales: [AppLocale] = []
    private(set) var levelUpdate: (InventoryLevel, String)?; private(set) var logoutCalls = 0
    init(snapshot: CollectionSnapshot) { value = snapshot }
    func snapshot(locale: AppLocale) async -> CollectionSnapshot { snapshotCalls += 1; locales.append(locale); return value }
    func requestAccess(_ action: ProtectedAction, resume: @escaping () -> Void) { resume() }
    func setInventoryLevel(_ level: InventoryLevel, itemID: String) { levelUpdate = (level, itemID) }
    func addInventoryProduct(_ product: TobaccoProductDTO) {}
    func createPrivateProduct(brand: String, line: String?, flavor: String, profiles: [String]) async -> Bool { true }
    func deletePrivateProduct(_ item: InventoryItem) {}
    func logout() async { logoutCalls += 1 }
    func deleteAccount() async throws -> Bool { if let deleteError { throw deleteError }; return false }
}
