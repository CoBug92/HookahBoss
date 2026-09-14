import Foundation

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

    var domainIngredients: [MixIngredient] {
        components.map {
            MixIngredient(
                id: $0.productId,
                brand: $0.brand,
                line: $0.line,
                flavor: $0.flavor,
                percentage: $0.percentage
            )
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
