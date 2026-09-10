import Foundation

protocol APITransport: Sendable {
    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

struct URLSessionTransport: APITransport {
    let session: URLSession
    init(session: URLSession = .shared) { self.session = session }

    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIError.nonHTTPResponse }
        return (data, http)
    }
}

enum APIError: Error, Equatable {
    case invalidURL
    case transport(String)
    case nonHTTPResponse
    case http(status: Int, serverCode: String?, body: Data)
    case decoding(String)
}

protocol AccessTokenProvider: Sendable {
    func accessToken(afterRejectedToken: String?) async throws -> String
}

enum AuthTokenError: Error { case signedOut }

struct APIClient: Sendable {
    typealias Locale = AppLocale
    enum ProductStatus: String { case published, archived }

    let baseURL: URL
    let transport: any APITransport
    let tokenProvider: (any AccessTokenProvider)?
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(baseURL: URL, transport: any APITransport = URLSessionTransport(), tokenProvider: (any AccessTokenProvider)? = nil) {
        self.baseURL = baseURL
        self.transport = transport
        self.tokenProvider = tokenProvider
        decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        encoder = JSONEncoder()
    }

    func brands() async throws -> [BrandDTO] {
        try await get("v1/brands")
    }

    func products(locale: Locale = .ru, status: ProductStatus = .published, brandId: UUID? = nil) async throws -> [TobaccoProductDTO] {
        try await allCursorPages("v1/products",query:["locale":locale.rawValue,"status":status.rawValue,"brandId":brandId?.uuidString])
    }

    func mixes(locale: Locale = .ru) async throws -> [OfficialMixDTO] {
        try await allCursorPages("v1/mixes",query:["locale":locale.rawValue])
    }

    func mix(id: UUID, locale: Locale = .ru) async throws -> OfficialMixDetailDTO {
        try await get("v1/mixes/\(id.uuidString)", query: ["locale": locale.rawValue])
    }

    func articles(locale: Locale = .ru, category: String? = nil, page: Int = 1, pageSize: Int = 20) async throws -> [ArticleDTO] {
        try await get("v1/articles", query: ["locale": locale.rawValue, "category": category, "page": String(page), "pageSize": String(pageSize)])
    }

    func article(id: String, locale: Locale = .ru) async throws -> ArticleDetailDTO {
        try await get("v1/articles/\(id)", query: ["locale": locale.rawValue])
    }

    func exchangeAppleIdentityToken(_ identityToken: String,authorizationCode:String?=nil) async throws -> APISessionDTO {
        try await send("v1/auth/apple", method: "POST", token: nil, body: AppleExchangeInput(identityToken: identityToken,authorizationCode:authorizationCode))
    }
    func refreshSession(_ refreshToken: String) async throws -> APISessionDTO { try await send("v1/auth/refresh", method: "POST", token: nil, body: RefreshInput(refreshToken: refreshToken)) }
    func logout() async throws { try await sendEmptyAuthorized("v1/auth/logout", method: "POST") }
    func deleteAccount() async throws ->AccountDeletionDTO { try await send("v1/me/account",method:"DELETE",token:try await requiredToken(),body:Optional<String>.none) }
    func adminCapabilities()async throws->AdminCapabilitiesDTO{try await get("v1/me/admin-capabilities",token:try await requiredToken())}
    func adminList(_ resource:AdminResource)async throws->[AdminRecord]{
        let limit=100,token=try await requiredToken();var offset=0,result:[AdminRecord]=[],seen=Set<String>()
        while true {
            let page:[AdminRecord]=try await get("v1/admin/\(resource.path)",query:["limit":String(limit),"offset":String(offset)],token:token)
            if page.isEmpty { break }
            let fresh=page.filter{seen.insert($0.id).inserted};result.append(contentsOf:fresh)
            if page.count < limit || fresh.isEmpty { break }
            offset += page.count
        }
        return result
    }
    func adminDetail(_ resource:AdminResource,id:String)async throws->AdminRecord{try await get("v1/admin/\(resource.path)/\(id)",token:try await requiredToken())}
    func adminCreate(_ resource:AdminResource,body:[String:JSONValue])async throws->AdminRecord{try await sendAuthorized("v1/admin/\(resource.path)",method:"POST",body:body)}
    func adminUpdate(_ resource:AdminResource,id:String,body:[String:JSONValue])async throws->AdminRecord{try await sendAuthorized("v1/admin/\(resource.path)\(resource.path=="substitution-deny-rules" ? "":"/\(id)")",method:"PUT",body:body)}
    func adminDelete(_ resource:AdminResource,id:String,body:[String:JSONValue]?=nil)async throws{let data=try body.map{try encoder.encode($0)};_ = try await performData("v1/admin/\(resource.path)\(resource.path=="substitution-deny-rules" ? "":"/\(id)")",method:"DELETE",token:try await requiredToken(),body:data)}
    func setRating(mixId: UUID, score: Int) async throws -> RatingDTO { try await sendAuthorized("v1/me/ratings/\(mixId.uuidString)", method: "PUT", body: ["score": score]) }
    func deleteRating(mixId: UUID) async throws { try await sendEmptyAuthorized("v1/me/ratings/\(mixId.uuidString)", method: "DELETE") }
    func addFavorite(mixId: UUID) async throws -> FavoriteDTO { try await sendAuthorized("v1/me/favorites/\(mixId.uuidString)", method: "PUT", body: Optional<String>.none) }
    func deleteFavorite(mixId: UUID) async throws { try await sendEmptyAuthorized("v1/me/favorites/\(mixId.uuidString)", method: "DELETE") }
    func library() async throws -> LibrarySnapshotDTO { try await get("v1/me/library", token: try await requiredToken()) }
    func privateProducts() async throws->[PrivateProductDTO]{try await get("v1/me/private-products",token:try await requiredToken())}
    func createPrivateProduct(_ input:PrivateProductWrite)async throws->PrivateProductDTO{try await sendAuthorized("v1/me/private-products",method:"POST",body:input)}
    func deletePrivateProduct(id:UUID)async throws{try await sendEmptyAuthorized("v1/me/private-products/\(id.uuidString)",method:"DELETE")}
    func setArticleBookmark(slug:String,enabled:Bool)async throws{try await sendEmptyAuthorized("v1/me/article-bookmarks/\(slug)",method:enabled ? "PUT":"DELETE")}

    func inventory() async throws -> [InventoryItemDTO] { try await get("v1/me/inventory", token: try await requiredToken()) }
    func inventoryMatches(locale:Locale = .ru) async throws -> [InventoryMatchDTO] { try await get("v1/me/inventory/matches",query:["locale":locale.rawValue],token:try await requiredToken()) }
    func upsertInventory(_ input: InventoryUpsert) async throws -> InventoryItemDTO { try await sendAuthorized("v1/me/inventory", method: "PUT", body: input) }
    func deleteInventoryItem(id: UUID) async throws { try await sendEmptyAuthorized("v1/me/inventory/\(id.uuidString)", method: "DELETE") }

    func personalMixes() async throws -> [PersonalMixSummaryDTO] { try await get("v1/me/personal-mixes", token: try await requiredToken()) }
    func personalMix(id: UUID) async throws -> PersonalMixDetailDTO { try await get("v1/me/personal-mixes/\(id.uuidString)", token: try await requiredToken()) }
    func createPersonalMix(_ input: PersonalMixWrite) async throws -> PersonalMixDetailDTO { try await sendAuthorized("v1/me/personal-mixes", method: "POST", body: input) }
    func updatePersonalMix(id: UUID, input: PersonalMixWrite) async throws -> PersonalMixDetailDTO { try await sendAuthorized("v1/me/personal-mixes/\(id.uuidString)", method: "PUT", body: input) }
    func deletePersonalMix(id: UUID) async throws { try await sendEmptyAuthorized("v1/me/personal-mixes/\(id.uuidString)", method: "DELETE") }

    private func get<Value: Decodable>(_ path: String, query: [String: String?] = [:], token: String? = nil) async throws -> Value {
        try await perform(path, method: "GET", query: query, token: token, body: nil)
    }
    private func allCursorPages<Value:Decodable & Identifiable>(_ path:String,query:[String:String?])async throws->[Value] where Value.ID==UUID{
        var cursor:String?,seenCursors=Set<String>(),seenIDs=Set<UUID>(),result:[Value]=[]
        for _ in 0..<1000 {
            var pageQuery=query;pageQuery["pageSize"]="100";pageQuery["cursor"]=cursor
            let data=try await performData(path,method:"GET",query:pageQuery,token:nil,body:nil)
            let page:CursorPageEnvelope<[Value]>;do{page=try decoder.decode(CursorPageEnvelope<[Value]>.self,from:data)}catch{throw APIError.decoding(String(describing:error))}
            result.append(contentsOf:page.data.filter{seenIDs.insert($0.id).inserted})
            guard page.pagination.hasMore else{return result}
            guard let next=page.pagination.nextCursor,!next.isEmpty,seenCursors.insert(next).inserted else{throw APIError.decoding("Invalid or repeated pagination cursor")}
            cursor=next
        }
        throw APIError.decoding("Pagination exceeded 1000 pages")
    }

    private func send<Value: Decodable, Body: Encodable>(_ path: String, method: String, token: String?, body: Body?) async throws -> Value {
        let data = try body.map { try encoder.encode($0) }
        return try await perform(path, method: method, token: token, body: data)
    }

    private func sendAuthorized<Value: Decodable, Body: Encodable>(_ path: String, method: String, body: Body?) async throws -> Value {
        try await send(path, method: method, token: try await requiredToken(), body: body)
    }

    private func sendEmpty(_ path: String, method: String, token: String) async throws {
        _ = try await performData(path, method: method, token: token, body: nil)
    }

    private func sendEmptyAuthorized(_ path: String, method: String) async throws { try await sendEmpty(path, method: method, token: try await requiredToken()) }
    private func requiredToken(afterRejected token: String? = nil) async throws -> String { guard let tokenProvider else { throw AuthTokenError.signedOut }; return try await tokenProvider.accessToken(afterRejectedToken: token) }

    private func perform<Value: Decodable>(_ path: String, method: String, query: [String: String?] = [:], token: String?, body: Data?) async throws -> Value {
        let data = try await performData(path, method: method, query: query, token: token, body: body)
        do { return try decoder.decode(APIEnvelope<Value>.self, from: data).data }
        catch { throw APIError.decoding(String(describing: error)) }
    }

    private func performData(_ path: String, method: String, query: [String: String?] = [:], token: String?, body: Data?) async throws -> Data {
        guard var components = URLComponents(url: baseURL.appending(path: path), resolvingAgainstBaseURL: false) else { throw APIError.invalidURL }
        components.queryItems = query.compactMap { key, value in value.map { URLQueryItem(name: key, value: $0) } }.sorted { $0.name < $1.name }
        guard let url = components.url else { throw APIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        if body != nil { request.setValue("application/json", forHTTPHeaderField: "Content-Type") }
        if let token { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }

        let data: Data; let response: HTTPURLResponse
        do { (data, response) = try await transport.data(for: request) }
        catch let error as APIError { throw error }
        catch { throw APIError.transport(String(describing: error)) }
        if response.statusCode == 401, let token, let tokenProvider {
            let refreshed = try await tokenProvider.accessToken(afterRejectedToken: token)
            return try await performDataOnce(path, method: method, query: query, token: refreshed, body: body)
        }
        guard (200..<300).contains(response.statusCode) else {
            let code = (try? decoder.decode(ServerError.self, from: data))?.error
            throw APIError.http(status: response.statusCode, serverCode: code, body: data)
        }
        return data
    }

    private func performDataOnce(_ path: String, method: String, query: [String: String?], token: String, body: Data?) async throws -> Data {
        guard var components = URLComponents(url: baseURL.appending(path: path), resolvingAgainstBaseURL: false) else { throw APIError.invalidURL }
        components.queryItems = query.compactMap { key, value in value.map { URLQueryItem(name: key, value: $0) } }.sorted { $0.name < $1.name }
        guard let url = components.url else { throw APIError.invalidURL }; var request = URLRequest(url: url); request.httpMethod=method;request.httpBody=body
        if body != nil { request.setValue("application/json", forHTTPHeaderField:"Content-Type") };request.setValue("Bearer \(token)",forHTTPHeaderField:"Authorization")
        let (data,response)=try await transport.data(for:request)
        guard (200..<300).contains(response.statusCode) else { throw APIError.http(status:response.statusCode,serverCode:(try? decoder.decode(ServerError.self,from:data))?.error,body:data) }
        return data
    }
}

private struct ServerError: Decodable { let error: String }

extension APIClient: InventoryRemoteServing, AdminServing {}
