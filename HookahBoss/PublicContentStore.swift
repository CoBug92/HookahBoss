import Foundation

protocol PublicCache: Sendable {
    func read(_ key: String) async -> Data?
    func write(_ data: Data, key: String) async
}

actor DiskPublicCache: PublicCache {
    private let directory: URL
    init(directory: URL? = nil) {
        self.directory = directory ?? FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appending(path: "PublicAPI", directoryHint: .isDirectory)
    }
    func read(_ key: String) -> Data? { try? Data(contentsOf: file(key)) }
    func write(_ data: Data, key: String) {
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try? data.write(to: file(key), options: .atomic)
    }
    private func file(_ key: String) -> URL { directory.appending(path: key.replacingOccurrences(of: "/", with: "_") + ".json") }
}

@MainActor
final class PublicContentStore: ObservableObject {
    enum LoadState: Equatable { case idle, loading, loaded, failed(String) }
    @Published private(set) var mixes: [MixPreview] = []
    @Published private(set) var products: [TobaccoProductDTO] = []
    @Published private(set) var articles: [ArticleDTO] = []
    @Published private(set) var state: LoadState = .idle

    private let client: APIClient?
    private let cache: any PublicCache
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    private var loadedLocale: APIClient.Locale?

    init(client: APIClient? = nil, cache: any PublicCache = DiskPublicCache()) {
        #if DEBUG
        if let client { self.client = client }
        else if ProcessInfo.processInfo.environment["HOOKAHBOSS_UI_TEST"] == "1" { self.client=APIClient(baseURL:URL(string:"https://fixture.invalid")!,transport:UITestPublicTransport()) }
        else if let config = try? AppConfig.load() { self.client = APIClient(baseURL: config.apiBaseURL) }
        else { self.client = nil }
        #else
        if let client { self.client=client }
        else if let config=try? AppConfig.load(){self.client=APIClient(baseURL:config.apiBaseURL)}
        else {self.client=nil}
        #endif
        self.cache = cache
    }

    func load(locale: APIClient.Locale, force: Bool = false) async {
        if !force, loadedLocale == locale, state == .loaded { return }
        loadedLocale = locale
        state = .loading
        let key = "public-\(locale.rawValue)-v2"
        if let data = await cache.read(key), let snapshot = try? decoder.decode(Snapshot.self, from: data) {
            apply(snapshot); state = .loaded
        }
        guard let client else { if mixes.isEmpty && articles.isEmpty { state = .failed(String(localized: "content.error.configuration")) }; return }
        do {
            async let mixDTOs = client.mixes(locale: locale)
            async let productDTOs = client.products(locale: locale)
            async let articleDTOs = client.articles(locale: locale, pageSize: 100)
            let snapshot = Snapshot(mixes: try await mixDTOs, products: try await productDTOs, articles: try await articleDTOs)
            apply(snapshot); state = .loaded
            if let data = try? encoder.encode(snapshot) { await cache.write(data, key: key) }
        } catch {
            if mixes.isEmpty && articles.isEmpty { state = .failed(String(localized: "content.error.network")) }
        }
    }

    func mixDetail(_ id: UUID, locale: APIClient.Locale) async throws -> MixPreview {
        let key = "mix-\(locale.rawValue)-\(id.uuidString)"
        if let client {
            do { let dto = try await client.mix(id: id, locale: locale); if let data = try? encoder.encode(dto) { await cache.write(data, key: key) }; return MixPreview(dto: dto) }
            catch { if let data = await cache.read(key), let dto = try? decoder.decode(OfficialMixDetailDTO.self, from: data) { return MixPreview(dto: dto) }; throw error }
        }
        if let data = await cache.read(key), let dto = try? decoder.decode(OfficialMixDetailDTO.self, from: data) { return MixPreview(dto: dto) }
        throw AppConfigError.missingAPIBaseURL
    }

    func cachedMixDetail(_ id:UUID,locale:APIClient.Locale) async -> MixPreview? {
        let key="mix-\(locale.rawValue)-\(id.uuidString)"
        guard let data=await cache.read(key),let dto=try? decoder.decode(OfficialMixDetailDTO.self,from:data) else{return nil}
        return MixPreview(dto:dto)
    }

    func articleDetail(_ id: String, locale: APIClient.Locale) async throws -> ArticleDetailDTO {
        let key = "article-\(locale.rawValue)-\(id)"
        if let client {
            do { let dto = try await client.article(id: id, locale: locale); if let data = try? encoder.encode(dto) { await cache.write(data, key: key) }; return dto }
            catch { if let data = await cache.read(key), let dto = try? decoder.decode(ArticleDetailDTO.self, from: data) { return dto }; throw error }
        }
        if let data = await cache.read(key), let dto = try? decoder.decode(ArticleDetailDTO.self, from: data) { return dto }
        throw AppConfigError.missingAPIBaseURL
    }

    private func apply(_ snapshot: Snapshot) {
        products = snapshot.products; articles = snapshot.articles
        mixes = snapshot.mixes.compactMap(MixPreview.init(dto:))
    }

    private struct Snapshot: Codable { let mixes: [OfficialMixDTO]; let products: [TobaccoProductDTO]; let articles: [ArticleDTO] }
}

#if DEBUG
private struct UITestPublicTransport:APITransport {
    func data(for request:URLRequest) async throws ->(Data,HTTPURLResponse) {
        let path=request.url!.path,json:String
        if path.hasSuffix("/mixes") { json=#"{"data":[{"id":"10000000-0000-0000-0000-000000000001","slug":"citrus-day","title":"Citrus Day","summary":"Bright citrus mix","rating":4.7,"ratingsCount":42,"components":[{"productId":"20000000-0000-0000-0000-000000000001","brand":"Brand","line":"Core","flavor":"Lemon","percentage":100,"position":1}],"tags":["Lemon"],"profiles":["citrus"],"sweetness":"subtle","acidity":"pronounced","freshness":"pronounced","strength":"medium"}],"pagination":{"nextCursor":null,"hasMore":false}}"# }
        else if path.contains("/mixes/") { json=#"{"data":{"id":"10000000-0000-0000-0000-000000000001","slug":"citrus-day","title":"Citrus Day","summary":"Bright citrus mix","rating":4.7,"ratingsCount":42,"components":[{"productId":"20000000-0000-0000-0000-000000000001","brand":"Brand","line":"Core","flavor":"Lemon","percentage":100,"position":1}],"tags":["Lemon"],"profiles":["citrus"],"sweetness":"subtle","acidity":"pronounced","freshness":"pronounced","strength":"medium"}}"# }
        else if path.hasSuffix("/products") { json=#"{"data":[{"id":"20000000-0000-0000-0000-000000000001","slug":"lemon","name":"Lemon","description":null,"translationOrigin":"official","sourceConfidence":"high","sweetness":"subtle","acidity":"pronounced","freshness":"pronounced","lineId":"30000000-0000-0000-0000-000000000001","lineName":"Core","strength":"medium","brandId":"40000000-0000-0000-0000-000000000001","brandName":"Brand","tags":[]}],"pagination":{"nextCursor":null,"hasMore":false}}"# }
        else if path.contains("/articles/") { json=#"{"data":{"id":"50000000-0000-0000-0000-000000000001","slug":"guide","title":"Hookah Basics","summary":"A practical introduction","sections":[{"heading":"Start","body":"Prepare carefully."}],"category":"fundamentals","readingMinutes":3,"related":[]}}"# }
        else { json=#"{"data":[{"id":"50000000-0000-0000-0000-000000000001","slug":"guide","title":"Hookah Basics","summary":"A practical introduction","category":"fundamentals","readingMinutes":3}],"pagination":{"page":1,"pageSize":100,"total":1}}"# }
        return(Data(json.utf8),HTTPURLResponse(url:request.url!,statusCode:200,httpVersion:nil,headerFields:nil)!)
    }
}
#endif

extension APIClient.Locale {
    static var currentApp: Self { Foundation.Locale.current.language.languageCode?.identifier == "en" ? .en : .ru }
}

extension MixPreview {
    init?(dto: OfficialMixDTO) {
        guard let strength = MixStrength(rawValue: dto.strength) else { return nil }
        self.init(id: dto.id, title: dto.title, flavorTags: dto.tags,
                  flavorProfiles: Set(dto.profiles.compactMap(FlavorProfile.init(rawValue:))),
                  sweetness: FlavorIntensity(rawValue: dto.sweetness) ?? .subtle,
                  acidity: FlavorIntensity(rawValue: dto.acidity) ?? .subtle,
                  freshness: FlavorIntensity(rawValue: dto.freshness) ?? .subtle,
                  ingredients: dto.components.sorted { $0.position < $1.position }.map { MixIngredient(id: $0.productId, brand: $0.brand, line: $0.line, flavor: $0.flavor, percentage: $0.percentage) },
                  rating: dto.rating, ratingsCount: dto.ratingsCount, strength: strength,
                  personalRating: nil, isFavorite: false, palette: .forProfiles(Set(dto.profiles.compactMap(FlavorProfile.init(rawValue:)))))
    }
    init(dto: OfficialMixDetailDTO) {
        let profiles=Set(dto.profiles.compactMap(FlavorProfile.init(rawValue:)))
        self.init(id:dto.id,title:dto.title,flavorTags:dto.tags,flavorProfiles:profiles,sweetness:FlavorIntensity(rawValue:dto.sweetness) ?? .subtle,acidity:FlavorIntensity(rawValue:dto.acidity) ?? .subtle,freshness:FlavorIntensity(rawValue:dto.freshness) ?? .subtle,ingredients:dto.domainIngredients,rating:dto.rating,ratingsCount:dto.ratingsCount,strength:MixStrength(rawValue:dto.strength) ?? .medium,personalRating:nil,isFavorite:false,palette:.forProfiles(profiles))
    }
}
