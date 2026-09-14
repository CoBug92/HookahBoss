import Foundation

@MainActor
final class MixFilterViewModel: ObservableObject {
    @Published var filter: MixFilter
    let catalog: [MixPreview]

    var resultCount: Int {
        catalog.filter { filter.matchQuality(for: $0) != nil }.count
    }

    init(
        catalog: [MixPreview],
        filter: MixFilter
    ) {
        self.catalog = catalog
        self.filter = filter
    }

    func toggle(_ profile: FlavorProfile) {
        if filter.profiles.contains(profile) {
            filter.profiles.remove(profile)
        } else {
            filter.profiles.insert(profile)
        }
    }

    func toggleStrength(_ strength: MixStrength) {
        filter.strength = filter.strength == strength ? nil : strength
    }

    func reset() {
        filter = .empty
    }
}
