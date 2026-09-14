import Foundation

enum CollectionPreviewData {
    static let inventory = [
        InventoryItem(
            id: "preview-mango",
            brand: "DARKSIDE",
            line: "Core",
            flavor: "Mango",
            level: .plenty,
            flavorProfiles: ["fruit"]
        ),
        InventoryItem(
            id: "private:preview-lime",
            brand: "Personal",
            line: nil,
            flavor: "Lime",
            level: .low,
            flavorProfiles: ["citrus"]
        ),
    ]

    static let personalMixes = PersonalMixPreviewData.collection

    static let signedOut = CollectionSnapshot(
        isAuthenticated: false,
        isAdmin: false,
        favoriteMixIDs: [],
        inventory: [],
        personalMixes: [],
        catalogMixes: [],
        products: TobaccoProductPreviewData.catalog
    )

    static let content = CollectionSnapshot(
        isAuthenticated: true,
        isAdmin: false,
        favoriteMixIDs: [MixesPreviewData.featured.id],
        inventory: inventory,
        personalMixes: personalMixes,
        catalogMixes: MixesPreviewData.catalog,
        products: TobaccoProductPreviewData.catalog
    )

    static let admin = CollectionSnapshot(
        isAuthenticated: true,
        isAdmin: true,
        favoriteMixIDs: [MixesPreviewData.featured.id],
        inventory: inventory,
        personalMixes: personalMixes,
        catalogMixes: MixesPreviewData.catalog,
        products: TobaccoProductPreviewData.catalog
    )
}
