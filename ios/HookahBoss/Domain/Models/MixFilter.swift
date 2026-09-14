import Foundation

struct MixFilter: Equatable {
    var profiles: Set<FlavorProfile> = []
    var sweetness: FlavorIntensity = .any
    var acidity: FlavorIntensity = .any
    var freshness: FlavorIntensity = .any
    var strength: MixStrength?
    var excludedFlavor = ""

    static let empty = MixFilter()

    var isEmpty: Bool {
        profiles.isEmpty
            && sweetness == .any
            && acidity == .any
            && freshness == .any
            && strength == nil
            && excludedTerms.isEmpty
    }

    var activeCriteriaCount: Int {
        profiles.count
            + (sweetness == .any ? 0 : 1)
            + (acidity == .any ? 0 : 1)
            + (freshness == .any ? 0 : 1)
            + (strength == nil ? 0 : 1)
            + excludedTerms.count
    }

    func matches(_ mix: MixPreview) -> Bool {
        matchQuality(for: mix) == .ideal
    }

    func matchQuality(for mix: MixPreview) -> MixMatchQuality? {
        if containsExcludedFlavor(in: mix) { return nil }
        var missedCriteria = 0

        if !profiles.isEmpty, profiles.isDisjoint(with: mix.flavorProfiles) { missedCriteria += 1 }
        if sweetness != .any, sweetness != mix.sweetness { missedCriteria += 1 }
        if acidity != .any, acidity != mix.acidity { missedCriteria += 1 }
        if freshness != .any, freshness != mix.freshness { missedCriteria += 1 }
        if let strength, strength != mix.strength { missedCriteria += 1 }

        if missedCriteria == 0 { return .ideal }
        if !isEmpty, missedCriteria == 1 { return .possible }
        return nil
    }

    private func containsExcludedFlavor(in mix: MixPreview) -> Bool {
        let searchableText = (mix.flavorTags + mix.ingredients.map(\.flavor))
            .joined(separator: " ")
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)

        return excludedTerms.contains { term in
            searchableText.contains(
                term.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            )
        }
    }

    private var excludedTerms: [String] {
        excludedFlavor
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
