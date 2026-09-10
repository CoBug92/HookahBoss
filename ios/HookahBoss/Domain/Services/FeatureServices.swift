import Foundation

enum AdminEntryVisibility {
    static func isVisible(isAuthenticated: Bool, isAdmin: Bool) -> Bool { isAuthenticated && isAdmin }
}

enum AppLocale: String, Sendable {
    case ru
    case en

    static var current: AppLocale {
        Foundation.Locale.current.language.languageCode?.identifier == "en" ? .en : .ru
    }

    static var currentApp: AppLocale { current }
}

@MainActor
protocol MixContentServing: AnyObject {
    func cachedMixDetail(_ id: UUID, locale: AppLocale) async -> MixPreview?
    func mixDetail(_ id: UUID, locale: AppLocale) async throws -> MixPreview
}

struct PublicCatalogSnapshot: Sendable {
    let mixes: [MixPreview]
    let articles: [ArticleDTO]
}

@MainActor
protocol PublicCatalogServing: AnyObject {
    func catalog(locale: AppLocale, force: Bool) async -> PublicCatalogSnapshot
    func articleDetail(_ id: String, locale: AppLocale) async throws -> ArticleDetailDTO
}

@MainActor
protocol AuthLibraryServing: AnyObject {
    var isAuthenticated: Bool { get }
    var favoriteMixIDs: Set<UUID> { get }
    var ratings: [UUID: Int] { get }
    var bookmarkedArticleSlugs: Set<String> { get }
    var libraryError: String? { get set }
    func authorize(_ action: ProtectedAction, resume: @escaping () -> Void)
    func setFavorite(_ enabled: Bool, mixId: UUID) async
    func setRating(_ score: Int?, mixId: UUID) async
    func setArticleBookmark(_ enabled: Bool, slug: String) async
}

@MainActor
protocol InventoryRemoteServing {
    func inventory() async throws -> [InventoryItemDTO]
    func upsertInventory(_ input: InventoryUpsert) async throws -> InventoryItemDTO
    func createPrivateProduct(_ input: PrivateProductWrite) async throws -> PrivateProductDTO
    func deletePrivateProduct(id: UUID) async throws
}

@MainActor
protocol AdminServing {
    func adminList(_ resource: AdminResource) async throws -> [AdminRecord]
    func adminCreate(_ resource: AdminResource, body: [String: JSONValue]) async throws -> AdminRecord
    func adminUpdate(_ resource: AdminResource, id: String, body: [String: JSONValue]) async throws -> AdminRecord
    func adminDelete(_ resource: AdminResource, id: String, body: [String: JSONValue]?) async throws
}

struct CreateMixProduct: Equatable, Sendable {
    let source: ComponentSource
    let sourceID: String
    let brand: String?
    let line: String?
    let flavor: String
    let flavorProfiles: [String]
}

struct CreateMixOptionSnapshot: Equatable, Sendable {
    let catalog: [CreateMixProduct]
    let personal: [CreateMixProduct]
    let inventory: [CreateMixProduct]
}

@MainActor
protocol CreateMixServing: AnyObject {
    func loadOptions(locale: AppLocale) async throws -> CreateMixOptionSnapshot
    func save(_ mix: PersonalMixRecord) async throws
}

@MainActor
protocol InventoryMatchServing: AnyObject {
    func matches(locale: AppLocale) async throws -> [InventoryMatchDTO]
}

struct CollectionSnapshot {
    let isAuthenticated: Bool
    let isAdmin: Bool
    let favoriteMixIDs: Set<UUID>
    let inventory: [InventoryItem]
    let personalMixes: [PersonalMixRecord]
    let catalogMixes: [MixPreview]
    let products: [TobaccoProductDTO]
}

@MainActor
protocol CollectionServing: AnyObject {
    func snapshot(locale: AppLocale) async -> CollectionSnapshot
    func requestAccess(_ action: ProtectedAction, resume: @escaping () -> Void)
    func setInventoryLevel(_ level: InventoryLevel, itemID: String)
    func addInventoryProduct(_ product: TobaccoProductDTO)
    func createPrivateProduct(brand: String, line: String?, flavor: String, profiles: [String]) async -> Bool
    func deletePrivateProduct(_ item: InventoryItem)
    func logout() async
    func deleteAccount() async throws -> Bool
}

protocol KeyValueStoring: AnyObject {
    func data(forKey defaultName: String) -> Data?
    func set(_ value: Any?, forKey defaultName: String)
}
