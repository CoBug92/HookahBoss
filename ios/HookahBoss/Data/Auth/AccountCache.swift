import Foundation

enum AccountCache {
    static func key(_ base: String, accountId: UUID) -> String {
        "account.\(accountId.uuidString).\(base)"
    }

    static func purge(accountId: UUID, defaults: UserDefaults = .standard) {
        for base in [
            "inventory.v1",
            "inventory.matches.v1",
            "personal.mixes.v1",
            "library.v1",
            "library.outbox.v1",
            "bookmark.outbox.v1",
            "inventory.outbox.v1",
            "private.outbox.v1",
            "personal.outbox.v1",
        ] {
            defaults.removeObject(forKey: key(base, accountId: accountId))
        }
    }

    static func discardLegacy(defaults: UserDefaults = .standard) {
        guard !defaults.bool(forKey: "account.cache.legacyDiscarded") else { return }
        defaults.removeObject(forKey: "inventory.sample.v1")
        defaults.removeObject(forKey: "personal.mixes.v1")
        defaults.set(true, forKey: "account.cache.legacyDiscarded")
    }
}
