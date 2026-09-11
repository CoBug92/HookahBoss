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

    init(id: UUID, title: String, flavorTags: [String], flavorProfiles: Set<FlavorProfile>, sweetness: FlavorIntensity, acidity: FlavorIntensity, freshness: FlavorIntensity, ingredients: [MixIngredient], rating: Double?, ratingsCount: Int, strength: MixStrength, personalRating: Int?, isFavorite: Bool, palette: MixPalette) {
        let ingredients = ingredients.mergingDuplicateProducts()
        self.id = id
        self.title = title
        self.flavorTags = ingredients.isEmpty ? flavorTags.uniqueValues() : ingredients.map(\.flavor).uniqueValues()
        self.flavorProfiles = flavorProfiles
        self.sweetness = sweetness
        self.acidity = acidity
        self.freshness = freshness
        self.ingredients = ingredients
        self.rating = rating
        self.ratingsCount = ratingsCount
        self.strength = strength
        self.personalRating = personalRating
        self.isFavorite = isFavorite
        self.palette = palette
    }
}
extension MixPreview {
    func personalized(rating:Int?,favorite:Bool)->MixPreview { .init(id:id,title:title,flavorTags:flavorTags,flavorProfiles:flavorProfiles,sweetness:sweetness,acidity:acidity,freshness:freshness,ingredients:ingredients,rating:self.rating,ratingsCount:ratingsCount,strength:strength,personalRating:rating,isFavorite:favorite,palette:palette) }
    func applyingPersonalRatingChange(from previous:Int?,to current:Int?)->MixPreview {
        guard previous != current else { return personalized(rating:current,favorite:isFavorite) }
        let previousSum=(rating ?? 0)*Double(ratingsCount)
        let nextCount:Int
        let nextSum:Double
        switch(previous,current){
        case(nil,.some(let score)):nextCount=ratingsCount+1;nextSum=previousSum+Double(score)
        case(.some(let old),.some(let score)):nextCount=ratingsCount;nextSum=previousSum-Double(old)+Double(score)
        case(.some(let old),nil):nextCount=max(0,ratingsCount-1);nextSum=previousSum-Double(old)
        case(nil,nil):nextCount=ratingsCount;nextSum=previousSum
        }
        let nextRating:Double?=nextCount == 0 ? nil:max(1,min(5,nextSum/Double(nextCount)))
        return .init(id:id,title:title,flavorTags:flavorTags,flavorProfiles:flavorProfiles,sweetness:sweetness,acidity:acidity,freshness:freshness,ingredients:ingredients,rating:nextRating,ratingsCount:nextCount,strength:strength,personalRating:current,isFavorite:isFavorite,palette:palette)
    }
}

enum FlavorProfile: String, CaseIterable, Identifiable, Hashable {
    case berry, fruit, citrus, dessert, beverage, herbal, spicy, fresh

    var id: String { rawValue }
    var title: String { switch self { case .berry:L10n.Profile.berry;case .fruit:L10n.Profile.fruit;case .citrus:L10n.Profile.citrus;case .dessert:L10n.Profile.dessert;case .beverage:L10n.Profile.beverage;case .herbal:L10n.Profile.herbal;case .spicy:L10n.Profile.spicy;case .fresh:L10n.Profile.fresh } }
}

enum FlavorIntensity: String, CaseIterable, Identifiable, Hashable {
    case any, subtle, pronounced

    var id: String { rawValue }
    var title: String { switch self { case .any:L10n.Intensity.any;case .subtle:L10n.Intensity.subtle;case .pronounced:L10n.Intensity.pronounced } }
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

private extension Array where Element == MixIngredient {
    func mergingDuplicateProducts() -> [MixIngredient] {
        var result: [MixIngredient] = []
        var indexByProduct: [String: Int] = [:]
        for ingredient in self {
            let key = [ingredient.brand, ingredient.flavor]
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current) }
                .joined(separator: "\u{0}")
            if let index = indexByProduct[key] {
                let existing = result[index]
                result[index] = MixIngredient(id: existing.id, brand: existing.brand, line: existing.line ?? ingredient.line, flavor: existing.flavor, percentage: existing.percentage + ingredient.percentage)
            } else {
                indexByProduct[key] = result.count
                result.append(ingredient)
            }
        }
        return result
    }
}

private extension Array where Element == String {
    func uniqueValues() -> [String] {
        var seen: Set<String> = []
        return filter {
            let key = $0.trimmingCharacters(in: .whitespacesAndNewlines).folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            return !key.isEmpty && seen.insert(key).inserted
        }
    }
}

enum MixStrength: String, Hashable {
    case light
    case medium
    case strong

    var title: String {
        switch self { case .light:L10n.Strength.light;case .medium:L10n.Strength.medium;case .strong:L10n.Strength.strong }
    }

    var detailTitle: String {
        switch self {
        case .light: L10n.Strength.Detail.light
        case .medium: L10n.Strength.Detail.medium
        case .strong: L10n.Strength.Detail.strong
        }
    }
}

enum MixPalette: CaseIterable, Hashable {
    case tropical
    case berry
    case citrus
    case dessert
    case beverage
    case herbal
    case spicy
    case fresh
    case tropicalCooler
    case forestBerry
    case peachTea
    case watermelonMint
    case cherrySpice
    case applePastry
    case grapeSoda
    case coconutVanilla
    case cucumberTonic
    case pomegranateCitrus

    static func forProfiles(_ profiles:Set<FlavorProfile>)->Self {
        if profiles.contains(.dessert) { return .dessert }
        if profiles.contains(.beverage) { return .beverage }
        if profiles.contains(.herbal) { return .herbal }
        if profiles.contains(.spicy) { return .spicy }
        if profiles.contains(.fresh) { return .fresh }
        if profiles.contains(.berry) { return .berry }
        if profiles.contains(.citrus) { return .citrus }
        return .tropical
    }

    static func forProfiles(_ profiles: Set<FlavorProfile>, seed: UUID) -> Self {
        let available = profiles.sorted { $0.rawValue < $1.rawValue }
        guard !available.isEmpty else { return .tropical }
        let checksum = seed.uuidString.utf8.reduce(0) { ($0 + Int($1)) % Int.max }
        let profile = available[checksum % available.count]
        let variants = palettes(for: profile)
        return variants[(checksum / max(1, available.count)) % variants.count]
    }

    private static func palette(for profile: FlavorProfile) -> Self {
        switch profile {
        case .berry: .berry
        case .fruit: .tropical
        case .citrus: .citrus
        case .dessert: .dessert
        case .beverage: .beverage
        case .herbal: .herbal
        case .spicy: .spicy
        case .fresh: .fresh
        }
    }

    private static func palettes(for profile: FlavorProfile) -> [Self] {
        switch profile {
        case .berry: [.berry, .forestBerry, .cherrySpice, .pomegranateCitrus]
        case .fruit: [.tropical, .tropicalCooler, .peachTea, .watermelonMint, .applePastry]
        case .citrus: [.citrus, .tropicalCooler, .watermelonMint, .pomegranateCitrus]
        case .dessert: [.dessert, .applePastry, .coconutVanilla]
        case .beverage: [.beverage, .peachTea, .grapeSoda, .cucumberTonic]
        case .herbal: [.herbal, .cucumberTonic, .watermelonMint]
        case .spicy: [.spicy, .cherrySpice, .applePastry]
        case .fresh: [.fresh, .watermelonMint, .cucumberTonic, .grapeSoda]
        }
    }
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
