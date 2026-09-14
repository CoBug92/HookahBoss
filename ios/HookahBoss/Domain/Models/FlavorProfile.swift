enum FlavorProfile: String, CaseIterable, Identifiable, Hashable {
    case berry
    case fruit
    case citrus
    case dessert
    case beverage
    case herbal
    case spicy
    case fresh

    var id: String { rawValue }
}
