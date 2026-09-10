import XCTest
@testable import HookahBoss

@MainActor
final class CreateMixViewModelTests: XCTestCase {
    func testSuccessfulSaveUsesEffectiveDistribution() async {
        let service = CreateMixServiceSpy(snapshot: .empty)
        let model = CreateMixViewModel(service: service)
        model.add(option(sourceID: UUID().uuidString, flavor: "Lemon"))
        model.add(option(sourceID: UUID().uuidString, flavor: "Mint"))

        model.save()
        await waitUntil { model.didSave }

        XCTAssertEqual(service.saved?.components.map(\.percentage), [50, 50])
        XCTAssertEqual(service.saved?.isApproximate, true)
    }

    func testInvalidDistributionDoesNotCallSave() async {
        let service = CreateMixServiceSpy(snapshot: .empty)
        let model = CreateMixViewModel(service: service)
        model.add(option(sourceID: UUID().uuidString, flavor: "Lemon"))
        model.setPercentage("60", at: 0)

        model.save()

        XCTAssertTrue(model.showValidation)
        XCTAssertNil(service.saved)
        XCTAssertNotNil(model.validationMessage)
    }

    func testSyncFailureIsPublishedAndDoesNotDismiss() async {
        let service = CreateMixServiceSpy(snapshot: .empty)
        service.saveError = TestFailure.expected
        let model = CreateMixViewModel(service: service)
        model.add(option(sourceID: UUID().uuidString, flavor: "Lemon"))

        model.save()
        await waitUntil { model.errorMessage != nil }

        XCTAssertFalse(model.didSave)
        XCTAssertNotNil(model.errorMessage)

        service.saveError = nil
        model.retry()
        await waitUntil { model.didSave }
        XCTAssertEqual(service.saveCalls, 2)
    }

    func testPrivateOptionsLoadAndPickerFiltersThem() async {
        let personal = CreateMixProduct(source: .personal, sourceID: "private:\(UUID().uuidString)", brand: "Mine",
                                        line: nil, flavor: "Pear", flavorProfiles: ["fruit"])
        let service = CreateMixServiceSpy(snapshot: CreateMixOptionSnapshot(catalog: [], personal: [personal], inventory: []))
        let model = CreateMixViewModel(service: service)

        model.appear(locale: .en)
        await waitUntil { !model.options.personal.isEmpty }
        let picker = ComponentPickerViewModel(snapshot: model.options, excluding: [])
        picker.source = .personal

        XCTAssertEqual(picker.filtered.map(\.flavor), ["Pear"])
        XCTAssertEqual(service.loadedLocales, [.en])
    }

    private func option(sourceID: String, flavor: String) -> ComponentOption {
        ComponentOption(CreateMixProduct(source: .catalog, sourceID: sourceID, brand: "Brand", line: "Line",
                                         flavor: flavor, flavorProfiles: ["fruit"]))
    }

    private func waitUntil(_ condition: @escaping @MainActor () -> Bool) async {
        for _ in 0..<100 where !condition() { await Task.yield() }
    }
}

private enum TestFailure: Error { case expected }

@MainActor
private final class CreateMixServiceSpy: CreateMixServing {
    let snapshot: CreateMixOptionSnapshot
    var saveError: Error?
    private(set) var saved: PersonalMixRecord?
    private(set) var saveCalls = 0
    private(set) var loadedLocales: [AppLocale] = []
    init(snapshot: CreateMixOptionSnapshot) { self.snapshot = snapshot }
    func loadOptions(locale: AppLocale) async throws -> CreateMixOptionSnapshot { loadedLocales.append(locale); return snapshot }
    func save(_ mix: PersonalMixRecord) async throws { saveCalls += 1; if let saveError { throw saveError }; saved = mix }
}

private extension CreateMixOptionSnapshot {
    static let empty = CreateMixOptionSnapshot(catalog: [], personal: [], inventory: [])
}
