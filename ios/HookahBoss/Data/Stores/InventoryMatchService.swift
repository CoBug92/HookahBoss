import Foundation

@MainActor
final class InventoryMatchService: InventoryMatchServing {
    private let accountID: UUID
    private let client: APIClient

    init(accountID: UUID, client: APIClient) { self.accountID = accountID; self.client = client }

    func matches(locale: AppLocale) async throws -> [InventoryMatchDTO] {
        do {
            let matches = try await client.inventoryMatches(locale: locale)
            InventoryMatchCache.save(matches, accountId: accountID)
            return matches
        } catch {
            if let cached = InventoryMatchCache.load(accountId: accountID) { return cached }
            throw error
        }
    }
}
