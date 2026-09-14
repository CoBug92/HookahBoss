import Foundation

actor AuthService: AccessTokenProvider {
    private let storage: any AuthSessionStorage
    private let exchange: @Sendable (String) async throws -> APISessionDTO
    private let refresh: @Sendable (String) async throws -> APISessionDTO
    private var refreshTask: Task<AuthSession, Error>?

    init(
        storage: any AuthSessionStorage = KeychainAuthSessionStorage(),
        exchange: @escaping @Sendable (String) async throws -> APISessionDTO,
        refresh: @escaping @Sendable (String) async throws -> APISessionDTO
    ) {
        self.storage = storage
        self.exchange = exchange
        self.refresh = refresh
    }

    func accessToken(afterRejectedToken rejected: String? = nil) async throws -> String {
        if let refreshTask { return try await refreshTask.value.accessToken }
        guard var session = try await storage.load(), session.refreshExpiresAt > Date() else {
            try await storage.clear()
            throw AuthTokenError.signedOut
        }
        if session.isValid, rejected == nil || rejected != session.accessToken {
            return session.accessToken
        }
        if let refreshTask {
            return try await refreshTask.value.accessToken
        }

        let token = session.refreshToken
        let refresh = self.refresh
        let storage = self.storage
        let task = Task<AuthSession, Error> {
            let dto = try await refresh(token)
            let renewed = Self.session(dto)
            try await storage.save(renewed)
            return renewed
        }
        refreshTask = task
        do {
            session = try await task.value
            refreshTask = nil
            return session.accessToken
        } catch {
            refreshTask = nil
            throw error
        }
    }

    func authenticate(identityToken: String) async throws {
        let dto = try await exchange(identityToken)
        try await storage.save(Self.session(dto))
    }

    func store(_ dto: APISessionDTO) async throws {
        try await storage.save(Self.session(dto))
    }

    func signOut() async throws {
        try await storage.clear()
    }

    func accountId() async throws -> UUID {
        guard let session = try await storage.load() else {
            throw AuthTokenError.signedOut
        }
        return session.accountId
    }

    private static func session(_ dto: APISessionDTO) -> AuthSession {
        .init(
            accessToken: dto.accessToken,
            expiresAt: Date().addingTimeInterval(TimeInterval(dto.expiresIn)),
            refreshToken: dto.refreshToken,
            refreshExpiresAt: Date().addingTimeInterval(TimeInterval(dto.refreshExpiresIn)),
            accountId: dto.accountId
        )
    }
}
