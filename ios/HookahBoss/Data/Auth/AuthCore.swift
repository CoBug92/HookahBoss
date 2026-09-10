import AuthenticationServices
import Security
import SwiftUI

struct AuthSession: Codable, Equatable, Sendable {
    let accessToken: String
    let expiresAt: Date
    let refreshToken: String
    let refreshExpiresAt: Date
    let accountId: UUID
    var isValid: Bool { expiresAt > Date().addingTimeInterval(30) }
}

protocol AuthSessionStorage: Sendable {
    func load() async throws -> AuthSession?
    func save(_ session: AuthSession) async throws
    func clear() async throws
}

actor KeychainAuthSessionStorage: AuthSessionStorage {
    private let service = "com.hookahboss.app.auth"
    private let account = "api-session"

    func load() throws -> AuthSession? {
        var item: CFTypeRef?
        let status = SecItemCopyMatching([kSecClass: kSecClassGenericPassword, kSecAttrService: service, kSecAttrAccount: account, kSecReturnData: true] as CFDictionary, &item)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = item as? Data else { throw KeychainError(status) }
        return try JSONDecoder().decode(AuthSession.self, from: data)
    }
    func save(_ session: AuthSession) throws {
        let data = try JSONEncoder().encode(session)
        let key = [kSecClass: kSecClassGenericPassword, kSecAttrService: service, kSecAttrAccount: account] as CFDictionary
        let attributes = [kSecValueData: data, kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly] as CFDictionary
        let status = SecItemUpdate(key, attributes)
        if status == errSecItemNotFound {
            var insert = key as! [CFString: Any]; insert[kSecValueData] = data; insert[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            let inserted = SecItemAdd(insert as CFDictionary, nil); guard inserted == errSecSuccess else { throw KeychainError(inserted) }
        } else if status != errSecSuccess { throw KeychainError(status) }
    }
    func clear() throws {
        let status = SecItemDelete([kSecClass: kSecClassGenericPassword, kSecAttrService: service, kSecAttrAccount: account] as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw KeychainError(status) }
    }
}

struct KeychainError: Error { let status: OSStatus; init(_ status: OSStatus) { self.status = status } }

actor AuthService: AccessTokenProvider {
    private let storage: any AuthSessionStorage
    private let exchange: @Sendable (String) async throws -> APISessionDTO
    private let refresh: @Sendable (String) async throws -> APISessionDTO
    private var refreshTask:Task<AuthSession,Error>?
    init(storage: any AuthSessionStorage = KeychainAuthSessionStorage(), exchange: @escaping @Sendable (String) async throws -> APISessionDTO, refresh: @escaping @Sendable (String) async throws -> APISessionDTO) {
        self.storage = storage; self.exchange = exchange; self.refresh = refresh
    }
    func accessToken(afterRejectedToken rejected: String? = nil) async throws -> String {
        if let refreshTask { return try await refreshTask.value.accessToken }
        guard var session = try await storage.load(), session.refreshExpiresAt > Date() else { try await storage.clear(); throw AuthTokenError.signedOut }
        if session.isValid && (rejected == nil || rejected != session.accessToken) { return session.accessToken }
        if let refreshTask { return try await refreshTask.value.accessToken }
        let token=session.refreshToken,refresh=self.refresh,storage=self.storage
        let task=Task<AuthSession,Error>{let dto=try await refresh(token);let renewed=Self.session(dto);try await storage.save(renewed);return renewed}
        refreshTask=task
        do { session=try await task.value;refreshTask=nil;return session.accessToken }
        catch { refreshTask=nil;throw error }
    }
    func authenticate(identityToken: String) async throws {
        let dto = try await exchange(identityToken)
        try await storage.save(Self.session(dto))
    }
    func store(_ dto:APISessionDTO) async throws { try await storage.save(Self.session(dto)) }
    func signOut() async throws { try await storage.clear() }
    func accountId() async throws -> UUID { guard let session=try await storage.load() else { throw AuthTokenError.signedOut }; return session.accountId }
    private static func session(_ dto: APISessionDTO) -> AuthSession { .init(accessToken:dto.accessToken,expiresAt:Date().addingTimeInterval(TimeInterval(dto.expiresIn)),refreshToken:dto.refreshToken,refreshExpiresAt:Date().addingTimeInterval(TimeInterval(dto.refreshExpiresIn)),accountId:dto.accountId) }
}

@MainActor
final class SignInWithAppleCoordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private var continuation: CheckedContinuation<String, Error>?
    func identityToken() async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            let request = ASAuthorizationAppleIDProvider().createRequest(); request.requestedScopes = [.email]
            let controller = ASAuthorizationController(authorizationRequests: [request]); controller.delegate = self; controller.presentationContextProvider = self; controller.performRequests()
        }
    }
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.keyWindow }.first ?? ASPresentationAnchor()
    }
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential, let data = credential.identityToken, let token = String(data: data, encoding: .utf8) else {
            continuation?.resume(throwing: AuthFlowError.missingIdentityToken); continuation = nil; return
        }
        continuation?.resume(returning: token); continuation = nil
    }
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) { continuation?.resume(throwing: error); continuation = nil }
}

enum AuthFlowError: Error { case missingIdentityToken }
enum ProtectedAction: String, CaseIterable {
    case favorite, rating, inventory, create, bookmark, personal
    var title: String { switch self {case .favorite:L10n.Auth.Favorite.title;case .rating:L10n.Auth.Rating.title;case .inventory:L10n.Auth.Inventory.title;case .create:L10n.Auth.Create.title;case .bookmark:L10n.Auth.Bookmark.title;case .personal:L10n.Auth.Personal.title} }
    var body: String { switch self {case .favorite:L10n.Auth.Favorite.body;case .rating:L10n.Auth.Rating.body;case .inventory:L10n.Auth.Inventory.body;case .create:L10n.Auth.Create.body;case .bookmark:L10n.Auth.Bookmark.body;case .personal:L10n.Auth.Personal.body} }
}

@MainActor
final class AuthGate: ObservableObject {
    enum State: Equatable { case hidden, prompt(ProtectedAction), loading(ProtectedAction), failed(ProtectedAction) }
    @Published private(set) var state: State = .hidden
    private var pending: (() -> Void)?
    func request(_ action: ProtectedAction, resume: @escaping () -> Void) { guard case .hidden = state else { return }; pending = resume; state = .prompt(action) }
    func begin() { if case .prompt(let action) = state { state = .loading(action) } else if case .failed(let action) = state { state = .loading(action) } }
    func succeed() { let action = pending; pending = nil; state = .hidden; action?() }
    func fail() { if case .loading(let action) = state { state = .failed(action) } }
    func cancel() { pending = nil; state = .hidden }
}

@MainActor
final class AuthRuntime: ObservableObject {
    @Published private(set) var accountId: UUID?
    @Published private(set) var configurationError: AppConfigError?
    @Published private(set) var favoriteMixIDs: Set<UUID> = []
    @Published private(set) var ratings: [UUID:Int] = [:]
    @Published var libraryError: String?
    @Published private(set) var bookmarkedArticleSlugs:Set<String>=[]
    @Published private(set) var isAdmin=false
    let gate = AuthGate()
    private var service: AuthService?
    private var client: APIClient?
    private var publicClient:APIClient?
    var authorizedClient: APIClient? { client }
    init(config: Result<AppConfig, AppConfigError>? = nil) {
        let resolved:Result<AppConfig,AppConfigError>
        if let config { resolved=config } else { do { resolved = .success(try AppConfig.load()) } catch let error as AppConfigError { resolved = .failure(error) } catch { resolved = .failure(.missingAPIBaseURL) } }
        switch resolved {
        case .failure(let error): configurationError=error
        case .success(let config):
            let publicClient=APIClient(baseURL:config.apiBaseURL)
            let service=AuthService(exchange:{try await publicClient.exchangeAppleIdentityToken($0)},refresh:{try await publicClient.refreshSession($0)})
            self.service=service;self.publicClient=publicClient;self.client=APIClient(baseURL:config.apiBaseURL,tokenProvider:service)
            Task { if let id=try? await service.accountId(){self.activate(id)} }
        }
    }
    var isAuthenticated:Bool { accountId != nil }
    func authenticate(identityToken:String,authorizationCode:String?=nil) async throws { guard let service,let publicClient else { throw configurationError ?? .missingAPIBaseURL };let dto=try await publicClient.exchangeAppleIdentityToken(identityToken,authorizationCode:authorizationCode);try await service.store(dto);activate(dto.accountId) }
    func logout() async { if let client { try? await client.logout() };try? await service?.signOut();accountId=nil;favoriteMixIDs=[];ratings=[:];bookmarkedArticleSlugs=[];isAdmin=false }
    func deleteAccount() async throws ->Bool { guard let id=accountId,let client,let service else{return false};let result=try await client.deleteAccount();AccountCache.purge(accountId:id);try await service.signOut();accountId=nil;isAdmin=false;return result.providerRevocation=="unavailable" }
    func setFavorite(_ enabled:Bool,mixId:UUID) async {
        let old=favoriteMixIDs; if enabled { favoriteMixIDs.insert(mixId) } else { favoriteMixIDs.remove(mixId) };saveLibraryCache()
        do { if enabled { _ = try await client?.addFavorite(mixId:mixId) } else { try await client?.deleteFavorite(mixId:mixId) } }
        catch { if SyncFailurePolicy.disposition(for:error) == .queue { enqueue(.init(id:UUID(),kind:.favorite,mixId:mixId,value:enabled ? 1:0)) } else { favoriteMixIDs=old };libraryError=L10n.Content.Error.network;saveLibraryCache() }
    }
    func setRating(_ score:Int?,mixId:UUID) async {
        let old=ratings;ratings[mixId]=score;saveLibraryCache()
        do { if let score { _ = try await client?.setRating(mixId:mixId,score:score) } else { try await client?.deleteRating(mixId:mixId) } }
        catch { if SyncFailurePolicy.disposition(for:error) == .queue { enqueue(.init(id:UUID(),kind:.rating,mixId:mixId,value:score)) } else { ratings=old };libraryError=L10n.Content.Error.network;saveLibraryCache() }
    }
    func setArticleBookmark(_ enabled:Bool,slug:String)async {let old=bookmarkedArticleSlugs;if enabled{bookmarkedArticleSlugs.insert(slug)}else{bookmarkedArticleSlugs.remove(slug)};saveLibraryCache();do{try await client?.setArticleBookmark(slug:slug,enabled:enabled)}catch{if error.isRetryableSyncFailure{enqueueBookmark(.init(slug:slug,enabled:enabled))}else{bookmarkedArticleSlugs=old};libraryError=L10n.Content.Error.network;saveLibraryCache()}}
    private func activate(_ id:UUID){isAdmin=false;accountId=id;loadLibraryCache(id);Task{await reconcileLibrary();await loadAdminCapability()}}
    private func loadAdminCapability()async{do{isAdmin=try await client?.adminCapabilities().admin ?? false}catch{isAdmin=false}}
    private func reconcileLibrary() async { await replayOutbox();await replayBookmarkOutbox();guard let snapshot=try? await client?.library() else{return};let projection=LibraryProjection(favorites:Set(snapshot.favorites.map(\.mixId)),ratings:Dictionary(uniqueKeysWithValues:snapshot.ratings.map{($0.mixId,$0.score)})).overlaying(pendingMutations());favoriteMixIDs=projection.favorites;ratings=projection.ratings;bookmarkedArticleSlugs=Set(snapshot.articleBookmarks);for mutation in pendingBookmarks(){if mutation.enabled{bookmarkedArticleSlugs.insert(mutation.slug)}else{bookmarkedArticleSlugs.remove(mutation.slug)}};saveLibraryCache() }
    private func loadLibraryCache(_ id:UUID){guard let data=UserDefaults.standard.data(forKey:AccountCache.key("library.v1",accountId:id)),let cached=try? JSONDecoder().decode(LibraryCache.self,from:data)else{return};favoriteMixIDs=Set(cached.favorites);ratings=cached.ratings;bookmarkedArticleSlugs=Set(cached.articleBookmarks ?? [])}
    private func saveLibraryCache(){guard let id=accountId,let data=try? JSONEncoder().encode(LibraryCache(favorites:Array(favoriteMixIDs),ratings:ratings,articleBookmarks:Array(bookmarkedArticleSlugs)))else{return};UserDefaults.standard.set(data,forKey:AccountCache.key("library.v1",accountId:id))}
    private func enqueue(_ mutation:LibraryMutation){guard let id=accountId else{return};let key=AccountCache.key("library.outbox.v1",accountId:id);let queue=(UserDefaults.standard.data(forKey:key).flatMap{try? JSONDecoder().decode([LibraryMutation].self,from:$0)}) ?? [];let updated=OutboxQueue.upserting(mutation,in:queue){$0.kind==$1.kind && $0.mixId==$1.mixId};UserDefaults.standard.set(try? JSONEncoder().encode(updated),forKey:key)}
    private func pendingMutations()->[LibraryMutation]{guard let id=accountId else{return []};return UserDefaults.standard.data(forKey:AccountCache.key("library.outbox.v1",accountId:id)).flatMap{try? JSONDecoder().decode([LibraryMutation].self,from:$0)} ?? []}
    private func bookmarkOutboxKey()->String?{accountId.map{AccountCache.key("bookmark.outbox.v1",accountId:$0)}}
    private func pendingBookmarks()->[BookmarkMutation]{guard let key=bookmarkOutboxKey() else{return []};return UserDefaults.standard.data(forKey:key).flatMap{try? JSONDecoder().decode([BookmarkMutation].self,from:$0)} ?? []}
    private func enqueueBookmark(_ mutation:BookmarkMutation){guard let key=bookmarkOutboxKey() else{return};let queue=OutboxQueue.upserting(mutation,in:pendingBookmarks()){$0.slug==$1.slug};UserDefaults.standard.set(try? JSONEncoder().encode(queue),forKey:key)}
    private func replayBookmarkOutbox()async{guard let client,let key=bookmarkOutboxKey()else{return};var queue=pendingBookmarks();for mutation in queue{do{try await client.setArticleBookmark(slug:mutation.slug,enabled:mutation.enabled);queue.removeAll{$0.slug==mutation.slug}}catch{if error.isRetryableSyncFailure{break}else{queue.removeAll{$0.slug==mutation.slug}}}};UserDefaults.standard.set(try? JSONEncoder().encode(queue),forKey:key)}
    private func replayOutbox() async {guard let id=accountId,let client else{return};let key=AccountCache.key("library.outbox.v1",accountId:id);guard var queue=UserDefaults.standard.data(forKey:key).flatMap({try? JSONDecoder().decode([LibraryMutation].self,from:$0)}) else{return};for mutation in queue { do { switch mutation.kind {case .favorite:if mutation.value==1{_ = try await client.addFavorite(mixId:mutation.mixId)}else{try await client.deleteFavorite(mixId:mutation.mixId)};case .rating:if let score=mutation.value{_ = try await client.setRating(mixId:mutation.mixId,score:score)}else{try await client.deleteRating(mixId:mutation.mixId)}};queue.removeAll{$0.id==mutation.id} } catch { if !error.isRetryableSyncFailure{queue.removeAll{$0.id==mutation.id}}else{break} } };UserDefaults.standard.set(try? JSONEncoder().encode(queue),forKey:key)}
}

extension AuthRuntime: AuthLibraryServing {
    func authorize(_ action: ProtectedAction, resume: @escaping () -> Void) {
        if isAuthenticated { resume() } else { gate.request(action, resume: resume) }
    }
}
private struct LibraryCache:Codable { let favorites:[UUID];let ratings:[UUID:Int];let articleBookmarks:[String]? }

enum AccountCache {
    static func key(_ base:String,accountId:UUID)->String { "account.\(accountId.uuidString).\(base)" }
    static func purge(accountId:UUID,defaults:UserDefaults = .standard) { for base in ["inventory.v1","inventory.matches.v1","personal.mixes.v1","library.v1","library.outbox.v1","bookmark.outbox.v1","inventory.outbox.v1","private.outbox.v1","personal.outbox.v1"] { defaults.removeObject(forKey:key(base,accountId:accountId)) } }
    static func discardLegacy(defaults:UserDefaults = .standard) { guard !defaults.bool(forKey:"account.cache.legacyDiscarded") else{return};defaults.removeObject(forKey:"inventory.sample.v1");defaults.removeObject(forKey:"personal.mixes.v1");defaults.set(true,forKey:"account.cache.legacyDiscarded") }
}
