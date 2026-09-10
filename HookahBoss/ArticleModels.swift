import Foundation

enum ArticleCategory: String, CaseIterable, Identifiable, Codable {
    case basics, preparation, heat, care, safety
    var id: String { rawValue }
    var titleKey: String { "articles.category.\(rawValue)" }
    var icon: String {
        switch self {
        case .basics: "book.pages"
        case .preparation: "list.bullet.clipboard"
        case .heat: "flame"
        case .care: "sparkles"
        case .safety: "shield.checkered"
        }
    }
    var artworkFilename:String { "article-\(rawValue)" }
}
