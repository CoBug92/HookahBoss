import Foundation

@MainActor
final class AccountWorkspace: ObservableObject {

    struct Stores {
        let accountId: UUID
        let personalMixes: PersonalMixStore
        let inventory: InventoryStore
    }

    // MARK: - Observable properties

    @Published private(set) var current: Stores?

    // MARK: - Public methods

    func activate(accountId: UUID?, defaults: UserDefaults = .standard) {
        AccountCache.discardLegacy(defaults: defaults)

        guard let accountId else {
            current = nil
            return
        }
        guard current?.accountId != accountId else {
            return
        }

        current = Stores(
            accountId: accountId,
            personalMixes: PersonalMixStore(
                defaults: defaults,
                accountId: accountId
            ),
            inventory: InventoryStore(
                defaults: defaults,
                accountId: accountId
            )
        )
    }
}
