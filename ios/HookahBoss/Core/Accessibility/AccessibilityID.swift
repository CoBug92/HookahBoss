import Foundation

enum AccessibilityID {
    static let ageConfirm = "age.confirm"
    static let articles = "screen.articles"
    static let homeFindMix = "home.findMix"
    static let homeLogin = "home.login"
    static let mixCardPrefix = "mix.card"
    static let mixComposition = "mix.composition"
    static let mixDetail = "screen.mixDetail"
    static let mixFilters = "mix.filters"
    static let personalMixDetail = "screen.personalMixDetail"
    static let personalMixComposition = "personalMix.composition"
    static func homeRecommendation(_ id: UUID) -> String { "home.recommendation.\(id.uuidString)" }
}
