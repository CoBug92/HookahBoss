import XCTest
@testable import HookahBoss

actor MemoryPublicCache: PublicCache {
    var values: [String: Data] = [:]
    func read(_ key: String) -> Data? { values[key] }
    func write(_ data: Data, key: String) { values[key] = data }
}

struct FixtureTransport: APITransport {
    let offline: Bool
    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        if offline { throw URLError(.notConnectedToInternet) }
        let path = request.url!.path
        let json: String
        if path.contains("/mixes/") {
            json = #"{"data":{"id":"10000000-0000-0000-0000-000000000001","slug":"fresh-mix","title":"Hydrated Mix","summary":"Rich","rating":4.8,"ratingsCount":20,"components":[{"productId":"20000000-0000-0000-0000-000000000001","brand":"Brand","line":"Core","flavor":"Lemon","percentage":100,"position":1}],"tags":["Lemon"],"profiles":["citrus"],"sweetness":"pronounced","acidity":"pronounced","freshness":"pronounced","strength":"strong"}}"#
        } else if path.hasSuffix("/mixes") {
            json = #"{"data":[{"id":"10000000-0000-0000-0000-000000000001","slug":"fresh-mix","title":"Fresh Mix","summary":"Summary","rating":4.5,"ratingsCount":2,"components":[{"productId":"20000000-0000-0000-0000-000000000001","brand":"Brand","line":"Core","flavor":"Lemon","percentage":100,"position":1}],"tags":["Lemon"],"profiles":["citrus"],"sweetness":"subtle","acidity":"pronounced","freshness":"pronounced","strength":"medium"}],"pagination":{"nextCursor":null,"hasMore":false}}"#
        } else if path.hasSuffix("/products") {
            json = #"{"data":[{"id":"20000000-0000-0000-0000-000000000001","slug":"lemon","name":"Lemon","description":null,"translationOrigin":"official","sourceConfidence":"high","sweetness":"subtle","acidity":"pronounced","freshness":"pronounced","lineId":"30000000-0000-0000-0000-000000000001","lineName":"Core","strength":"medium","brandId":"40000000-0000-0000-0000-000000000001","brandName":"Brand","tags":[]}],"pagination":{"nextCursor":null,"hasMore":false}}"#
        } else { json = #"{"data":[{"id":"50000000-0000-0000-0000-000000000001","slug":"guide","title":"Guide","summary":"Read","category":"fundamentals","readingMinutes":3}]}"# }
        return (Data(json.utf8), HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!)
    }
}

final class PublicContentStoreTests: XCTestCase {
    func testArtworkMappingUsesFlavorProfilesWithDessertPriority() {
        XCTAssertEqual(MixPalette.forProfiles([.dessert,.berry]),.dessert)
        XCTAssertEqual(MixPalette.forProfiles([.berry]),.berry)
        XCTAssertEqual(MixPalette.forProfiles([.citrus]),.citrus)
        XCTAssertEqual(MixPalette.forProfiles([.fruit,.beverage]),.beverage)
        XCTAssertEqual(MixPalette.forProfiles([.fresh]),.fresh)
        XCTAssertNotNil(ArtworkResource.image(for: .dessert))
        XCTAssertNotNil(ArtworkResource.image(for: .berry))
        XCTAssertNotNil(ArtworkResource.image(for: .tropical))
    }

    func testArtworkPNGsAreCopiedIntoApplicationBundle() {
        for palette in MixPalette.allCases {
            XCTAssertNotNil(ArtworkResource.image(for: palette))
        }
    }
    func testEveryArticleCategoryHasMappedBundledArtwork() {
        for category in ArticleCategory.allCases { XCTAssertNotNil(ArtworkResource.image(for: category),category.rawValue) }
    }

    func testRichDetailMapsProfilesStrengthAndIntensities() {
        let dto=OfficialMixDetailDTO(id:UUID(),slug:"dessert",title:"Dessert",summary:"Summary",rating:4.5,ratingsCount:2,components:[],tags:["Cream"],profiles:["dessert"],sweetness:"pronounced",acidity:"subtle",freshness:"subtle",strength:"strong")
        let mix=MixPreview(dto:dto)
        XCTAssertEqual(mix.flavorProfiles,[.dessert]);XCTAssertEqual(mix.palette,.dessert);XCTAssertEqual(mix.strength,.strong);XCTAssertEqual(mix.sweetness,.pronounced)
    }
    func testRichDetailRetainsFreshProfile() {
        let dto=OfficialMixDetailDTO(id:UUID(),slug:"iceberg",title:"Iceberg",summary:"Cooling",rating:4,ratingsCount:1,components:[],tags:["Cooling"],profiles:["fresh"],sweetness:"subtle",acidity:"subtle",freshness:"pronounced",strength:"medium")
        let mix=MixPreview(dto:dto)
        XCTAssertEqual(mix.flavorProfiles,[.fresh]);XCTAssertEqual(mix.palette,.fresh)
    }
    func testMixMergesDuplicateBrandAndFlavorAndBuildsCloudFromComposition() {
        let firstID = UUID(), secondID = UUID()
        let dto = OfficialMixDetailDTO(
            id: UUID(), slug: "duplicate", title: "Duplicate", summary: nil, rating: nil, ratingsCount: 0,
            components: [
                .init(productId: firstID, brand: "Musthave", line: "Original", flavor: "Pineapple", percentage: 20, position: 1),
                .init(productId: secondID, brand: " musthave ", line: "Original", flavor: "pineapple", percentage: 30, position: 2),
                .init(productId: UUID(), brand: "Darkside", line: "Core", flavor: "Lemon", percentage: 50, position: 3)
            ],
            tags: ["Unrelated server tag"], profiles: ["fruit"], sweetness: "subtle", acidity: "subtle", freshness: "subtle", strength: "medium"
        )

        let mix = MixPreview(dto: dto)

        XCTAssertEqual(mix.ingredients.count, 2)
        XCTAssertEqual(mix.ingredients.first?.id, firstID)
        XCTAssertEqual(mix.ingredients.first?.percentage, 50)
        XCTAssertEqual(mix.flavorTags, ["Pineapple", "Lemon"])
    }
    @MainActor func testMapsNetworkSnapshotAndRestoresItWhenOffline() async {
        let cache = MemoryPublicCache()
        let online = PublicContentStore(client: APIClient(baseURL: URL(string: "https://example.test")!, transport: FixtureTransport(offline: false)), cache: cache)
        await online.load(locale: .en)
        XCTAssertEqual(online.mixes.first?.ingredients.first?.flavor, "Lemon")
        XCTAssertEqual(online.mixes.first?.flavorProfiles, [.citrus])
        XCTAssertEqual(online.articles.first?.slug, "guide")

        let offline = PublicContentStore(client: APIClient(baseURL: URL(string: "https://example.test")!, transport: FixtureTransport(offline: true)), cache: cache)
        await offline.load(locale: .en)
        XCTAssertEqual(offline.mixes.first?.title, "Fresh Mix")
        XCTAssertEqual(offline.state, .loaded)
    }
    @MainActor func testDetailHydratesRichDTOAndOfflineStoreReadsLastSuccessfulDetail() async throws {
        let cache=MemoryPublicCache(),id=UUID(uuidString:"10000000-0000-0000-0000-000000000001")!
        let online=PublicContentStore(client:APIClient(baseURL:URL(string:"https://example.test")!,transport:FixtureTransport(offline:false)),cache:cache)
        let hydrated=try await online.mixDetail(id,locale:.en)
        XCTAssertEqual(hydrated.title,"Hydrated Mix");XCTAssertEqual(hydrated.strength,.strong);XCTAssertEqual(hydrated.ingredients.first?.percentage,100)
        let cached=await online.cachedMixDetail(id,locale:.en);XCTAssertEqual(cached?.title,"Hydrated Mix")
        let offline=PublicContentStore(client:APIClient(baseURL:URL(string:"https://example.test")!,transport:FixtureTransport(offline:true)),cache:cache)
        let stale=try await offline.mixDetail(id,locale:.en)
        XCTAssertEqual(stale.title,"Hydrated Mix");XCTAssertEqual(stale.flavorProfiles,[.citrus])
    }
}
