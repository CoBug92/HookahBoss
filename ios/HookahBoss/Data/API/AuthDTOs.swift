import Foundation

struct APISessionDTO: Codable, Equatable {
    let accessToken: String
    let expiresIn: Int
    let refreshToken: String
    let refreshExpiresIn: Int
    let accountId: UUID
}

struct AppleExchangeInput: Encodable {
    let identityToken: String
    let authorizationCode: String?
}

struct AccountDeletionDTO: Decodable, Equatable {
    let deleted: Bool
    let providerRevocation: String
}

struct RefreshInput: Encodable {
    let refreshToken: String
}
