import Foundation

@MainActor
final class CollectionViewModel: ObservableObject {
    @Published private(set) var isAuthenticated = false
    @Published private(set) var isAdmin = false
    @Published private(set) var favoriteMixIDs: Set<UUID> = []
    @Published private(set) var inventory: [InventoryItem] = []
    @Published private(set) var personalMixes: [PersonalMixRecord] = []
    @Published private(set) var catalogMixes: [MixPreview] = []
    @Published private(set) var products: [TobaccoProductDTO] = []
    @Published var expandedItemID: String?
    @Published var showSettings = false
    @Published var showAdmin = false
    @Published var confirmDelete = false
    @Published var showProviderUnavailable = false
    @Published var showAddInventory = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var didLogout = false
    private let service: any CollectionServing
    private var task: Task<Void, Never>?

    init(service: any CollectionServing) { self.service = service }
    deinit { task?.cancel() }
    var showsSignedOutPlaceholders: Bool { !isAuthenticated }
    var favoriteMixes: [MixPreview] { catalogMixes.filter { favoriteMixIDs.contains($0.id) } }

    func appear(locale: AppLocale = .currentApp) {
        guard task == nil else { return }
        task = Task { await initialize(locale: locale) }
    }
    func requestAccess(_ action: ProtectedAction, resume: @escaping () -> Void) { service.requestAccess(action, resume: resume) }
    func toggleExpanded(_ id: String) { expandedItemID = expandedItemID == id ? nil : id }
    func setLevel(_ level: InventoryLevel, itemID: String) {
        service.setInventoryLevel(level, itemID: itemID)
        if let index = inventory.firstIndex(where: { $0.id == itemID }) { inventory[index].level = level }
        expandedItemID = nil
    }
    func add(_ product: TobaccoProductDTO) {
        service.addInventoryProduct(product)
        if !inventory.contains(where: { $0.id == product.id.uuidString }) {
            inventory.append(.init(id: product.id.uuidString, brand: product.brandName, line: product.lineName,
                                   flavor: product.name, level: .plenty, flavorProfiles: product.tags.map(\.profile)))
        }
    }
    func deletePrivate(_ item: InventoryItem) { service.deletePrivateProduct(item); inventory.removeAll { $0.id == item.id } }
    func createPrivate(brand: String, line: String?, flavor: String, profiles: [String], completion: @escaping (Bool) -> Void) {
        Task {
            let succeeded = await service.createPrivateProduct(brand: brand, line: line, flavor: flavor, profiles: profiles)
            if succeeded { await refresh() } else { errorMessage = L10n.Content.Error.network }
            completion(succeeded)
        }
    }
    func logout() { Task { await service.logout(); didLogout = true; isAuthenticated = false } }
    func deleteAccount() {
        Task { do { showProviderUnavailable = try await service.deleteAccount(); isAuthenticated = false }
            catch { errorMessage = L10n.Content.Error.network } }
    }
    func clearError() { errorMessage = nil }

    private func initialize(locale: AppLocale) async { apply(await service.snapshot(locale: locale)); task = nil }
    private func refresh() async { apply(await service.snapshot(locale: .currentApp)) }
    private func apply(_ value: CollectionSnapshot) {
        isAuthenticated = value.isAuthenticated; isAdmin = value.isAdmin; favoriteMixIDs = value.favoriteMixIDs
        inventory = value.inventory; personalMixes = value.personalMixes; catalogMixes = value.catalogMixes; products = value.products
    }
}
