import Foundation

@MainActor
final class CollectionService: CollectionServing {
    private let auth: AuthRuntime
    private let content: PublicContentStore
    private let inventory: InventoryStore?
    private let personalMixes: PersonalMixStore?

    init(auth: AuthRuntime, content: PublicContentStore, inventory: InventoryStore?, personalMixes: PersonalMixStore?) {
        self.auth = auth; self.content = content; self.inventory = inventory; self.personalMixes = personalMixes
    }

    func snapshot(locale: AppLocale) async -> CollectionSnapshot {
        await content.load(locale: locale)
        if let inventory { await inventory.configure(client: auth.authorizedClient, products: content.products) }
        if let personalMixes { await personalMixes.configure(client: auth.authorizedClient) }
        return CollectionSnapshot(isAuthenticated: auth.isAuthenticated, isAdmin: auth.isAdmin,
            favoriteMixIDs: auth.favoriteMixIDs, inventory: inventory?.items ?? [], personalMixes: personalMixes?.mixes ?? [],
            catalogMixes: content.mixes, products: content.products)
    }

    func requestAccess(_ action: ProtectedAction, resume: @escaping () -> Void) { auth.authorize(action, resume: resume) }
    func setInventoryLevel(_ level: InventoryLevel, itemID: String) { inventory?.setLevel(level, for: itemID) }
    func addInventoryProduct(_ product: TobaccoProductDTO) { inventory?.add(product) }
    func createPrivateProduct(brand: String, line: String?, flavor: String, profiles: [String]) async -> Bool {
        await inventory?.createPrivate(brand: brand, line: line, flavor: flavor, profiles: profiles) ?? false
    }
    func deletePrivateProduct(_ item: InventoryItem) { inventory?.deletePrivate(item) }
    func logout() async { await auth.logout() }
    func deleteAccount() async throws -> Bool { try await auth.deleteAccount() }
}
