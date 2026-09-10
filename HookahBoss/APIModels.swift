import Foundation

struct APIEnvelope<Value: Decodable>: Decodable { let data: Value }
struct CursorPaginationDTO:Decodable,Equatable{let nextCursor:String?;let hasMore:Bool}
struct CursorPageEnvelope<Value:Decodable>:Decodable{let data:Value;let pagination:CursorPaginationDTO}
struct APISessionDTO: Codable, Equatable { let accessToken: String; let expiresIn: Int; let refreshToken: String; let refreshExpiresIn: Int; let accountId: UUID }
struct AppleExchangeInput: Encodable { let identityToken: String; let authorizationCode:String? }
struct AccountDeletionDTO:Decodable,Equatable{let deleted:Bool;let providerRevocation:String}
struct RefreshInput: Encodable { let refreshToken: String }

struct BrandDTO: Codable, Equatable {
    let id: UUID
    let slug: String
    let name: String
    let lines: [TobaccoLineDTO]
}

struct TobaccoLineDTO: Codable, Equatable {
    let id: UUID
    let slug: String
    let name: String
    let strength: String
}

struct FlavorTagDTO: Codable, Equatable {
    let id: UUID
    let slug: String
    let name: String
    let profile: String
    let weight: Int
}

struct TobaccoProductDTO: Codable, Equatable, Identifiable {
    let id: UUID
    let slug: String
    let name: String
    let description: String?
    let translationOrigin: String?
    let sourceConfidence: String?
    let sweetness: String
    let acidity: String
    let freshness: String
    let lineId: UUID
    let lineName: String
    let strength: String
    let brandId: UUID
    let brandName: String
    let tags: [FlavorTagDTO]
}

struct OfficialMixDTO: Codable, Equatable, Identifiable {
    let id: UUID
    let slug: String
    let title: String
    let summary: String?
    let rating: Double?
    let ratingsCount: Int
    let components: [OfficialMixComponentDTO]
    let tags: [String]
    let profiles: [String]
    let sweetness: String
    let acidity: String
    let freshness: String
    let strength: String
}

struct OfficialMixDetailDTO: Codable, Equatable {
    let id: UUID
    let slug: String
    let title: String
    let summary:String?
    let rating: Double?
    let ratingsCount: Int
    let components: [OfficialMixComponentDTO]
    let tags:[String]
    let profiles:[String]
    let sweetness:String
    let acidity:String
    let freshness:String
    let strength:String

    var domainIngredients: [MixIngredient] {
        components.map {
            MixIngredient(id: $0.productId, brand: $0.brand, line: $0.line, flavor: $0.flavor, percentage: $0.percentage)
        }
    }
}

struct OfficialMixComponentDTO: Codable, Equatable {
    let productId: UUID
    let brand: String
    let line: String?
    let flavor: String
    let percentage: Int
    let position: Int
}

struct ArticleDTO: Codable, Equatable, Hashable, Identifiable {
    let id: UUID
    let slug: String
    let title: String
    let summary: String
    let category: String
    let readingMinutes: Int
}

struct ArticleSectionDTO: Codable, Equatable, Hashable {
    let heading: String
    let body: String
}

struct ArticleDetailDTO: Codable, Equatable, Hashable {
    let id: UUID
    let slug: String
    let title: String
    let summary: String
    let sections: [ArticleSectionDTO]
    let category: String
    let readingMinutes: Int
    let related: [ArticleDTO]
}

struct RatingDTO: Codable, Equatable { let mixId: UUID; let score: Int; let updatedAt: String }
struct FavoriteDTO: Codable, Equatable { let mixId: UUID; let createdAt: String }
struct LibrarySnapshotDTO: Codable, Equatable {
    let favorites: [FavoriteDTO]
    let ratings: [RatingDTO]
    let inventory: [InventoryItemDTO]
    let personalMixes: [PersonalMixSummaryDTO]
    let articleBookmarks: [String]
}
struct PrivateProductDTO:Codable,Equatable,Identifiable { let id:UUID;let brandName:String;let lineName:String?;let flavorName:String;let flavorProfiles:[String];let createdAt:String }
struct PrivateProductWrite:Codable,Equatable { let clientId:UUID?;let brandName:String;let lineName:String?;let flavorName:String;let flavorProfiles:[String];init(clientId:UUID?=nil,brandName:String,lineName:String?,flavorName:String,flavorProfiles:[String]){self.clientId=clientId;self.brandName=brandName;self.lineName=lineName;self.flavorName=flavorName;self.flavorProfiles=flavorProfiles} }
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

struct PersonalMixSummaryDTO: Codable, Equatable {
    let id: UUID
    let title: String?
    let score: Int?
    let comment: String?
    let createdAt: String
    let updatedAt: String
    let componentCount: Int
    let isApproximate: Bool?
}

struct PersonalMixDetailDTO: Codable, Equatable {
    let id: UUID
    let title: String?
    let score: Int?
    let comment: String?
    let createdAt: String?
    let updatedAt: String?
    let isApproximate: Bool?
    let components: [PersonalMixComponentDTO]
}

struct PersonalMixComponentDTO: Codable, Equatable {
    let id: UUID?
    let productId: UUID?
    let privateProductId: UUID?
    let freeformName: String?
    let percentage: Int?
    let position: Int
    let brandName: String?
    let lineName: String?
    let flavorName: String?
    let flavorProfiles: [String]?
}

struct InventoryUpsert: Encodable, Equatable {
    let productId: UUID?
    let privateProductId: UUID?
    let level: String
}

struct PersonalMixWrite: Encodable, Equatable {
    let clientId: UUID?
    let title: String?
    let score: Int?
    let comment: String?
    let isApproximate: Bool
    let components: [PersonalMixComponentWrite]
    init(clientId:UUID?=nil,title:String?,score:Int?,comment:String?,isApproximate:Bool=false,components:[PersonalMixComponentWrite]){self.clientId=clientId;self.title=title;self.score=score;self.comment=comment;self.isApproximate=isApproximate;self.components=components}
}

struct PersonalMixComponentWrite: Encodable, Equatable {
    let productId: UUID?
    let privateProductId: UUID?
    let freeformName: String?
    let percentage: Int?
}
