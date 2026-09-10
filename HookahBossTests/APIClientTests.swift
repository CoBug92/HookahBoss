import XCTest
@testable import HookahBoss

actor MockTransport: APITransport {
    private var responses: [(Data, Int)]
    private(set) var requests: [URLRequest] = []

    init(json: String = "{\"data\":{}}", status: Int = 200) {
        responses = [(Data(json.utf8), status)]
    }
    init(jsonResponses:[String]) { responses=jsonResponses.map{(Data($0.utf8),200)} }

    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        requests.append(request)
        let next = responses.removeFirst()
        return (next.0, HTTPURLResponse(url: request.url!, statusCode: next.1, httpVersion: nil, headerFields: nil)!)
    }
}
struct FixedTokenProvider: AccessTokenProvider { let token: String; func accessToken(afterRejectedToken: String?) async throws -> String { token } }

final class APIClientTests: XCTestCase {
    private let baseURL = URL(string: "https://api.example.test/root/")!

    func testMixesLoadsEveryCursorPageAndDeduplicatesIDs() async throws {
        let first=UUID(),second=UUID();func mix(_ id:UUID,_ slug:String)->String { #"{"id":"\#(id)","slug":"\#(slug)","title":"Mix","summary":null,"rating":null,"ratingsCount":0,"components":[],"tags":[],"profiles":[],"sweetness":"subtle","acidity":"subtle","freshness":"subtle","strength":"medium"}"# }
        let transport=MockTransport(jsonResponses:[#"{"data":[\#(mix(first,"one"))],"pagination":{"nextCursor":"cursor-2","hasMore":true}}"#,#"{"data":[\#(mix(first,"one")),\#(mix(second,"two"))],"pagination":{"nextCursor":null,"hasMore":false}}"#])
        let result=try await APIClient(baseURL:baseURL,transport:transport).mixes(locale:.en);XCTAssertEqual(result.map(\.id),[first,second]);let requests=await transport.requests;XCTAssertEqual(requests.count,2)
        XCTAssertEqual(URLComponents(url:requests[0].url!,resolvingAgainstBaseURL:false)?.queryItems?.first(where:{$0.name=="pageSize"})?.value,"100")
        XCTAssertEqual(URLComponents(url:requests[1].url!,resolvingAgainstBaseURL:false)?.queryItems?.first(where:{$0.name=="cursor"})?.value,"cursor-2")
    }

    func testCursorLoaderRejectsRepeatedCursor() async throws {
        let id=UUID(),item=#"{"id":"\#(id)","slug":"one","title":"Mix","summary":null,"rating":null,"ratingsCount":0,"components":[],"tags":[],"profiles":[],"sweetness":"subtle","acidity":"subtle","freshness":"subtle","strength":"medium"}"#
        let page=#"{"data":[\#(item)],"pagination":{"nextCursor":"same","hasMore":true}}"#;let transport=MockTransport(jsonResponses:[page,page])
        do{_ = try await APIClient(baseURL:baseURL,transport:transport).mixes();XCTFail("Expected repeated cursor failure")}catch let error as APIError{guard case .decoding(let message)=error else{return XCTFail("Unexpected error")};XCTAssertTrue(message.contains("repeated"))}
    }

    func testAppleExchangeTransportsSingleUseAuthorizationCodeWithoutBearer() async throws {
        let account=UUID()
        let transport=MockTransport(json:"""
        {"data":{"accessToken":"access","expiresIn":900,"refreshToken":"refresh","refreshExpiresIn":2592000,"accountId":"\(account)"}}
        """)
        let client=APIClient(baseURL:baseURL,transport:transport)
        _ = try await client.exchangeAppleIdentityToken("identity",authorizationCode:"single-use")
        let captured=await transport.requests
        let request=try XCTUnwrap(captured.first)
        XCTAssertEqual(request.httpMethod,"POST")
        XCTAssertNil(request.value(forHTTPHeaderField:"Authorization"))
        let body=try XCTUnwrap(request.httpBody)
        let json=try XCTUnwrap(JSONSerialization.jsonObject(with:body) as? [String:String])
        XCTAssertEqual(json,["identityToken":"identity","authorizationCode":"single-use"])
    }

    func testPublicBrandsGETHasNoUnusedLocaleQueryOrAuthorizationAndDecodes() async throws {
        let id = UUID()
        let transport = MockTransport(json: """
        {"data":[{"id":"\(id)","slug":"musthave","name":"MustHave","lines":[]}]}
        """)
        let client = APIClient(baseURL: baseURL, transport: transport)

        let brands = try await client.brands()

        XCTAssertEqual(brands, [BrandDTO(id: id, slug: "musthave", name: "MustHave", lines: [])])
        let captured = await transport.requests
        let request = try XCTUnwrap(captured.first)
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.url?.path, "/root/v1/brands")
        XCTAssertTrue((URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems ?? []).isEmpty)
        XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))
    }

    func testArticlesGETSupportsFilterPaginationAndDecodesSummary() async throws {
        let id = UUID()
        let transport = MockTransport(json: """
        {"data":[{"id":"\(id)","slug":"heat","title":"Heat","summary":"Summary","category":"bowls_heat","readingMinutes":5}],"pagination":{"page":2,"pageSize":10,"total":1}}
        """)
        let client = APIClient(baseURL: baseURL, transport: transport)
        let articles = try await client.articles(locale: .en, category: "bowls_heat", page: 2, pageSize: 10)
        XCTAssertEqual(articles.first?.summary, "Summary")
        let captured = await transport.requests
        let request = try XCTUnwrap(captured.first)
        let items = try XCTUnwrap(URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems)
        XCTAssertEqual(Dictionary(uniqueKeysWithValues: items.map { ($0.name, $0.value!) }), ["locale": "en", "category": "bowls_heat", "page": "2", "pageSize": "10"])
        XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))
    }

    func testArticleDetailDecodesStructuredSectionsAndRelated() async throws {
        let id = UUID(), relatedId = UUID()
        let transport = MockTransport(json: """
        {"data":{"id":"\(id)","slug":"safety","title":"Safety","summary":"Summary","sections":[{"heading":"CO","body":"Body"}],"category":"safety","readingMinutes":6,"related":[{"id":"\(relatedId)","slug":"care","title":"Care","summary":"Clean","category":"care","readingMinutes":4}]}}
        """)
        let detail = try await APIClient(baseURL: baseURL, transport: transport).article(id: "safety", locale: .en)
        XCTAssertEqual(detail.sections, [.init(heading: "CO", body: "Body")])
        XCTAssertEqual(detail.related.first?.slug, "care")
    }

    func testRatingPUTUsesBearerAndJSONBody() async throws {
        let mixId = UUID()
        let transport = MockTransport(json: "{\"data\":{\"mixId\":\"\(mixId)\",\"score\":4,\"updatedAt\":\"2026-09-09T12:00:00Z\"}}")
        let client = APIClient(baseURL: baseURL, transport: transport, tokenProvider: FixedTokenProvider(token: "identity-token"))

        let rating = try await client.setRating(mixId: mixId, score: 4)

        XCTAssertEqual(rating.score, 4)
        let captured = await transport.requests
        let request = try XCTUnwrap(captured.first)
        XCTAssertEqual(request.httpMethod, "PUT")
        XCTAssertEqual(request.url?.path, "/root/v1/me/ratings/\(mixId.uuidString)")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer identity-token")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertEqual(try JSONSerialization.jsonObject(with: request.httpBody!) as? [String: Int], ["score": 4])
    }

    func testFavoriteDELETEAcceptsEmptySuccessResponse() async throws {
        let mixId = UUID()
        let transport = MockTransport(json: "", status: 204)
        let client = APIClient(baseURL: baseURL, transport: transport, tokenProvider: FixedTokenProvider(token: "token"))

        try await client.deleteFavorite(mixId: mixId)

        let captured = await transport.requests
        let request = try XCTUnwrap(captured.first)
        XCTAssertEqual(request.httpMethod, "DELETE")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer token")
        XCTAssertNil(request.httpBody)
    }

    func testInventoryPUTEncodesExactlyTheServerContract() async throws {
        let productId = UUID(), itemId = UUID()
        let transport = MockTransport(json: "{\"data\":{\"id\":\"\(itemId)\",\"level\":\"low\",\"productId\":\"\(productId)\",\"privateProductId\":null,\"updatedAt\":\"now\"}}")
        let client = APIClient(baseURL: baseURL, transport: transport, tokenProvider: FixedTokenProvider(token: "token"))

        let item = try await client.upsertInventory(.init(productId: productId, privateProductId: nil, level: "low"))

        XCTAssertEqual(item.level, "low")
        let captured = await transport.requests
        let body = try XCTUnwrap(captured.first?.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        XCTAssertEqual(json["productId"] as? String, productId.uuidString)
        XCTAssertEqual(json["level"] as? String, "low")
        XCTAssertNil(json["privateProductId"])
    }

    func testHTTPErrorPreservesStatusAndServerCode() async throws {
        let transport = MockTransport(json: "{\"error\":\"invalid_score\"}", status: 400)
        let client = APIClient(baseURL: baseURL, transport: transport, tokenProvider: FixedTokenProvider(token: "token"))
        do {
            _ = try await client.setRating(mixId: UUID(), score: 8)
            XCTFail("Expected an HTTP error")
        } catch let error as APIError {
            guard case .http(let status, let code, _) = error else { return XCTFail("Wrong error: \(error)") }
            XCTAssertEqual(status, 400)
            XCTAssertEqual(code, "invalid_score")
        }
    }

    func testDecodingErrorIsTyped() async throws {
        let client = APIClient(baseURL: baseURL, transport: MockTransport(json: "{\"data\":{\"unexpected\":true}}"))
        do {
            _ = try await client.mixes()
            XCTFail("Expected a decoding error")
        } catch let error as APIError {
            guard case .decoding = error else { return XCTFail("Wrong error: \(error)") }
        }
    }

    func testAdminCapabilityAndListAreAuthorized() async throws {
        let transport=MockTransport(json:"{\"data\":{\"admin\":true}}")
        let client=APIClient(baseURL:baseURL,transport:transport,tokenProvider:FixedTokenProvider(token:"session"))
        let capability=try await client.adminCapabilities();XCTAssertTrue(capability.admin)
        let requests=await transport.requests;let request=try XCTUnwrap(requests.first)
        XCTAssertEqual(request.url?.path,"/root/v1/me/admin-capabilities")
        XCTAssertEqual(request.value(forHTTPHeaderField:"Authorization"),"Bearer session")
    }

    func testAdminCreateUsesResourceRouteAndBody() async throws {
        let transport=MockTransport(json:"{\"data\":{\"id\":\"source-1\",\"url\":\"https://example.test\"}}")
        let client=APIClient(baseURL:baseURL,transport:transport,tokenProvider:FixedTokenProvider(token:"session"));let resource=AdminResource.all.first!
        _ = try await client.adminCreate(resource,body:["url":.string("https://example.test"),"checkedAt":.string("2026-09-09")])
        let requests=await transport.requests;let request=try XCTUnwrap(requests.first);XCTAssertEqual(request.httpMethod,"POST");XCTAssertEqual(request.url?.path,"/root/v1/admin/sources");XCTAssertNotNil(request.httpBody)
    }
    func testAdminListLoadsAll229RecordsInOrderedPages() async throws {
        func page(_ range:Range<Int>)->String{"{\"data\":["+range.map{"{\"id\":\"id-\($0)\",\"name\":\"Item \($0)\"}"}.joined(separator:",")+"]}"}
        let transport=MockTransport(jsonResponses:[page(0..<100),page(100..<200),page(200..<229)])
        let client=APIClient(baseURL:baseURL,transport:transport,tokenProvider:FixedTokenProvider(token:"session"))
        let records=try await client.adminList(AdminResource.all.first{$0.path=="products"}!)
        XCTAssertEqual(records.count,229);XCTAssertEqual(records.first?.id,"id-0");XCTAssertEqual(records.last?.id,"id-228")
        let requests=await transport.requests
        XCTAssertEqual(requests.compactMap{URLComponents(url:$0.url!,resolvingAgainstBaseURL:false)?.queryItems?.first{$0.name=="offset"}?.value},["0","100","200"])
        XCTAssertTrue(requests.allSatisfy{$0.value(forHTTPHeaderField:"Authorization")=="Bearer session"})
    }
    func testAdminListExactMultipleRequestsEmptyTerminator() async throws {
        func page(_ range:Range<Int>)->String{"{\"data\":["+range.map{"{\"id\":\"id-\($0)\"}"}.joined(separator:",")+"]}"}
        let transport=MockTransport(jsonResponses:[page(0..<100),page(100..<200),"{\"data\":[]}"])
        let client=APIClient(baseURL:baseURL,transport:transport,tokenProvider:FixedTokenProvider(token:"session"))
        let records=try await client.adminList(AdminResource.all.first!)
        XCTAssertEqual(records,Array(0..<200).map{AdminRecord.fixture(id:"id-\($0)")})
        let requests=await transport.requests;XCTAssertEqual(requests.count,3)
    }
}

private extension AdminRecord { static func fixture(id:String)->AdminRecord { try! JSONDecoder().decode(AdminRecord.self,from:Data("{\"id\":\"\(id)\"}".utf8)) } }
