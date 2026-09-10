import XCTest
@testable import HookahBoss

actor MemoryAuthStorage: AuthSessionStorage {
    var session: AuthSession?
    init(_ session: AuthSession?) { self.session = session }
    func load() async throws -> AuthSession? { session }
    func save(_ session: AuthSession) async throws { self.session = session }
    func clear() async throws { session = nil }
}

@MainActor final class AuthGateTests: XCTestCase {
    func testAdminEntryRequiresBothAuthenticationAndServerGrant() {
        XCTAssertFalse(AdminEntryVisibility.isVisible(isAuthenticated:false,isAdmin:false))
        XCTAssertFalse(AdminEntryVisibility.isVisible(isAuthenticated:false,isAdmin:true))
        XCTAssertFalse(AdminEntryVisibility.isVisible(isAuthenticated:true,isAdmin:false))
        XCTAssertTrue(AdminEntryVisibility.isVisible(isAuthenticated:true,isAdmin:true))
    }
    func testSuccessResumesPendingActionExactlyOnce() {
        let gate = AuthGate(); var calls = 0
        gate.request(.favorite) { calls += 1 }; gate.begin(); gate.succeed(); gate.succeed()
        XCTAssertEqual(calls, 1); XCTAssertEqual(gate.state, .hidden)
    }
    func testCancelAndFailureNeverRunPendingAction() {
        let gate = AuthGate(); var calls = 0
        gate.request(.inventory) { calls += 1 }; gate.begin(); gate.fail()
        XCTAssertEqual(gate.state, .failed(.inventory)); XCTAssertEqual(calls, 0)
        gate.cancel(); XCTAssertEqual(calls, 0); XCTAssertEqual(gate.state, .hidden)
    }
    func testRetryPreservesActionAndEventuallyResumesOnce() {
        let gate = AuthGate(); var calls = 0
        gate.request(.create) { calls += 1 }; gate.begin(); gate.fail(); gate.begin(); gate.succeed()
        XCTAssertEqual(calls, 1); XCTAssertEqual(gate.state, .hidden)
    }
    func testConcurrentPromptDoesNotReplacePendingAction() {
        let gate = AuthGate(); var first = 0; var second = 0
        gate.request(.rating) { first += 1 }; gate.request(.favorite) { second += 1 }; gate.begin(); gate.succeed()
        XCTAssertEqual(first, 1); XCTAssertEqual(second, 0)
    }
}

final class AuthRefreshTests: XCTestCase {
    func testConcurrentRejectedRequestsRotateRefreshOnlyOnce() async throws {
        let accountId=UUID();let old = AuthSession(accessToken: "old", expiresAt: .distantFuture, refreshToken: "refresh-old", refreshExpiresAt: .distantFuture, accountId:accountId)
        let storage = MemoryAuthStorage(old)
        actor Counter { var value=0; func next()->Int { value += 1; return value }; func current()->Int { value } }; let counter=Counter()
        let service = AuthService(storage: storage, exchange: { _ in fatalError() }, refresh: { _ in
            let count = await counter.next()
            return APISessionDTO(accessToken: "new-\(count)", expiresIn: 900, refreshToken: "refresh-new", refreshExpiresIn: 2_592_000,accountId:accountId)
        })
        async let first = service.accessToken(afterRejectedToken: "old")
        async let second = service.accessToken(afterRejectedToken: "old")
        let values = try await [first, second]
        let refreshCount = await counter.current()
        XCTAssertEqual(Set(values), ["new-1"]); XCTAssertEqual(refreshCount, 1)
    }

    func testExpiredRefreshRequiresAppleReauthentication() async {
        let storage = MemoryAuthStorage(.init(accessToken:"old",expiresAt:.distantPast,refreshToken:"expired",refreshExpiresAt:.distantPast,accountId:UUID()))
        let service = AuthService(storage:storage,exchange:{_ in fatalError()},refresh:{_ in fatalError()})
        await XCTAssertThrowsErrorAsync(try await service.accessToken(afterRejectedToken:nil))
    }
}

@MainActor final class AccountCacheTests:XCTestCase {
    func testNewInventoryContainsNoImplicitEmptyCatalogRows(){let defaults=UserDefaults(suiteName:"EmptyInventoryTests")!;defaults.removePersistentDomain(forName:"EmptyInventoryTests");XCTAssertTrue(InventoryStore(defaults:defaults,accountId:UUID()).items.isEmpty)}
    func testCachesAreIsolatedAndOnlyDeletedAccountIsPurged(){
        let defaults=UserDefaults(suiteName:"AccountCacheTests")!;defaults.removePersistentDomain(forName:"AccountCacheTests")
        let first=UUID(),second=UUID();let firstKey=AccountCache.key("inventory.v1",accountId:first),secondKey=AccountCache.key("inventory.v1",accountId:second)
        defaults.set(Data([1]),forKey:firstKey);defaults.set(Data([2]),forKey:secondKey);XCTAssertNotEqual(defaults.data(forKey:firstKey),defaults.data(forKey:secondKey))
        AccountCache.purge(accountId:first,defaults:defaults)
        XCTAssertNil(defaults.data(forKey:AccountCache.key("inventory.v1",accountId:first)));XCTAssertNotNil(defaults.data(forKey:AccountCache.key("inventory.v1",accountId:second)))
    }
    func testLegacyGlobalCachesAreDiscardedOnlyOnce(){
        let defaults=UserDefaults(suiteName:"LegacyCacheTests")!;defaults.removePersistentDomain(forName:"LegacyCacheTests");defaults.set(Data([1]),forKey:"inventory.sample.v1")
        AccountCache.discardLegacy(defaults:defaults);XCTAssertNil(defaults.data(forKey:"inventory.sample.v1"));defaults.set(Data([2]),forKey:"inventory.sample.v1");AccountCache.discardLegacy(defaults:defaults);XCTAssertNotNil(defaults.data(forKey:"inventory.sample.v1"))
    }
    func testReleaseConfigRequiresHTTPS(){
        XCTAssertThrowsError(try AppConfig.validate(raw:nil,isDebug:false));XCTAssertThrowsError(try AppConfig.validate(raw:"http://api.example.com",isDebug:false));XCTAssertNoThrow(try AppConfig.validate(raw:"https://api.example.com",isDebug:false))
    }
    func testWorkspaceSharesCreateAndMyStoreAndIsolatesAccountSwitch() {
        let suite="AccountWorkspaceTests";let defaults=UserDefaults(suiteName:suite)!;defaults.removePersistentDomain(forName:suite)
        let first=UUID(),second=UUID(),workspace=AccountWorkspace()
        workspace.activate(accountId:first,defaults:defaults)
        let createStore=workspace.current!.personalMixes
        let record=PersonalMixRecord(id:UUID(),title:"Shared",components:[],createdAt:Date(),isApproximate:false)
        createStore.add(record)
        XCTAssertTrue(workspace.current!.personalMixes === createStore)
        XCTAssertEqual(workspace.current!.personalMixes.mixes.map(\.id),[record.id])
        workspace.activate(accountId:second,defaults:defaults)
        XCTAssertTrue(workspace.current!.personalMixes.mixes.isEmpty)
        workspace.activate(accountId:first,defaults:defaults)
        XCTAssertEqual(workspace.current!.personalMixes.mixes.map(\.id),[record.id])
    }
    func testWorkspaceLogoutDropsLiveReferencesButKeepsNamespacedCache() {
        let suite="AccountWorkspaceLogoutTests";let defaults=UserDefaults(suiteName:suite)!;defaults.removePersistentDomain(forName:suite)
        let account=UUID(),workspace=AccountWorkspace();workspace.activate(accountId:account,defaults:defaults)
        workspace.current!.personalMixes.add(.init(id:UUID(),title:"Cached",components:[],createdAt:Date()))
        workspace.activate(accountId:nil,defaults:defaults);XCTAssertNil(workspace.current)
        workspace.activate(accountId:account,defaults:defaults);XCTAssertEqual(workspace.current!.personalMixes.mixes.count,1)
    }
}

private func XCTAssertThrowsErrorAsync(_ expression: @autoclosure () async throws -> Any) async {
    do { _ = try await expression(); XCTFail("Expected error") } catch { }
}
