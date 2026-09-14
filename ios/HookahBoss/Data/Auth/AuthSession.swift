import Foundation

struct AuthSession: Codable, Equatable, Sendable {
    let accessToken: String
    let expiresAt: Date
    let refreshToken: String
    let refreshExpiresAt: Date
    let accountId: UUID

    var isValid: Bool {
        expiresAt > Date().addingTimeInterval(30)
    }
}

/// Хранит аутентификационную сессию вне presentation-слоя.
protocol AuthSessionStorage: Sendable {
    /// Загружает сохранённую сессию или `nil`, если пользователь не входил.
    func load() async throws -> AuthSession?

    /// Атомарно сохраняет актуальную сессию.
    func save(_ session: AuthSession) async throws

    /// Удаляет сохранённую сессию.
    func clear() async throws
}
