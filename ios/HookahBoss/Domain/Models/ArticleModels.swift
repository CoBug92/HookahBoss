import Foundation

enum ArticleCategory: String, CaseIterable, Identifiable, Codable {
    case basics, preparation, heat, care, safety
    var id: String { rawValue }
    var title: String { switch self {case .basics:L10n.Articles.Category.basics;case .preparation:L10n.Articles.Category.preparation;case .heat:L10n.Articles.Category.heat;case .care:L10n.Articles.Category.care;case .safety:L10n.Articles.Category.safety} }
    var icon: String {
        switch self {
        case .basics: "book.pages"
        case .preparation: "list.bullet.clipboard"
        case .heat: "flame"
        case .care: "sparkles"
        case .safety: "shield.checkered"
        }
    }
}
