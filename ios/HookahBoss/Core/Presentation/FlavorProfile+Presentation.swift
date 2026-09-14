extension FlavorProfile {
    var title: String {
        switch self {
        case .berry: L10n.Profile.berry
        case .fruit: L10n.Profile.fruit
        case .citrus: L10n.Profile.citrus
        case .dessert: L10n.Profile.dessert
        case .beverage: L10n.Profile.beverage
        case .herbal: L10n.Profile.herbal
        case .spicy: L10n.Profile.spicy
        case .fresh: L10n.Profile.fresh
        }
    }
}
