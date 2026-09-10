import XCTest
@testable import HookahBoss

@MainActor
final class PersonalMixDetailViewModelTests: XCTestCase {
    func testMapsPersistedMixIntoLocalizedDetailState() {
        let component = PersonalMixComponentRecord(
            id: UUID(), source: .catalog, sourceID: UUID().uuidString,
            brand: "DARKSIDE", line: "Core", flavor: "Mango", percentage: 60
        )
        let mix = PersonalMixRecord(
            id: UUID(), title: nil, components: [component], createdAt: .distantPast,
            isApproximate: true
        )

        let model = PersonalMixDetailViewModel(mix: mix)

        XCTAssertEqual(model.title, L10n.Collection.untitledMix)
        XCTAssertTrue(model.isApproximate)
        XCTAssertEqual(model.components, [
            .init(id: component.id, flavor: "Mango", brandAndLine: "DARKSIDE · Core", percentage: 60)
        ])
    }
}
