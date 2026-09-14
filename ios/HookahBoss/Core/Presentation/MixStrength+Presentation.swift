extension MixStrength {
    var title: String {
        switch self {
        case .light: L10n.Strength.light
        case .medium: L10n.Strength.medium
        case .strong: L10n.Strength.strong
        }
    }

    var detailTitle: String {
        switch self {
        case .light: L10n.Strength.Detail.light
        case .medium: L10n.Strength.Detail.medium
        case .strong: L10n.Strength.Detail.strong
        }
    }
}
