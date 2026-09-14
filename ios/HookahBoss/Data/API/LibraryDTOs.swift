import Foundation

struct RatingDTO: Codable, Equatable {
    let mixId: UUID
    let score: Int
    let updatedAt: String
}

struct FavoriteDTO: Codable, Equatable {
    let mixId: UUID
    let createdAt: String
}

struct LibrarySnapshotDTO: Codable, Equatable {
    let favorites: [FavoriteDTO]
    let ratings: [RatingDTO]
    let inventory: [InventoryItemDTO]
    let personalMixes: [PersonalMixSummaryDTO]
    let articleBookmarks: [String]
}

struct PrivateProductDTO: Codable, Equatable, Identifiable {
    let id: UUID
    let brandName: String
    let lineName: String?
    let flavorName: String
    let flavorProfiles: [String]
    let createdAt: String
}

struct PrivateProductWrite: Codable, Equatable {
    let clientId: UUID?
    let brandName: String
    let lineName: String?
    let flavorName: String
    let flavorProfiles: [String]

    init(
        clientId: UUID? = nil,
        brandName: String,
        lineName: String?,
        flavorName: String,
        flavorProfiles: [String]
    ) {
        self.clientId = clientId
        self.brandName = brandName
        self.lineName = lineName
        self.flavorName = flavorName
        self.flavorProfiles = flavorProfiles
    }
}

struct InventoryMatchDTO: Codable, Equatable {
    let mixId: UUID
    let kind: String
    let missingFlavor: String?
    let sourceProductId: UUID?
    let substituteProductId: UUID?
}

struct InventoryItemDTO: Codable, Equatable {
    let id: UUID
    let level: String
    let productId: UUID?
    let privateProductId: UUID?
    let flavorName: String?
    let brandName: String?
    let lineName: String?
    let updatedAt: String
}

struct InventoryUpsert: Encodable, Equatable {
    let productId: UUID?
    let privateProductId: UUID?
    let level: String
}
