import XCTest
@testable import HookahBoss

@MainActor
final class ViewModelTests: XCTestCase {
    func testAdminListViewModelLoadsRecordsThroughProtocol() async throws {
        let record = try adminRecord(id: "brand-1", title: "Brand")
        let service = AdminServiceSpy(records: [record])
        let model = AdminResourceListViewModel(service: service, resource: AdminResource.all[1])

        await model.load()

        XCTAssertEqual(model.records, [record])
        XCTAssertFalse(model.isLoading)
        XCTAssertNil(model.errorMessage)
        XCTAssertEqual(service.listCalls, 1)
    }

    func testMixDetailViewModelPublishesCacheThenFreshValue() async {
        let cached = mix(title: "Cached")
        let fresh = mix(title: "Fresh")
        let service = MixContentSpy(cached: cached, fresh: fresh)
        let auth = AuthLibrarySpy()
        let model = MixDetailViewModel(mix: cached, content: service, auth: auth)

        await model.appear(locale: .en)

        XCTAssertEqual(model.hydratedMix?.title, "Fresh")
        XCTAssertEqual(service.requestedLocales, [.en, .en])
    }

    func testMixDetailViewModelReconcilesRejectedRating() async {
        let initial = mix(title: "Mix")
        let auth = AuthLibrarySpy()
        auth.ratingResult = 2
        let model = MixDetailViewModel(
            mix: initial,
            content: MixContentSpy(cached: nil, fresh: initial),
            auth: auth
        )

        await model.submitRating(5)

        XCTAssertEqual(auth.requestedRating, 5)
        XCTAssertEqual(model.personalRating, 2)
    }

    func testAdminEditorValidatesAndCreatesAggregate() async throws {
        let service=AdminServiceSpy(records:[try adminRecord(id:"1",title:"One")]);let resource=AdminResource.all.first{$0.path=="official-mixes"}!
        let model=AdminEditorViewModel(service:service,resource:resource,record:nil)
        for field in resource.fields where field.required && field.kind != .json { model.values[field.key] = field.key == "status" ? "draft":"value" }
        model.components=[.init(productId:UUID().uuidString,percentage:"100")]
        let saved=await model.save();XCTAssertTrue(saved);XCTAssertEqual(service.createCalls,1)
    }

    func testAdminEditorReportsValidationWithoutCallingService() async {
        let service=AdminServiceSpy(records:[]),resource=AdminResource.all.first{$0.path=="brands"}!,model=AdminEditorViewModel(service:service,resource:resource,record:nil)
        let saved=await model.save();XCTAssertFalse(saved);XCTAssertNotNil(model.error);XCTAssertEqual(service.createCalls,0)
    }

    func testAdminReferenceLoadsAndFilters() async throws {
        let service=AdminServiceSpy(records:[try adminRecord(id:"1",title:"Alpha"),try adminRecord(id:"2",title:"Beta")]);let model=AdminReferenceViewModel(service:service,resource:AdminResource.all[1]);model.appear();await Task.yield();await Task.yield();model.search="Beta";XCTAssertEqual(model.filtered.map(\.title),["Beta"])
    }

    private func adminRecord(id: String, title: String) throws -> AdminRecord {
        try JSONDecoder().decode(AdminRecord.self, from: Data(#"{"id":"\#(id)","title":"\#(title)"}"#.utf8))
    }

    private func mix(title: String) -> MixPreview {
        MixPreview(id: UUID(), title: title, flavorTags: [], flavorProfiles: [], sweetness: .subtle,
                   acidity: .subtle, freshness: .subtle, ingredients: [], rating: nil,
                   ratingsCount: 0, strength: .medium, personalRating: nil,
                   isFavorite: false, palette: .tropical)
    }
}

@MainActor
private final class AdminServiceSpy: AdminServing {
    let records: [AdminRecord]
    private(set) var listCalls = 0
    private(set) var createCalls = 0

    init(records: [AdminRecord]) { self.records = records }
    func adminList(_ resource: AdminResource) async throws -> [AdminRecord] { listCalls += 1; return records }
    func adminCreate(_ resource: AdminResource, body: [String: JSONValue]) async throws -> AdminRecord { createCalls += 1; return records[0] }
    func adminUpdate(_ resource: AdminResource, id: String, body: [String: JSONValue]) async throws -> AdminRecord { records[0] }
    func adminDelete(_ resource: AdminResource, id: String, body: [String: JSONValue]?) async throws {}
}

@MainActor
private final class MixContentSpy: MixContentServing {
    let cached: MixPreview?
    let fresh: MixPreview
    private(set) var requestedLocales: [AppLocale] = []

    init(cached: MixPreview?, fresh: MixPreview) { self.cached = cached; self.fresh = fresh }
    func cachedMixDetail(_ id: UUID, locale: AppLocale) async -> MixPreview? { requestedLocales.append(locale); return cached }
    func mixDetail(_ id: UUID, locale: AppLocale) async throws -> MixPreview { requestedLocales.append(locale); return fresh }
}

@MainActor
private final class AuthLibrarySpy: AuthLibraryServing {
    var isAuthenticated = true
    var favoriteMixIDs: Set<UUID> = []
    var ratings: [UUID: Int] = [:]
    var bookmarkedArticleSlugs: Set<String> = []
    var libraryError: String?
    var ratingResult: Int?
    private(set) var requestedRating: Int?
    func authorize(_ action: ProtectedAction, resume: @escaping () -> Void) { resume() }
    func setFavorite(_ enabled: Bool, mixId: UUID) async {
        if enabled { favoriteMixIDs.insert(mixId) } else { favoriteMixIDs.remove(mixId) }
    }
    func setRating(_ score: Int?, mixId: UUID) async {
        requestedRating = score
        ratings[mixId] = ratingResult ?? score
    }
    func setArticleBookmark(_ enabled: Bool, slug: String) async {}
}
