extension FlavorIntensity {
    var title: String {
        switch self {
        case .any: L10n.Intensity.any
        case .subtle: L10n.Intensity.subtle
        case .pronounced: L10n.Intensity.pronounced
        }
    }
}
