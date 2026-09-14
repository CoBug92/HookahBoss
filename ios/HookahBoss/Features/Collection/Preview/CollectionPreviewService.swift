import Foundation

@MainActor
final class CollectionPreviewService: CollectionServing {
    private let value: CollectionSnapshot
    private let delay: Duration?

    init(delay: Duration? = nil) {
        value = CollectionPreviewData.signedOut
        self.delay = delay
    }

    init(value: CollectionSnapshot, delay: Duration? = nil) {
        self.value = value
        self.delay = delay
    }

    func snapshot(locale: AppLocale) async -> CollectionSnapshot {
        if let delay {
            try? await Task.sleep(for: delay)
        }
        return value
    }

    func requestAccess(_ action: ProtectedAction, resume: @escaping () -> Void) {}
    func setInventoryLevel(_ level: InventoryLevel, itemID: String) {}
    func addInventoryProduct(_ product: TobaccoProductDTO) {}

    func createPrivateProduct(brand: String, line: String?, flavor: String, profiles: [String]) async -> Bool {
        false
    }

    func deletePrivateProduct(_ item: InventoryItem) {}
    func logout() async {}

    func deleteAccount() async throws -> Bool {
        false
    }
}
