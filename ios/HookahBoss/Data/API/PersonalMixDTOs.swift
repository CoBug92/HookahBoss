import Foundation

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

struct PersonalMixWrite: Encodable, Equatable {
    let clientId: UUID?
    let title: String?
    let score: Int?
    let comment: String?
    let isApproximate: Bool
    let components: [PersonalMixComponentWrite]

    init(
        clientId: UUID? = nil,
        title: String?,
        score: Int?,
        comment: String?,
        isApproximate: Bool = false,
        components: [PersonalMixComponentWrite]
    ) {
        self.clientId = clientId
        self.title = title
        self.score = score
        self.comment = comment
        self.isApproximate = isApproximate
        self.components = components
    }
}

struct PersonalMixComponentWrite: Encodable, Equatable {
    let productId: UUID?
    let privateProductId: UUID?
    let freeformName: String?
    let percentage: Int?
}
