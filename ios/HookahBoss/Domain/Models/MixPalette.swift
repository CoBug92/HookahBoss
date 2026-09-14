import Foundation

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

    static func forProfiles(_ profiles: Set<FlavorProfile>) -> Self {
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
