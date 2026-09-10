import XCTest
@testable import HookahBoss

@MainActor
final class InventoryMatchViewModelTests: XCTestCase {
    func testClassifiesReadySubstitutionAndMissingResults() async throws {
        let readyID = UUID(), substitutionID = UUID(), missingID = UUID()
        let sourceID = UUID(), targetID = UUID()
        let service = InventoryMatchServiceSpy(matches: [
            .init(mixId: readyID, kind: "ready", missingFlavor: nil, sourceProductId: nil, substituteProductId: nil),
            .init(mixId: substitutionID, kind: "substitution", missingFlavor: nil, sourceProductId: sourceID, substituteProductId: targetID),
            .init(mixId: missingID, kind: "missing", missingFlavor: "Bergamot", sourceProductId: nil, substituteProductId: nil),
        ])
        let products = try [product(id: sourceID, name: "Pear"), product(id: targetID, name: "Apple")]
        let model = InventoryMatchViewModel(service: service,
            catalog: [mix(id: readyID), mix(id: substitutionID), mix(id: missingID)], products: products)

        model.appear(locale: .en)
        await waitUntil { model.state != .loading }

        XCTAssertEqual(model.ready.map(\.id), [readyID])
        XCTAssertEqual(model.substitutions.first?.note, "Pear → Apple")
        XCTAssertEqual(model.missing.first?.note, "Bergamot")
        XCTAssertEqual(service.locales, [.en])
    }

    func testAnonymousModelFailsWithoutCallingInfrastructure() async {
        let model = InventoryMatchViewModel(service: nil, catalog: [], products: [])
        model.appear()
        await waitUntil { model.state != .loading }
        XCTAssertEqual(model.state, .failed)
    }

    func testRetryRecoversAfterTransientFailure() async {
        let mixID = UUID()
        let service = InventoryMatchServiceSpy(matches: [.init(mixId: mixID, kind: "ready", missingFlavor: nil, sourceProductId: nil, substituteProductId: nil)])
        service.shouldFail = true
        let model = InventoryMatchViewModel(service: service, catalog: [mix(id: mixID)], products: [])
        model.appear(locale: .en)
        await waitUntil { model.state == .failed }

        service.shouldFail = false
        model.retry(locale: .en)
        await waitUntil { model.state == .loaded }

        XCTAssertEqual(model.ready.map(\.id), [mixID])
        XCTAssertEqual(service.locales, [.en, .en])
    }

    private func mix(id: UUID) -> MixPreview {
        MixPreview(id: id, title: id.uuidString, flavorTags: [], flavorProfiles: [], sweetness: .subtle,
                   acidity: .subtle, freshness: .subtle, ingredients: [], rating: nil, ratingsCount: 0,
                   strength: .medium, personalRating: nil, isFavorite: false, palette: .tropical)
    }

    private func product(id: UUID, name: String) throws -> TobaccoProductDTO {
        let json = #"{"id":"\#(id.uuidString)","slug":"x","name":"\#(name)","description":null,"translationOrigin":"official","sourceConfidence":"high","sweetness":"subtle","acidity":"subtle","freshness":"subtle","lineId":"00000000-0000-0000-0000-000000000001","lineName":"Core","strength":"medium","brandId":"00000000-0000-0000-0000-000000000002","brandName":"Brand","tags":[]}"#
        return try JSONDecoder().decode(TobaccoProductDTO.self, from: Data(json.utf8))
    }

    private func waitUntil(_ condition: @escaping @MainActor () -> Bool) async {
        for _ in 0..<100 where !condition() { await Task.yield() }
    }
}

@MainActor
private final class InventoryMatchServiceSpy: InventoryMatchServing {
    let values: [InventoryMatchDTO]
    private(set) var locales: [AppLocale] = []
    var shouldFail = false
    init(matches: [InventoryMatchDTO]) { values = matches }
    func matches(locale: AppLocale) async throws -> [InventoryMatchDTO] { locales.append(locale); if shouldFail { throw URLError(.notConnectedToInternet) }; return values }
}
