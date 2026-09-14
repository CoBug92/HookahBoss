import Foundation

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
