import Foundation

struct CollectionSnapshot {
    let isAuthenticated: Bool
    let isAdmin: Bool
    let favoriteMixIDs: Set<UUID>
    let inventory: [InventoryItem]
    let personalMixes: [PersonalMixRecord]
    let catalogMixes: [MixPreview]
    let products: [TobaccoProductDTO]
}
