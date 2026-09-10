import Foundation

enum AccessibilityID {
    static let ageConfirm = "age.confirm"
    static let homeFindMix = "home.findMix"
    static let homeLogin = "home.login"
    static let mixComposition = "mix.composition"
    static let personalMixDetail = "screen.personalMixDetail"
    static let personalMixComposition = "personalMix.composition"
    static func homeRecommendation(_ id:UUID)->String { "home.recommendation.\(id.uuidString)" }
}
