import Foundation

extension UserDefaults: KeyValueStoring {}

enum InventoryMatchCache {
    private static let baseKey = "inventory.matches.v1"

    static func save(_ matches: [InventoryMatchDTO], accountId: UUID, defaults: UserDefaults = .standard) {
        defaults.set(try? JSONEncoder().encode(matches), forKey: AccountCache.key(baseKey, accountId: accountId))
    }

    static func load(accountId: UUID, defaults: UserDefaults = .standard) -> [InventoryMatchDTO]? {
        guard let data = defaults.data(forKey: AccountCache.key(baseKey, accountId: accountId)) else { return nil }
        return try? JSONDecoder().decode([InventoryMatchDTO].self, from: data)
    }
}
