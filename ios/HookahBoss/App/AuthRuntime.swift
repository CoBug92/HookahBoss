import Combine
import Foundation

@MainActor
final class AuthRuntime: ObservableObject {

    // MARK: - Observable properties

    @Published private(set) var accountId: UUID?
    @Published private(set) var configurationError: AppConfigError?
    @Published private(set) var isAdmin = false

    // MARK: - Properties

    let gate = AuthGate()

    private let library = AuthLibraryStore()
    private var libraryChanges: AnyCancellable?
    private var service: AuthService?
    private var client: APIClient?
    private var publicClient: APIClient?

    // MARK: - Computed properties

    var authorizedClient: APIClient? { client }
    var isAuthenticated: Bool { accountId != nil }
    var favoriteMixIDs: Set<UUID> { library.favoriteMixIDs }
    var ratings: [UUID: Int] { library.ratings }
    var bookmarkedArticleSlugs: Set<String> { library.bookmarkedArticleSlugs }

    var libraryError: String? {
        get { library.syncError }
        set { library.syncError = newValue }
    }

    // MARK: - Init

    init(config: Result<AppConfig, AppConfigError>? = nil) {
        libraryChanges = library.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }

        switch config ?? Self.loadConfiguration() {
        case .failure(let error):
            configurationError = error
        case .success(let config):
            configure(using: config)
        }
    }

    // MARK: - Session

    func authenticate(identityToken: String, authorizationCode: String? = nil) async throws {
        guard let service, let publicClient else {
            throw configurationError ?? AppConfigError.missingAPIBaseURL
        }

        let dto = try await publicClient.exchangeAppleIdentityToken(
            identityToken,
            authorizationCode: authorizationCode
        )
        try await service.store(dto)
        activate(dto.accountId)
    }

    func logout() async {
        if let client {
            try? await client.logout()
        }
        try? await service?.signOut()
        deactivate()
    }

    func deleteAccount() async throws -> Bool {
        guard let id = accountId, let client, let service else { return false }

        let result = try await client.deleteAccount()
        AccountCache.purge(accountId: id)
        try await service.signOut()
        deactivate()
        return result.providerRevocation == "unavailable"
    }

    // MARK: - Private methods

    private static func loadConfiguration() -> Result<AppConfig, AppConfigError> {
        do {
            return .success(try AppConfig.load())
        } catch let error as AppConfigError {
            return .failure(error)
        } catch {
            return .failure(.missingAPIBaseURL)
        }
    }

    private func configure(using config: AppConfig) {
        let publicClient = APIClient(baseURL: config.apiBaseURL)
        let service = AuthService(
            exchange: { try await publicClient.exchangeAppleIdentityToken($0) },
            refresh: { try await publicClient.refreshSession($0) }
        )
        self.service = service
        self.publicClient = publicClient
        client = APIClient(baseURL: config.apiBaseURL, tokenProvider: service)

        Task {
            if let id = try? await service.accountId() {
                activate(id)
            }
        }
    }

    private func activate(_ id: UUID) {
        isAdmin = false
        accountId = id
        library.activate(accountId: id, client: client)

        Task {
            await loadAdminCapability()
        }
    }

    private func deactivate() {
        accountId = nil
        isAdmin = false
        library.deactivate()
    }

    private func loadAdminCapability() async {
        do {
            isAdmin = try await client?.adminCapabilities().admin ?? false
        } catch {
            isAdmin = false
        }
    }
}

// MARK: - AuthLibraryServing

extension AuthRuntime: AuthLibraryServing {
    func authorize(_ action: ProtectedAction, resume: @escaping () -> Void) {
        if isAuthenticated {
            resume()
        } else {
            gate.request(action, resume: resume)
        }
    }

    func setFavorite(_ enabled: Bool, mixId: UUID) async {
        await library.setFavorite(enabled, mixId: mixId)
    }

    func setRating(_ score: Int?, mixId: UUID) async {
        await library.setRating(score, mixId: mixId)
    }

    func setArticleBookmark(_ enabled: Bool, slug: String) async {
        await library.setArticleBookmark(enabled, slug: slug)
    }
}
