import Foundation

struct MixPreview: Identifiable, Hashable {
    let id: UUID
    let title: String
    let flavorTags: [String]
    let flavorProfiles: Set<FlavorProfile>
    let sweetness: FlavorIntensity
    let acidity: FlavorIntensity
    let freshness: FlavorIntensity
    let ingredients: [MixIngredient]
    let rating: Double?
    let ratingsCount: Int
    let strength: MixStrength
    let personalRating: Int?
    let isFavorite: Bool
    let palette: MixPalette
}
extension MixPreview {
    func personalized(rating:Int?,favorite:Bool)->MixPreview { .init(id:id,title:title,flavorTags:flavorTags,flavorProfiles:flavorProfiles,sweetness:sweetness,acidity:acidity,freshness:freshness,ingredients:ingredients,rating:self.rating,ratingsCount:ratingsCount,strength:strength,personalRating:rating,isFavorite:favorite,palette:palette) }
}

enum FlavorProfile: String, CaseIterable, Identifiable, Hashable {
    case berry, fruit, citrus, dessert, beverage, herbal, spicy, fresh

    var id: String { rawValue }
    var title: String { String(localized: String.LocalizationValue("profile.\(rawValue)")) }
}

enum FlavorIntensity: String, CaseIterable, Identifiable, Hashable {
    case any, subtle, pronounced

    var id: String { rawValue }
    var title: String { String(localized: String.LocalizationValue("intensity.\(rawValue)")) }
}

struct MixIngredient: Identifiable, Hashable {
    let id: UUID
    let brand: String
    let line: String?
    let flavor: String
    let percentage: Int

    init(id: UUID = UUID(), brand: String, line: String? = nil, flavor: String, percentage: Int) {
        self.id = id
        self.brand = brand
        self.line = line
        self.flavor = flavor
        self.percentage = percentage
    }

    var brandAndLine: String {
        [brand, line].compactMap { $0 }.joined(separator: " · ")
    }
}

enum MixStrength: String, Hashable {
    case light
    case medium
    case strong

    var title: String {
        String(localized: String.LocalizationValue("strength.\(rawValue)"))
    }
}

enum MixPalette: Hashable {
    case tropical
    case berry
    case citrus
    case dessert

    static func forProfiles(_ profiles:Set<FlavorProfile>)->Self {
        if profiles.contains(.dessert) { return .dessert }
        if profiles.contains(.berry) { return .berry }
        if profiles.contains(.citrus) { return .citrus }
        return .tropical
    }
    var artworkFilename:String { switch self {case .dessert:"mix-dessert";case .berry,.citrus:"mix-berry-citrus";case .tropical:"mix-tropical"} }
}

struct MixFilter: Equatable {
    var profiles: Set<FlavorProfile> = []
    var sweetness: FlavorIntensity = .any
    var acidity: FlavorIntensity = .any
    var freshness: FlavorIntensity = .any
    var strength: MixStrength?
    var excludedFlavor = ""

    static let empty = MixFilter()

    var isEmpty: Bool {
        profiles.isEmpty && sweetness == .any && acidity == .any && freshness == .any && strength == nil && excludedTerms.isEmpty
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
            searchableText.contains(term.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current))
        }
    }

    private var excludedTerms: [String] {
        excludedFlavor
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}

enum MixMatchQuality {
    case ideal
    case possible
}
