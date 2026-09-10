import Foundation

enum CreateMixServiceError: Error {
    case saveRejected
}

@MainActor
final class CreateMixService: CreateMixServing {
    private let content: PublicContentStore
    private let inventory: InventoryStore
    private let personalMixes: PersonalMixStore
    private let client: APIClient?

    init(content: PublicContentStore, inventory: InventoryStore, personalMixes: PersonalMixStore, client: APIClient?) {
        self.content = content
        self.inventory = inventory
        self.personalMixes = personalMixes
        self.client = client
    }

    func loadOptions(locale: AppLocale) async throws -> CreateMixOptionSnapshot {
        await content.load(locale: locale)
        let catalog = content.products.map {
            CreateMixProduct(source: .catalog, sourceID: $0.id.uuidString, brand: $0.brandName,
                             line: $0.lineName, flavor: $0.name, flavorProfiles: $0.tags.map(\.profile))
        }
        let cachedPersonal = inventory.items.filter { $0.id.hasPrefix("private:") }.map(Self.product)
        let remotePersonal: [CreateMixProduct]
        if let client {
            remotePersonal = try await client.privateProducts().map {
                CreateMixProduct(source: .personal, sourceID: "private:\($0.id.uuidString)",
                                 brand: $0.brandName, line: $0.lineName, flavor: $0.flavorName,
                                 flavorProfiles: $0.flavorProfiles)
            }
        } else {
            remotePersonal = []
        }
        let personal = Dictionary((cachedPersonal + remotePersonal).map { ($0.sourceID, $0) },
                                  uniquingKeysWith: { _, remote in remote }).values
            .sorted { $0.flavor.localizedCaseInsensitiveCompare($1.flavor) == .orderedAscending }
        let availableInventory = inventory.items.filter { $0.level != .empty }.map {
            let item = Self.product($0)
            return CreateMixProduct(source: .inventory, sourceID: item.sourceID, brand: item.brand,
                                    line: item.line, flavor: item.flavor, flavorProfiles: item.flavorProfiles)
        }
        return CreateMixOptionSnapshot(catalog: catalog, personal: personal, inventory: availableInventory)
    }

    func save(_ mix: PersonalMixRecord) async throws {
        await personalMixes.configure(client: client)
        guard await personalMixes.addSynced(mix) else { throw CreateMixServiceError.saveRejected }
    }

    private static func product(_ item: InventoryItem) -> CreateMixProduct {
        CreateMixProduct(source: .personal, sourceID: item.id, brand: item.brand, line: item.line,
                         flavor: item.flavor, flavorProfiles: item.flavorProfiles ?? [])
    }
}
