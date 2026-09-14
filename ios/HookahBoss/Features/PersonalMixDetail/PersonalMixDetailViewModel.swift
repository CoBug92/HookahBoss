import Foundation

@MainActor
final class PersonalMixDetailViewModel: ObservableObject {

    // MARK: - Properties

    let mix: PersonalMixRecord

    // MARK: - Init

    init(mix: PersonalMixRecord) {
        self.mix = mix
    }

    // MARK: - Computed properties

    var title: String {
        mix.title ?? L10n.Collection.untitledMix
    }

    var isApproximate: Bool {
        mix.isApproximate == true
    }

    var components: [PersonalMixComponentViewData] {
        mix.components.map { component in
            let parts = [component.brand, component.line]
                .compactMap { value in
                    value?.trimmingCharacters(in: .whitespacesAndNewlines)
                }
                .filter { !$0.isEmpty }
            return PersonalMixComponentViewData(
                id: component.id,
                flavor: component.flavor,
                brandAndLine: parts.isEmpty
                    ? nil
                    : parts.joined(separator: TechnicalString.bulletSeparator),
                percentage: component.percentage
            )
        }
    }
}
