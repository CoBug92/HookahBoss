extension ArticleCategory {
    var title: String {
        switch self {
        case .basics: L10n.Articles.Category.basics
        case .preparation: L10n.Articles.Category.preparation
        case .heat: L10n.Articles.Category.heat
        case .care: L10n.Articles.Category.care
        case .safety: L10n.Articles.Category.safety
        }
    }
}
