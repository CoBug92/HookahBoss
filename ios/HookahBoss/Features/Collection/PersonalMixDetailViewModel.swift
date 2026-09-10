import Foundation

@MainActor
final class PersonalMixDetailViewModel: ObservableObject {
    struct Component: Identifiable, Equatable {
        let id: UUID
        let flavor: String
        let brandAndLine: String?
        let percentage: Int?
    }

    let mix: PersonalMixRecord

    init(mix: PersonalMixRecord) {
        self.mix = mix
    }

    var title: String { mix.title ?? L10n.Collection.untitledMix }
    var isApproximate: Bool { mix.isApproximate == true }
    var components: [Component] {
        mix.components.map { component in
            let parts = [component.brand, component.line].compactMap { value in
                value?.trimmingCharacters(in: .whitespacesAndNewlines)
            }.filter { !$0.isEmpty }
            return Component(
                id: component.id,
                flavor: component.flavor,
                brandAndLine: parts.isEmpty ? nil : parts.joined(separator: " · "),
                percentage: component.percentage
            )
        }
    }
}
